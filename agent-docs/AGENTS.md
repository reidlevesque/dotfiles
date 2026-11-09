# Agent Configuration

## Task naming

At the start of each new task, use `list_projects` to find its project's
display name, then use `set_thread_title` to name it
`<project display name>: <short topic>`.

Start both the project prefix and the short topic with a lowercase letter.
Keep the topic concise. Preserve titles explicitly supplied by the user.

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
When creating a Linear ticket, use the LEI team.
When you start work on a Linear ticket that you created, assign it to me and
move it to In Progress:
`linear issue update <ID> --assignee self --state "In Progress"`.

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

## Slack search

Slack's API quota is shared by every user of `slack-cli` and the MaaS Slack
MCP server. Search allows 20 calls per minute and message or thread reads
allow 50 per minute for all of NVIDIA together. Two searches in one minute
can return HTTP 429. Choose the route in this order:

1. Use a connector that has its own Slack app when one is connected: the
   claude.ai Slack tools in Claude Code (`slack_search_public_and_private`,
   `slack_read_channel`, `slack_read_thread`), or the Slack plugin in Codex
   when it is authorized.
2. Use `glean-cli search --datasource slack` to find messages and threads.
   It reads Glean's index and makes no Slack API call. Expect an indexing
   lag of minutes to hours. If it reports no token, run `glean-cli auth init`,
   open the URL in a browser, and run
   `glean-cli auth complete '<callback-url>'`.
3. Use `slack-cli` only for what the routes above cannot see, such as DMs
   and group DMs.

When you use `slack-cli`:

- Run Slack calls one at a time; never run them in parallel.
- Search only to locate a conversation, then read it with
  `conversation history` or `thread replies` and a large `--limit`.
- On HTTP 429, wait the `retry-after` seconds from the error (30 for search,
  10 for history and threads) and retry once. If the same call fails twice,
  stop that route and report the gap.
- The 429 comes from Slack through the ECI gateway, not from the CLI.
  Report it as a shared-quota limit, not a local bug. Support is
  #maas-support (C07UFJPHJUU); NVBug 6941982 tracks it.

## Subspace handoffs

When I ask to hand off work to Subspace, launch standalone agents outside
Paseo. Paseo is only the launch point. Do not use Paseo `create_agent`,
`paseo run`, or the `paseo-handoff` workflow for the receiving agents.
Do not add a Paseo listener integration or forward worker completions to
Paseo. Report completion of the migration here; subsequent coordination
and decisions belong in the Subspace room.

Carry out the handoff, rather than only giving me launch commands:

1. Identify the target host, repository, room, existing crew, and current
   service configuration. Reuse them where possible. Check linked tickets
   and active work before starting anything; do not duplicate another
   agent's assignment. Preserve unrelated agents and rooms.
2. Prepare a durable handoff with the goal, acceptance criteria, authority,
   decisions, completed work, exact branches and commits, uncommitted
   changes, blockers, and next actions. Link authoritative evidence.
   Record each agent's working directory, provider-native session or thread
   ID, model, effort, role, and private Subspace client-state directory.
   Keep credentials in private files, never in prompts or logs.
3. Preflight the server's health, credentials, actual executable versions,
   bridge options, saved sessions, worktrees, and service configuration.
   A mise shim can exist without resolving a tool; execute a harmless
   version or help command. Install a missing required helper from the
   existing trusted checkout. Do not change PATH just because it uses mise.
4. Resolve required execution approval before stopping the original crew.
   The supplied bridges automatically approve tools; Codex also runs
   unsandboxed. Apply approval already given for this crew without asking
   again. Do not infer broader approval from an unrelated crew. If approval
   is missing or automatic review blocks the action, prepare the concrete
   configuration, explain the exact blocker, and ask once while the old
   crew remains available.
5. Use the native Subspace bridges under a detached supervisor. On this
   Linux host, prefer systemd user services, one per agent, grouped under
   a room-specific target. Reuse existing units. Preserve `reid/` branches
   and existing worktrees; use bridges directly when `subspace-crew` cannot
   preserve them. Do not enable reboot startup unless requested.
6. Once preflight passes, stop only the crew's old runtimes and listeners.
   For Paseo migrations, archive only the matching agent entries, never
   their workspaces. Confirm that the old provider processes have exited
   before resuming their conversations elsewhere. Never run two processes
   against the same native session or client-state directory.
7. Resume existing conversations in the same working directories with the
   same model and effort: Claude uses `--session`, Codex uses `--thread`.
   Check the installed bridge's prompt behaviour on resume. When a resume
   cannot accept a prompt, deliver the handoff through the room after the
   bridge connects. Only create a new conversation when none can be resumed;
   provide the complete handoff and record its new native ID.
8. Remove Paseo-specific tools and connection settings from the standalone
   runtime. Tell the agents to coordinate through Subspace, not recreate
   Paseo agents or send Paseo notifications. The bridge owns the sole room
   waiter and wakes idle agents. Agents must not start another waiter or
   continuously poll. Post meaningful changes rather than acknowledgements.
9. Start the standalone services and verify the native session IDs, model
   settings, room identities, and successful message delivery. Check for
   startup errors and restart loops. A running supervisor alone is not
   evidence of a working agent. If migration fails, preserve all state and
   report which workers are stopped; do not claim completion.
10. Save the actual start, stop, status, log, and viewer instructions with
    the project. Report the room and those controls concisely. Commands run
    from a Paseo terminal must control the standalone supervisor without
    creating Paseo agents. Keep workspaces used by services available.

For the existing Autonomous Rex crew, use `rex-crew.target` in the user
service manager and room `autonomous-rex-dev`. The units are
`rex-coordinator.service`, `rex-builder.service`, and `rex-reviewer.service`.
Start or stop with `systemctl --user start rex-crew.target` or
`systemctl --user stop rex-crew.target`. Its operating guide is
`/home/rlevesque/dev/github/nvidia-lpu/autonomous-rex-subspace/docs/subspace.md`.
Inspect the live configuration before relying on these host-specific paths.
`subspace-crew down` does not control this migrated crew. Stopping workers
does not delete or hide rooms; leave room history intact unless I request
otherwise.


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
- If a PR's base is a branch other than the default branch, use GitHub stacked
  PRs through `gh stack`. Do not use `gh pr create --base`. Run
  `gh stack init` or `gh stack add` for the branches, and then run
  `gh stack submit --auto` so that the PRs are drafts in one GitHub stack.
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
