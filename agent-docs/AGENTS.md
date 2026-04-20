# Agent Configuration

## Commands

Slash commands live in `~/.claude/commands/`. Type `/` in Claude Code to see what is available.

Command source files are in `@/Users/rlevesque/.dotfiles/agent-docs/commands/`.

## Local CLIs

These local CLIs are available and should be preferred when they fit the task:

- Outlook: `outlook-cli`
- JIRA: `jira-cli`
- Confluence: `confluence-cli`
- Calendar: `calendar-cli`
- Buildkite: `bk`

Additional installed CLI tools are available in `/opt/homebrew/bin`, including:

- `concur-cli`, `databricks-cli`, `dl-cli`, `gdrive-cli`, `glean-cli`, `helios-cli`, `itss-cli`, `meeting-cli`, `nicc-cli`, `nspect-cli`, `nvbugs-cli`, `omni-cli`, `onedrive-cli`, `onenote-cli`, `pagerduty-cli`, `redis-cli`, `redmine-cli`, `sfdc-cli`, `sharepoint-cli`, `slack-cli`, `smartsheet-cli`, `starfleet-cli`, `teams-cli`, and `transcript-cli`

To inspect the current machine inventory, run `printf '%s\n' /opt/homebrew/bin/*-cli`.

## Documentation

### Agent Tooling

- `@/Users/rlevesque/.dotfiles/agent-docs/docs/claude-command-guide.md` - Creating custom Claude Code commands
- `@/Users/rlevesque/.dotfiles/agent-docs/docs/mcp-sync-documentation.md` - MCP config sync

### Language Best Practices

- `@/Users/rlevesque/.dotfiles/agent-docs/docs/bash-best-practices.md` - Bash scripting (3.2 compatible)
- `@/Users/rlevesque/.dotfiles/agent-docs/docs/yaml-best-practices.md` - YAML formatting and structure
- `@/Users/rlevesque/.dotfiles/agent-docs/docs/go-best-practices.md` - Go development patterns

### MCP Development

- `@/Users/rlevesque/.dotfiles/agent-docs/docs/mcp-best-practices.md` - MCP server development

## Feedback Style

- Be direct and honest.
- Point out mistakes plainly.
- Challenge incorrect assumptions.
- Provide critical code reviews.
- Skip unnecessary hedging.

## Git Workflow

- Use Conventional Commits for commits and PR titles.
- Keep commits atomic and focused.
- When making branches, prefix them with `reid/`.
- Never make merge commits when resolving conflicts. Instead rebase against the default branch.

## Checks

- Always run formatting before telling the user the job is done.
- Always run linting before telling the user the job is done.
- Always run typechecking before telling the user the job is done.
- Always build code before telling the user the job is done.
