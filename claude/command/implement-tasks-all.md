Use the task-implementer agent to implement the tasks in $1 one by one.

- ALWAYS check that we are starting this process with a clean git state with no
  uncommitted changes and no new files that are not part of the repository.
- ALWAYS use individual agent for each task
- ALWAYS make sure that the changes after each task completion are committed
  - If they are NOT committed, stage all pending including new files and
    use the /commit-staged command to trigger a commit
