# Oh My Pi (OMP) — Prebuilt Tools Reference

Complete list of built-in tools available in the OMP coding harness.

---

## Core File Operations

### `read`
Read files, directories, archives (tar/zip), SQLite databases, internal resources, images, documents (PDF/DOCX/etc.), and web URLs. Supports line-range selectors (`:50-100`), raw mode (`:raw`), structural summaries for code files, and multiple concurrent range reads. Internally routes through URL cache, archive reader, SQLite reader, and internal URL resolver.

### `write`
Create or overwrite files, archive entries (tar/zip), SQLite rows (insert/update/delete), or resolve merge conflicts (`conflict://`). Supports LSP format-on-write, shebang auto-chmod, and auto-generated file protection.

### `edit`
Apply source edits using a hashline patch language. Anchored on `[PATH#TAG]` snapshots from `read`/`search`. Operations: `SWAP` (replace lines), `SWAP.BLK` (replace tree-sitter block), `DEL` / `DEL.BLK` (delete), `INS.PRE` / `INS.POST` / `INS.BLK.POST` (insert), `INS.HEAD` / `INS.TAIL` (file start/end). Supports multi-file sections in one call.

---

## Search & Discovery

### `find`
Find filesystem paths by glob. Supports multiple paths, `.gitignore` respect, hidden files, and native globbing. Returns paths sorted by modification time. Use for filename/path discovery.

### `search`
Search file contents with regex (Rust RE2-style) across files, directories, globs, and internal URLs. Supports multi-line patterns, context lines, file-page pagination, and archive member search. Use for content matching.

### `ast_grep`
Structural code search via native ast-grep. Matches AST patterns (`$NAME`, `$_`, `$$$NAME`, `$$$`) across 50+ languages. Returns hashline-anchored match results with captured metavariables. Use when syntax shape matters more than text.

### `ast_edit`
Preview and apply structural rewrites via native ast-grep. Rewrite rules (`pat` → `out`) substitute matched AST nodes. Always previews first; actual writes happen through the `resolve` tool. Use for codebase-wide codemods.

### `web_search`
Run a web query through available search providers (Perplexity, Gemini, Anthropic, Brave, Tavily, Kagi, Exa, SearXNG, and others). Returns LLM-formatted answers, source URLs, and optional citations. Supports recency filtering and multiple provider fallback.

---

## Code Intelligence

### `lsp`
Query language servers for diagnostics, definition, references, hover, symbols, rename, code actions, type definition, implementation, capabilities, and raw LSP requests. Supports workspace-level diagnostics (`cargo check`, `tsc --noEmit`, `go build`), file rename with workspace edit application, and `lspmux` multiplexing.

### `debug`
Drive one DAP (Debug Adapter Protocol) debug session. Actions: launch, attach, set/remove breakpoints (source, function, instruction, data), continue, step over/in/out, pause, evaluate expressions, inspect stack traces, threads, scopes, variables, disassemble, read/write memory, list modules and loaded sources, send custom DAP requests, view output, terminate. Also exposes interactive TUI for logs, performance profiling, heap snapshots, system diagnostics, and report bundles.

---

## Execution

### `bash`
Execute shell commands in the session workspace. Supports PTY mode, background/async execution, auto-backgrounding, environment variables, and working directory override. Intercepts commands that shadow better tools (`cat` → `read`, `grep` → `search`, `sed -i` → `edit`, etc.). Persistent shell sessions with streaming tail output.

### `eval`
Execute Python or JavaScript code in persistent cell-based runtimes. Python uses an IPython-style subprocess kernel; JavaScript uses a persistent VM. Both support `display()`, `read()`, `write()`, `tool.<name>()`, `completion()` (oneshot model calls), `agent()` (subagent spawning), `parallel()`, `pipeline()`, and `budget` inspection. State persists across cells and tool calls.

---

## Browser Automation

### `browser`
Open, reuse, close, and script browser tabs against headless Chromium, CDP-attached apps, or cmux surfaces. The `tab` helper API provides: navigation, accessibility snapshots, ARIA snapshots, element interaction (click, type, fill, drag, scroll), screenshots, content extraction, file upload, and wait helpers. Supports stealth patches for headless mode, custom Electron app attachment, and dialog auto-handling.

