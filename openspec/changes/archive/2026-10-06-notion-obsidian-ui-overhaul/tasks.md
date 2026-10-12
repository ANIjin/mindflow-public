# Tasks

## 1. Foundation: dependencies, tokens, migration

- [x] 1.1 Add `flutter_markdown`, `markdown`, `highlight` to pubspec.yaml and verify `flutter pub get` succeeds
- [x] 1.2 Create `Tokens` ThemeExtension (color, spacing, radius, type scale, elevation, motion) with light and dark token sets built from one purple seed (accent, sidebar highlight, focus ring, link, graph-edge tint) and dark as the default theme, and verify `theme()` produces both themes from the same tokens and a first-launch test renders dark with the purple accent
- [x] 1.3 Update `theme.dart` components to read tokens via `Theme.of(context).extension<Tokens>()`, keep `Apple` as deprecated alias, and verify existing screens render in both dark (default) and light with the purple accent
- [x] 1.4 Add `uiVersion` to settings and implement the v2 migration (backup `nodes/` and `views/`, add new node fields with defaults, map old layouts to database configs), and verify a pre-change store opens with all nodes, views, chat, and settings intact and a backup directory exists
- [x] 1.5 Write migration unit tests (legacy node fields, layout mapping, backup creation, idempotence on second open) and verify they pass with `flutter test`

## 2. Data model, parser, and indices

- [x] 2.1 Extend `MindNode` with `parentId`, `spaceId`, `properties`, `icon`, `cover`, `review` (due, interval, ease, reps, lapses) and JSON round-trip, and verify round-trip unit tests pass
- [x] 2.2 Implement the markdown block parser (heading, todo, toggle, callout, code, quote, bulleted/numbered list, table, divider, image, paragraph) that splits `body` into blocks, and verify parser tests cover each block type and legacy plain-text bodies
- [x] 2.3 Implement wikilink/tag extraction and sync with `MindNode.links`, and verify extraction tests for links, tags, and unresolved links
- [x] 2.4 Build the link index (in/out adjacency, persisted `links.json`, rebuilt on save, rename cascade), and verify tests: save updates index, rename updates inbound links, delete removes entries
- [x] 2.5 Build the search index (tokens from title/body/tags/properties with block offsets, persisted `search.json`, incremental rebuild), and verify tests: query finds body text with offset, deleted page removed from results
- [x] 2.6 Generate `vault/` markdown mirrors on save with front-matter, and verify a saved page produces a mirror file matching its body

## 3. Workspace shell and sidebar

- [x] 3.1 Implement `ShellState` (open panes, current page, sidebar collapse) on provider and verify state changes notify listeners
- [x] 3.2 Build the sidebar: spaces, nested page tree with expand/collapse, favorites, recents (cap 10), current-page highlight, and verify tree rendering tests for nesting and recents cap
- [x] 3.3 Build the responsive shell: ≥700px sidebar + panes, narrow single pane + drawer, collapsible icon rail, and verify layout tests at 1000px and 400px widths
- [x] 3.4 Add keyboard shortcuts (palette, new page, search, toggle sidebar, focus editor) and visible focus indicators, and verify a widget test that Ctrl+K opens the palette and Tab shows focus rings
- [x] 3.5 Wire the shell to existing pages (board, calendar, chat, memory, settings) so integrations, schedule, notifications, and chat keep working, and verify the app launches with no runtime errors on Windows

## 4. Page editor

- [x] 4.1 Build the block editor widget list bound to the parsed model with autosave (≤2s idle, saved indicator), and verify widget tests: edit persists, indicator shows saved
- [x] 4.2 Render live preview via `flutter_markdown` fed by the same parsed blocks, and verify preview tests for headings, code, tables
- [x] 4.3 Implement typed blocks (todo checkbox, toggle collapse, callout, code, quote, table, divider, image) with block-local styling, and verify each block type round-trips through editor and preview
- [x] 4.4 Implement the slash-command menu on `/` with fuzzy filtering and block insertion, and verify a widget test: `/tab` inserts a table
- [x] 4.5 Implement drag-to-reorder blocks with persisted order, and verify a reorder test moves a block and saves
- [x] 4.6 Implement `[[` autocomplete over page titles, unresolved-link create-page affordance, and clickable links, and verify tests for existing, missing, and clicked links
- [x] 4.7 Implement `#` tag autocomplete and clickable tag chips, and verify a test inserts an existing tag and filters on click
- [x] 4.8 Document the editor in `doc/page-editor.md` (block types, shortcuts, markdown subset) and verify the documented shortcuts match the implementation

## 5. Links, backlinks, and graph

