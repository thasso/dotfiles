---
name: git-commit-style
description: Use when staging changes, writing commit messages, or preparing commits.
---

# Git Commit Style

Use this skill whenever the user asks to commit changes or draft a commit message.

## Workflow

1. Review what changed (`git status`, staged diff, and unstaged diff as needed).
2. Summarize changes for the user in plain language.
3. Propose a commit message that follows the style below.
4. Ask for confirmation before running `git commit`.
5. Never push (`git push`) unless the user explicitly asks.

## Commit message style

- Subject line must be short and imperative.
  - Good: `Add tmux split bindings`
  - Bad: `Added tmux split bindings`
- Keep the subject focused on the primary change.
- Add a body when needed.
- Body should explain **why** and high-level intent, not line-by-line edits.
- Follow common commit message line length and styles

## Safety checks before commit

- Ensure no unrelated files are included.
- Ensure secrets or credentials are not being committed.
- If changes are broad, suggest splitting into multiple commits.

## If information is missing

Ask targeted questions before committing, for example:

- "Do you want this as one commit or split by concern?"
- "Should I include a body explaining the reasoning?"
- "Are you ready for me to run `git commit` now?"
