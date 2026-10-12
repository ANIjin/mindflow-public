# Proposal

## Why

MindFlow today is a capable AI-powered student productivity app, but its UI is a flat five-tab board of node cards, and its content model is a single plain-text `body` per node. Students who live in Notion (nested pages, databases, polished design) and Obsidian (markdown vault, backlinks, graph, daily notes) cannot do the same work here: there is no page editor, no linked knowledge base, no database views beyond six fixed layouts, no command palette, no search, and no study loop (spaced repetition, class pages, exam planning). This change rebuilds the app around a linked, markdown-first knowledge base with Notion-grade databases and design, while keeping the existing AI agent, schedule, notifications, and integrations.

## What Changes

- Replace the five-tab shell with a Notion-style workspace: collapsible sidebar page tree (spaces, favorites, recents), multi-pane content area, command palette (Ctrl/Cmd+K), and a dark-first design system with a purple accent (light theme available).
- Add a markdown-first page editor for node bodies: live preview, markdown blocks (headings, todo, toggle, callout, code, quote, lists, tables), slash-command menu, drag-to-reorder blocks, `[[wikilinks]]` that resolve to node ids, and `#tag` autocomplete.
- Add a link layer: backlinks panel per page, forward-links panel, graph view of the vault, unlinked-mention detection, and a link index rebuilt on every save.
- Add database views over nodes: table, board, gallery, calendar, and list, with per-view properties, filters, sorts, grouping, and inline editing. Existing list/kanban/grid/calendar/focus/timeline layouts migrate into this database engine.
- Add knowledge-base primitives: nested pages (parent/child), templates, daily notes, class pages auto-generated from the schedule, favorites, and page metadata (icon, cover, properties).
- Add study tools: spaced-repetition review deck built from notes/assignments, exam planner (countdown + study plan), and note-to-assignment linking.
- Add global full-text search and quick capture (a single keystroke to capture a thought that the agent files into the right page).
- Extend the AI agent tools to operate on pages, blocks, links, databases, and review decks.
- **BREAKING**: node `body` becomes markdown with block structure; existing plain-text bodies are auto-migrated. Board page layout is replaced by the workspace + database views; the old tab bar is removed.

## Capabilities

### New Capabilities

- `design-system`: theme tokens, light/dark modes, typography, spacing, motion, and the responsive workspace shell (sidebar + panes) shared by every screen.
- `knowledge-base`: spaces, nested page tree, sidebar navigation, templates, daily notes, class pages, favorites/recents, page metadata.
- `page-editor`: markdown-first editor with blocks, live preview, slash menu, drag reorder, wikilinks, and tag autocomplete.
- `graph-and-links`: link resolution to node ids, backlinks/forward-links panels, unlinked mentions, graph view, and the link index.
- `databases`: database views (table/board/gallery/calendar/list) over nodes with properties, filters, sorts, grouping, and inline editing.
- `command-palette`: command palette, global full-text search, and quick capture.
- `study-tools`: spaced-repetition review deck, exam planner, and note-to-assignment linking.

### Modified Capabilities

None — the project has no existing specs; all behavior above is introduced as new capabilities.

## Impact

- `lib/ui/`: new workspace shell (`app_shell.dart`), page editor, database views, graph view, sidebar tree, command palette, search, study screens; `theme.dart` becomes a token-based light/dark system.
- `lib/core/models/node.dart`: markdown body, block list, parent/child, properties, icon/cover, review state; `view_def.dart` gains database-view config (columns, filters, sorts).
- `lib/core/memory/memory_store.dart`: vault layout (markdown mirror files), link index, full-text index, templates, daily notes.
- `lib/core/ai/tools.dart`: new agent tools for pages, blocks, links, databases, review decks.
- `pubspec.yaml`: new dependencies (markdown rendering, syntax highlighting, graph canvas, search) — chosen in design.
- Existing integrations (Blackboard/Outlook/aktiv), schedule, notifications, and chat are preserved and wired into the new shell.
