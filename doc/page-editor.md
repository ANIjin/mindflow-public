# Page editor

MindFlow edits page bodies as markdown. The editor splits the body into typed blocks, autosaves, and shows a live preview.

## Block types

| Slash command | Block | Markdown form |
|---|---|---|
| `/heading` | Heading (H1) | `# title` |
| `/todo` | To-do | `- [ ] text` / `- [x] text` |
| `/toggle` | Toggle | `> [!toggle]` with nested lines |
| `/callout` | Callout | `> [!note] title` |
| `/code` | Code | fenced ` ```lang ` |
| `/quote` | Quote | `> line` |
| `/bulleted` | Bulleted list | `- item` |
| `/numbered` | Numbered list | `1. item` |
| `/tab` / `/table` | Table | pipe table |
| `/divider` | Divider | `---` |
| `/image` | Image | `![alt](url)` |
| `/paragraph` | Paragraph | plain text |

## Shortcuts

| Shortcut | Action |
|---|---|
| `/` on an empty block | Open slash-command menu (fuzzy filter) |
| `[[` | Wikilink autocomplete over page titles |
| `#` | Tag autocomplete over existing tags |
| Drag handle | Reorder blocks (order persisted on save) |
| Enter (on many blocks) | Insert a new paragraph below |
| Ctrl/Cmd+E | Focus the page editor (shell) |

## Autosave

Edits save automatically within **2 seconds** of the last change. The header shows `Saving…` then `Saved`.

## Markdown subset

The parser and preview share one block model (`parseBlocks` / `blocksToMarkdown`). Preview is rendered with `flutter_markdown` from that same markdown string. Legacy plain-text bodies open as a single paragraph block.
