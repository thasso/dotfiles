import { tool } from "@opencode-ai/plugin"
import { readdir, stat, mkdir } from "node:fs/promises"
import { join } from "node:path"

export default tool({
  description: "Create a new git worktree with branch name validation",
  args: {
    branchName: tool.schema.string().describe("Branch name (must start with 'agent-')"),
    sourceBranch: tool.schema.string().optional().describe("Source branch to branch from (defaults to 'main')"),
    createBranch: tool.schema.boolean().optional().default(true).describe("Create branch if it doesn't exist"),
    targetPath: tool.schema.string().optional().describe("Override auto-detected worktree path")
  },
  async execute(args) {
    const { branchName, sourceBranch = 'main', createBranch = true, targetPath } = args

    // Validate branch name starts with 'agent-'
    if (!branchName.startsWith('agent-')) {
      return JSON.stringify({
        success: false,
        error: `Branch name must start with 'agent-'. Got: ${branchName}`
      }, null, 2)
    }

    let gitRoot: string
    let isParentDir = false

    // Get repository information
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

    // Detect existing worktrees to determine structure
    const worktreesList = await Bun.$`git -C ${gitRoot} worktree list`.quiet().text().then(t => t.trim())
    const worktreeLines = worktreesList.split('\n').filter(line => line.trim())

    let structure: 'flat' | 'nested' | 'parallel' = 'flat'
    let hasSiblingWorktreesDir = false

    // Check for sibling worktrees directory
    if (isParentDir) {
       hasSiblingWorktreesDir = await stat(join(process.cwd(), 'worktrees')).then(s => s.isDirectory()).catch(() => false)
    } else {
       const parentWorktreesDir = join(gitRoot, '..', 'worktrees')
       hasSiblingWorktreesDir = await stat(parentWorktreesDir).then(s => s.isDirectory()).catch(() => false)
    }

    for (const line of worktreeLines) {
      const match = line.match(/^([^\s]+)\s+([a-f0-9]+)\s+\[([^\]]+)\]?$/)
      if (match) {
        const path = match[1]
        if (path !== gitRoot) {
          const relativePath = path.replace(gitRoot, '').replace(/^\//, '')
          if (relativePath.startsWith('worktrees/')) {
            structure = 'nested'
          } else {
            const parentDir = join(gitRoot, '..')
            if (path.startsWith(join(parentDir, 'worktrees'))) {
              structure = 'parallel'
            }
          }
        }
      }
    }

    // If we detected worktrees folder exists as sibling, use parallel
    if (structure === 'flat' && hasSiblingWorktreesDir) {
        structure = 'parallel'
    }

    // Calculate worktree path
    let worktreeDir: string
    if (targetPath) {
      worktreeDir = targetPath
    } else if (structure === 'nested') {
      worktreeDir = `${gitRoot}/worktrees`
    } else if (structure === 'parallel') {
      const parentDir = isParentDir ? process.cwd() : join(gitRoot, '..')
      worktreeDir = join(parentDir, 'worktrees')
    } else {
      worktreeDir = gitRoot
    }

    // Ensure worktree directory exists for parallel/nested structures
    if (structure === 'parallel' || structure === 'nested') {
      try {
        await mkdir(worktreeDir, { recursive: true })
      } catch (error) {
        // Directory might already exist, ignore
      }
    }

    // Check if worktree already exists
    const existingWorktree = worktreeLines.find(line =>
      line.startsWith(`${worktreeDir}/${branchName}`) ||
      line.includes(`[${branchName}]`)
    )

    if (existingWorktree) {
      return JSON.stringify({
        success: false,
        error: `Worktree for branch '${branchName}' already exists`,
        branchName,
        worktreePath: existingWorktree.split(' ')[0]
      }, null, 2)
    }

    // Check if branch already exists (when not creating)
    let branchExists = false
    try {
      await Bun.$`git -C ${gitRoot} show-ref --verify --quiet refs/heads/${branchName}`.quiet()
      branchExists = true
    } catch {
      branchExists = false
    }

    if (branchExists && !createBranch) {
      return JSON.stringify({
        success: false,
        error: `Branch '${branchName}' already exists and createBranch is false`,
        branchName
      }, null, 2)
    }

    try {
      // Create worktree
      const worktreePath = `${worktreeDir}/${branchName}`
      
      if (createBranch) {
        await Bun.$`git -C ${gitRoot} worktree add -b ${branchName} ${worktreePath} ${sourceBranch}`.quiet()
      } else if (branchExists) {
        await Bun.$`git -C ${gitRoot} worktree add ${worktreePath} ${branchName}`.quiet()
      } else {
        return JSON.stringify({
          success: false,
          error: `Branch '${branchName}' does not exist and createBranch is false`,
          branchName
        }, null, 2)
      }

      return JSON.stringify({
        success: true,
        branchName,
        worktreePath,
        repoRoot: gitRoot,
        structure
      }, null, 2)
    } catch (error) {
      return JSON.stringify({
        success: false,
        error: `Failed to create worktree: ${error}`,
        branchName
      }, null, 2)
    }
  }
})
