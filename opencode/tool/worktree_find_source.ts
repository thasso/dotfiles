import { tool } from "@opencode-ai/plugin"
import { readdir, stat } from "node:fs/promises"
import { join } from "node:path"

export default tool({
  description: "Detect git repository structure and identify source branch for worktree operations",
  args: {
    sourceBranch: tool.schema.string().optional().describe("Optional override for the source branch (defaults to main)")
  },
  async execute(args) {
    const { sourceBranch: overrideSourceBranch } = args

    let gitRoot: string
    let currentBranch: string
    let isParentDir = false

    // 1. Try to detect if we are inside a git repo
    try {
      gitRoot = await Bun.$`git rev-parse --show-toplevel`.text().then(t => t.trim())
      currentBranch = await Bun.$`git branch --show-current`.text().then(t => t.trim())
    } catch (error) {
      // Not in a git repo, check if we are in the parent directory
      const entries = await readdir(process.cwd(), { withFileTypes: true })
      const gitRepos: string[] = []

      for (const entry of entries) {
        if (entry.isDirectory()) {
          try {
            // Check for .git directory
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
          error: "Not a git repository and no git repositories found in current directory"
        }, null, 2)
      } else if (gitRepos.length > 1) {
        return JSON.stringify({
          error: `Multiple git repositories found: ${gitRepos.map(p => p.split('/').pop()).join(', ')}. Please run from inside the specific repository.`
        }, null, 2)
      }

      gitRoot = gitRepos[0]
      // Get current branch of the found repo
      currentBranch = await Bun.$`git -C ${gitRoot} branch --show-current`.quiet().text().then(t => t.trim())
      isParentDir = true
    }

    // List existing worktrees
    // Use -C to ensure we run against the repo even if in parent dir
    const worktreesList = await Bun.$`git -C ${gitRoot} worktree list`.quiet().text().then(t => t.trim())
    const worktreeLines = worktreesList.split('\n').filter(line => line.trim())

    // Detect structure
    let structure: 'flat' | 'nested' | 'parallel' = 'flat'
    const existingWorktrees: string[] = []
    let hasSiblingWorktreesDir = false

    // Check for sibling worktrees directory
    if (isParentDir) {
       hasSiblingWorktreesDir = await stat(join(process.cwd(), 'worktrees')).then(s => s.isDirectory()).catch(() => false)
    } else {
       // If in repo, check if ../worktrees exists
       const parentWorktreesDir = join(gitRoot, '..', 'worktrees')
       hasSiblingWorktreesDir = await stat(parentWorktreesDir).then(s => s.isDirectory()).catch(() => false)
    }

    for (const line of worktreeLines) {
      const match = line.match(/^([^\s]+)\s+([a-f0-9]+)\s+\[([^\]]+)\]?$/)
      if (match) {
        const path = match[1]
        const branch = match[3]
        if (path !== gitRoot) {
          existingWorktrees.push(branch)

          // Analyze path to determine structure
          if (structure === 'flat') {
             const relativePath = path.replace(gitRoot, '').replace(/^\//, '')
             if (relativePath.startsWith('worktrees/')) {
               structure = 'nested'
             } else {
               // Check if it looks like a parallel structure
               // sibling path would be ../worktrees/branch
               const parentDir = join(gitRoot, '..')
               if (path.startsWith(join(parentDir, 'worktrees'))) {
                 structure = 'parallel'
               }
             }
          }
        }
      }
    }
    
    // If we detected worktrees folder exists as sibling, use parallel
    if (structure === 'flat' && hasSiblingWorktreesDir) {
        structure = 'parallel'
    }

    // Determine source branch
    const sourceBranch = overrideSourceBranch || 'main'

    // Calculate worktree path based on detected structure
    let worktreePath: string
    if (structure === 'nested') {
      worktreePath = `${gitRoot}/worktrees`
    } else if (structure === 'parallel') {
      // Parallel: parent/worktrees
      const parentDir = isParentDir ? process.cwd() : join(gitRoot, '..')
      worktreePath = join(parentDir, 'worktrees')
    } else {
      // Flat structure: worktrees at same level as main repo
      worktreePath = gitRoot
    }

    // Return as JSON string
    return JSON.stringify({
      sourceBranch,
      worktreePath,
      repoRoot: gitRoot,
      structure,
      existingWorktrees,
      currentBranch,
      isParentDir
    }, null, 2)
  }
})
