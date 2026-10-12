# Design

## Context

MindFlow stores each page as a JSON file (`nodes/<id>.json`) with a plain-text `body`, a `links` list, and fixed view layouts rendered by `board_page.dart`. The shell is a five-tab `CupertinoTabBar`/sidebar in `app_shell.dart`, styled by hard-coded colors in `theme.dart`. The AI agent operates through `ToolExecutor` in `tools.dart`. Constraints: local-first file store (no server), Windows desktop is primary, iOS/mobile must stay usable, and the existing integrations, schedule, notifications, and chat must keep working. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- One source of truth for page content that both the editor and the agent read and write.
- A link index and search index that stay correct on every save, including agent writes.
- A token-based theme and shell that every new screen reuses.
- Zero data loss for existing nodes, views, chat, schedule, and settings.

**Non-Goals:**
- Real-time collaboration, cloud sync, account system.
- Obsidian plugin ecosystem, community plugins, themes from marketplace.
- OS-level global hotkeys outside the app window (in-app shortcuts only).
- Full Notion permissioning/sharing.

## Decisions

**Markdown string as the body, blocks derived at load.** `MindNode.body` stays a markdown string; a parser splits it into typed blocks (heading, todo, toggle, callout, code, quote, list, table, divider, image, paragraph) for editing and rendering. Chosen over a structured block-JSON body because it preserves the existing store, agent tools, and chat, keeps bodies portable (openable in Obsidian/VS Code), and matches the user's markdown-first choice. Alternative considered: block-JSON body — richer drag/reorder guarantees, but breaks the current store format and agent tool contract, so deferred.

**JSON files remain source of truth; markdown mirror files are generated.** Each page also writes `vault/<space>/<page>.md` for portability and external graph tools. The JSON is authoritative; the mirror is regenerated on save and never read back as input. Alternative: markdown as source of truth — rejected because node metadata (due, reminders, priority, review state) has no clean markdown home and the agent tools depend on JSON.

**Link index rebuilt on every save, persisted to `links.json`.** On save, the parser extracts `[[wikilinks]]` and `#tags`, syncs them with `MindNode.links`, and updates an in-memory adjacency map (out/in). Rename updates all inbound wikilinks. Rebuild-on-save is O(body length) and keeps agent writes consistent. Alternative: lazy scan on demand — rejected: backlinks panel and graph need the index at open time.

**In-memory inverted index for search, persisted to `search.json`.** Tokens from title, body, tags, properties map to node ids with block offsets for snippet jumps. Rebuilt incrementally on save. Chosen over SQLite FTS: the vault is a few thousand pages, a Dart map is simpler and avoids a new native dependency. Alternative considered: SQLite FTS5 — better for very large vaults; revisit if vault exceeds ~10k pages.

**Graph view via CustomPainter with force-directed layout computed in Dart.** Nodes are drawn on a canvas with pan/zoom (Transform widget) and hit-testing for selection. Chosen over third-party graph packages: none mature in Flutter for this scale, and a painter integrates with the theme tokens. Layout is computed lazily and cached; for >2,000 nodes the graph renders a filtered subgraph.

**Markdown preview via `flutter_markdown`; editing uses a custom block model.** Preview rendering is delegated to `flutter_markdown` (maintained, supports code highlighting via `highlight`). The editor itself is a list of block widgets bound to the parsed model, so slash commands, drag handles, and todo checkboxes operate on blocks, not raw text. Alternative: pure custom renderer — rejected as unnecessary effort.

**ThemeExtension tokens, dark-first with purple accent.** A `Tokens` ThemeExtension carries color, spacing, radius, type scale, elevation, motion; `theme()` builds light and dark `ThemeData` from the same tokens, with dark as the default on first launch. A single purple seed color generates the accent family: accent, sidebar highlight, focus ring, link, selection, and graph-edge tint, with dark-surface neutrals (near-black background, elevated card, hairline) tuned to read against purple. The light theme keeps the same purple accent. Components read tokens through `Theme.of(context).extension<Tokens>()`. Replaces the static `Apple` color class; `Apple` remains as a deprecated alias during migration.

**Shell: custom sidebar + pane stack, provider state.** The shell keeps `provider` (already in use) with a `ShellState` for open panes, sidebar collapse, and current page. Wide layout: sidebar + up to two panes; narrow: single pane + drawer. Keyboard shortcuts via `Callbacks`/`Shortcuts` and `Focus` for focus rings. Chosen over `NavigationRail`: needs nested tree, favorites, recents.

**Quick capture is in-app (Ctrl+Shift+Space) and queues to the agent.** Captures are saved as `type: capture` nodes immediately; a queue drains to the agent when idle, reusing the existing `sendChat` path. Global OS hotkey deferred (needs platform plugins).

**Data model additions.** `MindNode` gains `parentId`, `spaceId`, `properties` (Map), `icon`, `cover`, `review` (due, interval, ease, reps, lapses). `ViewDef` gains `columns` (list of property ids) and `filters` (list of {field, op, value}); old single-field filters map into the new list. `settings.json` gains `uiVersion` to gate migration.

**Agent tool surface extension.** New tools: `create_page`, `update_page_body`, `append_block`, `link_pages`, `search`, `create_database_view`, `add_review_card`, `grade_card`, `plan_exams`. Existing tools unchanged so current prompts keep working.

**Dependencies added:** `flutter_markdown`, `markdown`, `highlight`. No graph, search, or hotkey packages.

## Risks / Trade-offs

- [Block parser diverges from `flutter_markdown` rendering] → single parser feeds both editor and preview; preview uses the same parsed blocks, not a second parse.
- [Migration corrupts existing nodes] → migration runs once behind `uiVersion`, writes a timestamped backup copy of `nodes/` before touching files; failures leave originals untouched.
- [Graph performance on large vaults] → layout cached, filtered subgraph beyond 2,000 nodes, node size LOD by zoom.
- [Agent tool growth increases prompt size and misuse risk] → new tools mirror existing shapes; system prompt updated in the same task as tool addition.
- [Mobile layout crams desktop features] → panes collapse to single-pane stack; graph and table views degrade to scrollable lists on narrow screens.
- [Rename cascades break links] → rename is a single transaction updating index, mirrors, and inbound wikilinks; partial failure rolls back.

## Migration Plan

1. On `MemoryStore.open`, read `uiVersion`; if < 2, back up `nodes/` and `views/`, add new fields with defaults, parse bodies into blocks lazily, generate `vault/` mirrors, build `links.json` and `search.json`, set `uiVersion = 2`.
2. Old view layouts map to database configs (list→list, kanban→board, grid→gallery, calendar→calendar, focus→list with limit, timeline→list sorted by due).
3. Rollback: restore the backup directory and reset `uiVersion`; app runs the pre-change shell.

## Open Questions

- OS-level global quick-capture hotkey on Windows (needs a platform plugin) — deferred, in-app shortcut ships first.
- Whether vault mirrors should be Obsidian-compatible enough to open the folder directly in Obsidian (front-matter format) — decide during mirror implementation.