- [x] 5.1 Build the backlinks panel (grouped by linking block, click opens target block), and verify a test: saved link appears on target page and click scrolls to block
- [x] 5.2 Build the forward-links panel with click-to-open, and verify a test lists outgoing links
- [x] 5.3 Implement unlinked-mention detection and convert-to-wikilink action, and verify a test finds a mention and conversion updates the index
- [x] 5.4 Build the graph view (CustomPainter, force-directed layout, pan/zoom, node select opens page, filters by type/tag/direction, filtered subgraph beyond 2000 nodes), and verify a widget test renders nodes and selecting one opens the page
- [x] 5.5 Verify node-link parity: agent `link_nodes` shows in forward/backlinks panels, and a test asserts both directions

## 6. Database views

- [x] 6.1 Extend `ViewDef` with `columns` and `filters` list, and verify JSON round-trip tests
- [x] 6.2 Implement the database engine: apply filters (AND), sorts (multi), grouping, and node count, and verify engine tests for filter/sort/group combinations
- [x] 6.3 Implement table, board, gallery, calendar, and list layouts over the engine, and verify layout tests render the same node set in each layout
- [x] 6.4 Implement property selection per view (show/hide fields), and verify a test hides unselected fields
- [x] 6.5 Implement inline editing (title, status, priority, due, tags) from rows/cards with immediate persistence, and verify a test checks off a row without opening the page
- [x] 6.6 Migrate existing views through the engine preserving name, filters, sorts, order, pinned, and verify a launch test shows old views rendering with prior config
- [x] 6.7 Replace the board page with the database workspace and verify the board shows all views with counts

## 7. Command palette, search, quick capture

- [x] 7.1 Implement the command palette overlay (Ctrl/Cmd+K, command list, fuzzy match, execute, no-results → content search), and verify widget tests for open, match, execute, empty state
- [x] 7.2 Wire global search UI to the search index (ranked results, snippets, open at matching block), and verify a test opens a page at the matched block
- [x] 7.3 Implement quick capture (in-app shortcut, saves capture node, queues to agent when idle, reports filing location), and verify a test captures text while busy and the queue drains after
- [x] 7.4 Document palette commands and search behavior in `doc/palette-and-search.md` and verify the documented command list matches registered commands

## 8. Knowledge base primitives

- [x] 8.1 Implement spaces and page hierarchy operations (create child, rename, move/re-parent, duplicate, delete with child re-parent confirmation), and verify tests for each operation including delete-with-children
- [x] 8.2 Implement templates (blank, class notes, assignment brief, weekly plan, meeting notes) and new-page-from-template, and verify a test creates a page pre-filled from a template
- [x] 8.3 Implement daily notes (create on first access, sidebar link, day's classes and due items surfaced), and verify a test creates today's note with due items
- [x] 8.4 Implement class pages generated from schedule entries with assignments listed, and verify a test adds a class and shows its page with assignments
- [x] 8.5 Implement page metadata (icon, cover, custom properties) displayed in header and sidebar, and verify a test sets an icon and shows it in both places

## 9. Study tools

- [x] 9.1 Build the review deck (cards from todo blocks, tagged notes, assignment pages; spaced-repetition state; due-today count), and verify tests: card creation, due count
- [x] 9.2 Implement the review session (one card at a time, again/hard/good/easy grading, interval update, next due date, session end), and verify grading tests for each grade
- [x] 9.3 Implement the exam planner (register exam, countdown, generated study plan on calendar and daily note, recompute on date change), and verify a test schedules study blocks before an exam and recomputes after a date change
- [x] 9.4 Implement note-to-assignment linking shown on both pages with coverage count, and verify a test links a note and shows it on both pages
- [x] 9.5 Implement study session tracking (date, duration, cards reviewed) and weekly summary, and verify a test records sessions and produces the summary
- [x] 9.6 Document the study loop in `doc/study-tools.md` (deck, grading, exam plan) and verify the documented grading rules match the implementation

## 10. Agent tools and integration

- [x] 10.1 Add agent tools `create_page`, `update_page_body`, `append_block`, `link_pages`, `search`, `create_database_view`, `add_review_card`, `grade_card`, `plan_exams` mirroring existing tool shapes, and verify tool-schema tests
- [x] 10.2 Update the agent system prompt to cover pages, links, databases, and review, and verify a chat run uses the new tools against a seeded vault
- [x] 10.3 Run the full test suite (`flutter test`) and `flutter analyze`, and verify zero failures and zero analyzer warnings
- [x] 10.4 Run an end-to-end integration check on Windows: launch, create page, add blocks, link, search, database view, review card, exam plan, quick capture, theme switch, and verify every spec scenario exercised passes
