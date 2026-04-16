# Agent Configuration

## Commands

Slash commands live in `~/.claude/commands/`. Type `/` in Claude Code to see what is available.

Command source files are in `@/Users/rlevesque/.dotfiles/agent-docs/commands/`.

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

- Use Conventional Commits.
- Keep commits atomic and focused.
- When making branches, prefix them with `reid/`.

## Checks

- Always run formatting before telling the user the job is done.
- Always run linting before telling the user the job is done.
- Always run typechecking before telling the user the job is done.
- Always build code before telling the user the job is done.
