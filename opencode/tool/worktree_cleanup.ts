import { tool } from "@opencode-ai/plugin"
import { readdir, stat } from "node:fs/promises"
import { join } from "node:path"

export default tool({
  description: "Remove a worktree and clean up the associated branch",
  args: {
    branchName: tool.schema.string().describe("Branch name to cleanup"),
    force: tool.schema.boolean().optional().default(false).describe("Skip branch deletion checks"),
    deleteBranch: tool.schema.boolean().optional().default(true).describe("Delete the branch after removing worktree")
  },
  async execute(args) {
    const { branchName, force = false, deleteBranch = true } = args

    let worktreeRemoved = false
    let branchDeleted = false
    const errors: string[] = []

    let gitRoot: string
    let isParentDir = false

    // Validate git repository
    try {
      gitRoot = await Bun.$`git rev-parse --show-toplevel`.text().then(t => t.trim())
    } catch (error) {
      // Not in a git repo, check if we are in the parent directory
      const entries = await readdir(process.cwd(), { withFileTypes: true })
      const gitRepos: string[] = []

      for (const entry of entries) {
        if (entry.isDirectory()) {
          try {
            const gitDir = join(process.cwd(), entry.name, '.git')
            const gitDirExists = await stat(gitDir).then(() => true).catch(() => false)
            if (gitDirExists) {
              gitRepos.push(join(process.cwd(), entry.name))
            }
          } catch (e) {
            // Ignore
          }
        }
      }

      if (gitRepos.length === 0) {
        return JSON.stringify({
          success: false,
          error: "Not a git repository and no git repositories found in current directory"
        }, null, 2)
      } else if (gitRepos.length > 1) {
        return JSON.stringify({
          success: false,
          error: `Multiple git repositories found: ${gitRepos.map(p => p.split('/').pop()).join(', ')}. Please run from inside the specific repository.`
        }, null, 2)
      }

      gitRoot = gitRepos[0]
      isParentDir = true
    }

    // Get worktree list
    let worktreesList = ''
    try {
      worktreesList = await Bun.$`git -C ${gitRoot} worktree list`.quiet().text().then(t => t.trim())
    } catch (error) {
      return JSON.stringify({
        success: false,
        error: `Failed to list worktrees: ${error}`
      }, null, 2)
    }
    const worktreeLines = worktreesList.split('\n').filter(line => line.trim())

    // Find the worktree
    let worktreePath: string | null = null
    for (const line of worktreeLines) {
      const match = line.match(/^([^\s]+)\s+([a-f0-9]+)\s+\[([^\]]+)\]?$/)
      if (match && match[3] === branchName) {
        worktreePath = match[1]
        break
      }
    }

    // Remove worktree if found
    if (worktreePath) {
      try {
        if (force) {
          await Bun.$`git -C ${gitRoot} worktree remove ${worktreePath} --force`.quiet()
        } else {
          await Bun.$`git -C ${gitRoot} worktree remove ${worktreePath}`.quiet()
        }
        worktreeRemoved = true
      } catch (error) {
        errors.push(`Failed to remove worktree: ${error}`)
      }
    } else {
      errors.push(`Worktree for branch '${branchName}' not found`)
    }

    // Delete branch if requested
    if (deleteBranch) {
      try {
        // Check if branch exists
        const result = await Bun.$`git -C ${gitRoot} show-ref --verify --quiet refs/heads/${branchName}`.quiet()
        const branchExists = result.exitCode === 0

        if (branchExists) {
          // Check if branch is current branch (cannot delete)
          let currentBranch = ''
          try {
            currentBranch = await Bun.$`git -C ${gitRoot} branch --show-current`.quiet().text().then(t => t.trim())
          } catch (error) {
            errors.push(`Failed to get current branch: ${error}`)
          }

          if (currentBranch === branchName) {
            // Switch away from the branch first
            try {
              // Try to switch to main or master
              const mainBranch = await Bun.$`git -C ${gitRoot} show-ref --verify --quiet refs/heads/main`.quiet()
              const masterBranch = await Bun.$`git -C ${gitRoot} show-ref --verify --quiet refs/heads/master`.quiet()
              
              if (mainBranch.exitCode === 0) {
                await Bun.$`git -C ${gitRoot} checkout main`.quiet()
              } else if (masterBranch.exitCode === 0) {
                await Bun.$`git -C ${gitRoot} checkout master`.quiet()
              } else {
                errors.push(`Cannot delete branch '${branchName}' - it is the current branch and no main/master branch found to switch to`)
              }
            } catch (switchError) {
              errors.push(`Failed to switch away from branch: ${switchError}`)
            }
          }

          // Try to delete the branch
          try {
            if (force) {
              await Bun.$`git -C ${gitRoot} branch -D ${branchName}`.quiet()
            } else {
              await Bun.$`git -C ${gitRoot} branch -d ${branchName}`.quiet()
            }
            branchDeleted = true
          } catch (deleteError) {
            errors.push(`Failed to delete branch: ${deleteError}`)
          }
        } else {
          // Branch doesn't exist, consider it "deleted" for success criteria
          branchDeleted = true
        }
      } catch (checkError) {
        errors.push(`Error checking branch: ${checkError}`)
      }
    }

    return JSON.stringify({
      success: worktreeRemoved && (branchDeleted || !deleteBranch),
      worktreeRemoved,
      branchDeleted,
      error: errors.length > 0 ? errors.join('; ') : undefined
    }, null, 2)
  }
})
