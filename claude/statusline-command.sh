#!/usr/bin/env bash
# Claude Code status line — mirrors p10k lean prompt segments:
# dir | git branch | user@host | model | context usage

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/\~}"

# Git branch (skip lock files to avoid blocking)
git_branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree --no-optional-locks >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# Context usage indicator
ctx_str=""
if [ -n "$used_pct" ]; then
  ctx_str=$(printf "ctx:%.0f%%" "$used_pct")
fi

# Build output with ANSI colors (will be dimmed by Claude Code)
# Cyan for directory, yellow for git branch, grey for user@host, blue for model
user_host="$(whoami)@$(hostname -s)"

printf "\033[36m%s\033[0m" "$short_cwd"

if [ -n "$git_branch" ]; then
  printf " \033[33m \033[0m\033[33m%s\033[0m" "$git_branch"
fi

printf " \033[90m%s\033[0m" "$user_host"

if [ -n "$model" ]; then
  printf " \033[34m%s\033[0m" "$model"
fi

if [ -n "$ctx_str" ]; then
  printf " \033[90m%s\033[0m" "$ctx_str"
fi

printf "\n"