---

## Task Orchestration

### `task`
Spawn subagents for background or foreground work. Batch mode (`tasks[]`) fans out independent tasks; flat mode spawns one per call. Supports agent discovery (project/user/bundled agents), isolated workspaces (APFS/Btrfs/ZFS/overlayfs clones), branch/patch merge strategies, and structured output. Subagents share `local://` files, `irc` for peer coordination, and `history://` for transcript access.

### `job`
Wait for or cancel background jobs managed by the session async runtime. Actions: poll specific job ids, poll all running jobs, cancel jobs, or list all jobs. Adaptive polling intervals, delivery suppression for watched jobs, and progress snapshots.

### `irc`
Send and receive messages between agents over a process-global mailbox bus. Operations: `list` peers, `send` direct or broadcast messages (with optional `await` for round-trip), `wait` for incoming messages, and `inbox` drain/peek. Wakes idle agents, revives parked agents.

---

## Session Management

### `todo`
Manage a phased task list. Operations: `init` (replace list), `start` (mark in-progress), `done` (mark completed), `drop` (abandon), `rm` (remove), `append` (add to phase), `view` (read-only echo). Enforces single-active-task invariant. Survives session resume.

### `checkpoint`
Mark the current conversation state so later `rewind` can collapse exploratory context into a concise report. Records message count and session entry ID. Top-level sessions only.

### `rewind`
End an active checkpoint by pruning exploratory context and retaining a concise report. Replaces in-memory conversation history with the prefix up to the checkpoint. Persists a `branch_summary` entry. Requires an active checkpoint.

---

## User Interaction

### `ask`
Prompt the interactive user for option-picker or free-form answers. Supports single-select, multi-select, recommended defaults, custom input, timeout auto-selection, and multi-question navigation.

---

## Memory (Long-Term)

### `recall`
Search the active long-term memory backend (Hindsight or Mnemopi) and return matching memories. Supports scoped banks (global, per-project, per-project-tagged), tag filtering, and scored results.

### `reflect`
Synthesize an answer over the active long-term memory backend. Hindsight performs server-side reflection; Mnemopi performs local recall + formatting. Supports extra context guidance.

### `retain`
Store durable facts through the active long-term memory backend. Hindsight uses queued batch writes with debounced flush; Mnemopi writes directly to local SQLite. Supports scoped banks and metadata.

---

## Source Control

### `github`
Dispatch GitHub CLI operations. Operations: `repo_view`, `pr_create` (with draft/reviewers/labels), `pr_checkout` (with worktrees), `pr_push`, `search_issues`, `search_prs`, `search_code`, `search_commits`, `search_repos`, and `run_watch` (streaming GitHub Actions monitor). Integrates with `issue://` and `pr://` internal URL schemes for cached reads.

---

## Utilities

### `inspect_image`
Send a local image file (PNG, JPEG, GIF, WEBP) to a vision-capable model and return text analysis. Supports auto-resize, WebP re-encoding for unsupported models, and configurable model selection.

### `resolve`
Finalize a pending action by applying or discarding it. Used by `ast_edit` previews, plan approvals, and other preview/apply workflows. Consumes queued or standing resolve handlers.

### `search_tool_bm25`
Search the hidden tool-discovery index and activate top matches for the current session. Uses BM25 ranking over tool names, labels, descriptions, and schema keys. Enables discovery of MCP and built-in tools not yet in the active tool set.

---

## Internal URL Schemes

These are not standalone tools but are accessible through `read` and `write`:

| Scheme | Purpose |
|---|---|
| `skill://<name>` | Skill instructions and files |
| `rule://<name>` | Rule details |
| `agent://<id>` | Subagent output artifacts |
| `artifact://<id>` | Tool output artifacts |
| `history://<id>` | Agent transcripts |
| `local://<name>` | Session-local persistent files |
| `memory://` | Memory backend data |
| `mcp://<uri>` | MCP server resources |
| `issue://<N>` | GitHub issues (cached) |
| `pr://<N>` | GitHub PRs (cached, including diffs) |
| `vault://` | Vault secrets |
| `conflict://<id>` | Merge conflict resolutions |
