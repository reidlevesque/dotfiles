# Agent Configuration

## Commands

Slash commands live in `~/.claude/commands/`.
Type `/` in Claude Code to see what is available.

Command source files are in `~/.dotfiles/agent-docs/commands/`.

## Local CLIs

When these local CLIs fit the task, use them:

- Outlook: `outlook-cli`
- JIRA: `jira-cli`
- Confluence: `confluence-cli`
- Calendar: `calendar-cli`
- Buildkite: `bk`

When interacting with Linear, use the `linear` CLI.

The `PATH` contains these additional CLI tools:

- `concur-cli`, `databricks-cli`, `dl-cli`, `gdrive-cli`, `glean-cli`,
  `helios-cli`, `itss-cli`, `meeting-cli`, `nicc-cli`, `nspect-cli`,
  `nvbugs-cli`, `omni-cli`, `onedrive-cli`, `onenote-cli`, `pagerduty-cli`,
  `redis-cli`, `redmine-cli`, `sfdc-cli`, `sharepoint-cli`, `slack-cli`,
  `smartsheet-cli`, `starfleet-cli`, `teams-cli`, and `transcript-cli`

To inspect the current machine inventory, run
`compgen -c | rg -- '-cli$' | sort -u`.

If `mise` blocks a needed command because local configuration must be trusted,
run `mise trust` and then retry the command.

## Latency and Tool Use

- Use medium reasoning for routine work.
- Reserve maximum reasoning for the hardest quality-first work.
- Use a faster model for collection, search, and mechanical work.
- Use no more than three subagents by default.
- Do not let subagents create subagents.
- If the root agent authorizes recursion, permit the requested delegation.
- Give each subagent a self-contained brief and minimal history.
- Limit collection-agent responses to 2,000 tokens.
- If the task needs more evidence, increase this limit.
- If tools support concurrency, run independent read-only calls concurrently.
- Use native file tools, `rg`, `fd`, and `jq` for local inspection.
- If a command does not need profile initialisation, use a non-login shell.
- Bound remote queries with narrow time ranges, fields, and result limits.
- Limit each remote status read to 60 seconds.
- If a CLI has no timeout option, run the status read with `timeout 60s`.
- If the same route times out twice, stop that route.
- Examine authentication or service health before you retry the route.
- Do not start interactive authentication in an unattended tool call.
- Do not use fixed sleeps or foreground polling loops.
- Use one bounded monitor with backoff for long-running status checks.
- For Buildkite status reads, prefer
  `bk build view --summary --json --no-input --no-pager`.
- For multi-repository GitHub reads, use GraphQL or bounded parallel requests.
- Do not send one serial request for each repository.
- For calendar searches, set a narrow date range and result limit.
- If an event ID is known, use `calendar-cli get` instead of another `find`.
- Use one service interface during a task.
- If a connector route fails twice, use the local CLI or report the blocker.
- Do not repeat a completed tool call.
- If the tool-call inputs changed, you can repeat the call.

## Documentation

Read these on demand when a task touches the topic; they are not loaded
automatically.

### Agent Tooling

- `~/.dotfiles/agent-docs/docs/claude-command-guide.md`:
  Creating custom Claude Code commands
- `~/.dotfiles/agent-docs/docs/mcp-sync-documentation.md`:
  MCP config sync

### Language Best Practices

- `~/.dotfiles/agent-docs/docs/bash-best-practices.md`:
  Bash scripting (3.2 compatible)
- `~/.dotfiles/agent-docs/docs/yaml-best-practices.md`:
  YAML formatting and structure
- `~/.dotfiles/agent-docs/docs/go-best-practices.md`:
  Go development patterns

### MCP Development

- `~/.dotfiles/agent-docs/docs/mcp-best-practices.md`:
  MCP server development

## Feedback Style

- Be direct and honest.
- Point out mistakes plainly.
- Challenge incorrect assumptions.
- Provide critical code reviews.
- Skip unnecessary hedging.

## Writing Style

- Use Canadian English spelling and conventions when writing documentation or
  code comments.
- Use 24-hour time when communicating times to the user.

## Git Workflow

- Before the first branch or worktree, run `git up` once from the root task.
- If `git up` fails, run `git fetch` and use `origin/main`.
- Reuse the refreshed base from the root task for all subagents.
- Do not run `git up` again in a subagent.
- Use Conventional Commits for commits and PR titles.
- Always include the Linear ticket ID (e.g. `ABC-123`) in the PR title when
  the work is associated with a Linear ticket.
- Keep commits atomic and focused.
- When making branches, prefix them with `reid/`.
- Open PRs in draft mode by default.
- Never run `gh auth setup-git`; it rewrites the tracked `~/.gitconfig`
  symlink target. For GitHub HTTPS auth, rely on the existing credential helper
  or pass a temporary helper with `git -c`.
- If a PR triggers a Codex code review Buildkite pipeline, unblock the
  waiting step so the review runs.
- If a draft PR doesn't run CI by default, unblock it in the buildkite pipeline.
- Never make merge commits when resolving conflicts. Instead rebase against
  the default branch.

## PR Feedback

- When posting a PR comment or review reply, prefix the comment with the running
  agent's lowercase name in square brackets, for example `[codex]` for Codex or
  `[claude]` for Claude Code.
- Examine each PR comment against the code and tests before changing code.
- If a comment is valid, fix it, push a focused change, reply to the PR
  comment, and unblock the Codex code review job in Buildkite.
- If a comment is not valid, reply to the PR comment with a clear explanation
  of why no code change is needed.

## Node Operations

- Do not suspend, quarantine, reserve, reboot, power-cycle, or otherwise remove
  Brake nodes from scheduling unless the user explicitly asks for that exact
  node operation. When CI appears blocked by a bad node, inspect logs and report
  the suspected node-health issue instead of changing node state.

## Checks

- For code changes, run formatting, linting, typechecking, and builds that apply
  to the affected target.
- For documentation changes, run only the applicable documentation checks.
- For read-only tasks, do not run change-validation commands.
- Run independent checks concurrently.
- If the inputs did not change, do not run a successful check again.
