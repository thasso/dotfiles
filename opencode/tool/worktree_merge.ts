import { tool } from "@opencode-ai/plugin"
import { readdir, stat } from "node:fs/promises"
import { join } from "node:path"

export default tool({
  description: "Merge a worktree branch to source using squash merge with conflict handling",
  args: {
    branchName: tool.schema.string().describe("Branch name to merge"),
    sourceBranch: tool.schema.string().optional().default('main').describe("Target branch (defaults to 'main')"),
    autoResolveConflicts: tool.schema.boolean().optional().default(true).describe("Attempt simple conflict auto-resolution"),
    commitMessage: tool.schema.string().optional().describe("Custom commit message override"),
    dryRun: tool.schema.boolean().optional().default(false).describe("Preview merge without executing")
  },
  async execute(args) {
    const { branchName, sourceBranch = 'main', autoResolveConflicts = true, commitMessage: customMessage, dryRun = false } = args

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

    // Get worktree path
    const worktreesList = await Bun.$`git -C ${gitRoot} worktree list`.quiet().text().then(t => t.trim())
    const worktreeLines = worktreesList.split('\n').filter(line => line.trim())

    let worktreePath: string | null = null
    for (const line of worktreeLines) {
      const match = line.match(/^([^\s]+)\s+([a-f0-9]+)\s+\[([^\]]+)\]?$/)
      if (match && match[3] === branchName) {
        worktreePath = match[1]
        break
      }
    }

    if (!worktreePath) {
      return JSON.stringify({
        success: false,
        error: `Worktree for branch '${branchName}' not found`
      }, null, 2)
    }

    // Get diff statistics
    let diffStat = ''
    let diffNumstat = ''
    try {
      diffStat = await Bun.$`git -C ${gitRoot} diff --stat ${sourceBranch}..${branchName}`.quiet().text().then(t => t.trim())
      diffNumstat = await Bun.$`git -C ${gitRoot} diff --numstat ${sourceBranch}..${branchName}`.quiet().text().then(t => t.trim())
    } catch (error) {
      return JSON.stringify({
        success: false,
        error: `Failed to get diff statistics: ${error}`,
        branchName,
        sourceBranch
      }, null, 2)
    }

    if (!diffNumstat && !customMessage) {
      return JSON.stringify({
        success: false,
        error: `No changes found between ${sourceBranch} and ${branchName}`,
        filesChanged: 0
      }, null, 2)
    }

    // Parse diff statistics
    let filesChanged = 0
    let insertions = 0
    let deletions = 0
    if (diffNumstat) {
      for (const line of diffNumstat.split('\n')) {
        const parts = line.split('\t')
        if (parts.length >= 3) {
          filesChanged++
          insertions += parseInt(parts[0]) || 0
          deletions += parseInt(parts[1]) || 0
        }
      }
    }

    if (dryRun) {
      return JSON.stringify({
        success: true,
        mergeType: 'squash',
        dryRun: true,
        branchName,
        sourceBranch,
        filesChanged,
        insertions,
        deletions,
        diffSummary: diffStat
      }, null, 2)
    }

    // Generate commit message if not provided
    let commitMessage = customMessage
    if (!commitMessage) {
      // Get a summary of changes
      let shortlog = ''
      try {
        shortlog = await Bun.$`git -C ${gitRoot} log --oneline ${sourceBranch}..${branchName}`.quiet().text().then(t => t.trim())
      } catch (error) {
        // Ignore error, just won't have shortlog
      }

      // Extract feature name from branch name
      const featureName = branchName.replace(/^agent-/, '').replace(/-/g, ' ')

      commitMessage = `Implement ${featureName}`

      if (shortlog) {
        const commits = shortlog.split('\n').filter(l => l.trim())
        if (commits.length > 0) {
          commitMessage += `\n\n${commits.join('\n')}`
        }
      }
    }

    try {
      // Switch to source branch in main repo
      await Bun.$`git -C ${gitRoot} checkout ${sourceBranch}`.quiet()

      // Attempt squash merge
      let mergeOutput = ''
      let conflicts: string[] = []
      let autoResolved: string[] = []
      let commitCreated = false

      try {
        // Squash merge without committing
        await Bun.$`git -C ${gitRoot} merge --squash ${branchName}`.quiet()
        mergeOutput = 'Merge prepared'

        // Commit the merge using stdin to handle multi-line messages
        await Bun.$`git -C ${gitRoot} commit -F -`.stdin(commitMessage).quiet()
        commitCreated = true
      } catch (mergeError) {
        const errorOutput = String(mergeError)

        if (errorOutput.includes('conflict')) {
          mergeOutput = 'Merge has conflicts'

          // Get list of conflicted files
          const conflictFiles = await Bun.$`git -C ${gitRoot} diff --name-only --diff-filter=U`.quiet().text().then(t => t.trim())
          conflicts = conflictFiles.split('\n').filter(f => f.trim())

          // Attempt simple auto-resolution
          if (autoResolveConflicts && conflicts.length > 0) {
            for (const file of conflicts) {
              try {
                // Try to use git's conflict markers resolution for simple cases
                await Bun.$`git -C ${gitRoot} checkout --ours ${file}`.quiet()
                await Bun.$`git -C ${gitRoot} add ${file}`.quiet()
                autoResolved.push(file)
              } catch (resolveError) {
                // Keep as unresolved
              }
            }

            // Update conflicts list after auto-resolution
            try {
              const remainingConflicts = await Bun.$`git -C ${gitRoot} diff --name-only --diff-filter=U`.quiet().text().then(t => t.trim())
              conflicts = remainingConflicts.split('\n').filter(f => f.trim())
            } catch (error) {
              // If this fails, assume conflicts remain
            }

            // If all conflicts resolved, commit the merge
            if (conflicts.length === 0) {
              try {
                await Bun.$`git -C ${gitRoot} commit -F -`.stdin(commitMessage).quiet()
                commitCreated = true
              } catch (commitError) {
                // Commit failed after auto-resolution
              }
            }
          }
        } else {
          throw mergeError
        }
      }

      // Get final diff summary (only if commit was created)
      let finalDiffStat = diffStat
      if (commitCreated) {
        try {
          finalDiffStat = await Bun.$`git -C ${gitRoot} show --stat HEAD`.quiet().text().then(t => t.trim())
        } catch (error) {
          // Use original diffStat if this fails
        }
      }

      return JSON.stringify({
        success: conflicts.length === 0 && commitCreated,
        mergeType: 'squash',
        commitMessage,
        branchName,
        sourceBranch,
        filesChanged,
        insertions,
        deletions,
        conflicts: conflicts.length > 0 ? conflicts : undefined,
        autoResolved: autoResolved.length > 0 ? autoResolved : undefined,
        diffSummary: finalDiffStat,
        needsManualResolution: conflicts.length > 0,
        commitCreated
      }, null, 2)
    } catch (error) {
      return JSON.stringify({
        success: false,
        error: `Merge failed: ${error}`,
        branchName,
        sourceBranch
      }, null, 2)
    }
  }
})
