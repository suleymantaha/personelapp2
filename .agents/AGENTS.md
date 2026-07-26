# Workspace Agent Rules

## Auto Git Flow
- **CRITICAL RULE**: Whenever changes are made and the work is finished, the agent MUST automatically follow this Git workflow without asking for permission:
  1. Create a new branch with a descriptive name (e.g., `feat/...`, `fix/...`, `refactor/...`).
  2. Stage and commit all finished changes to that branch.
  3. Push the new branch to the remote repository.
  4. Remind the user that a new branch was pushed and they can now open a Pull Request (or Merge Request) to the `main` branch.
  This behavior is auto-active for all tasks across any page or component in this workspace.
