# Palette and search

## Open

- **Ctrl/Cmd+K** — open command palette
- **Ctrl/Cmd+F** — open palette in search mode
- **Ctrl/Cmd+Shift+Space** — quick capture

## Commands

| Command | Keywords |
|---|---|
| New page | create page note |
| Search pages | find query |
| Toggle sidebar | collapse expand rail |
| Open board | views database |
| Open calendar | schedule |
| Open chat | agent ask |
| Open memory | vault log |
| Open settings | prefs theme |
| Open graph | links network |
| Open daily note | today journal daily |
| Quick capture | inbox capture thought |
| Run sync | integrations refresh |

If no command matches the typed query, the palette falls back to **full-text search** over titles, bodies, tags, and properties (via `search.json` / `SearchIndex`). Selecting a hit opens that page.

## Quick capture

Creates a `type: capture` node immediately. If the agent is busy, the capture id is queued and filed when idle; otherwise the agent is asked to file it and report the landing location.
