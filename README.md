<p align="center">
  <img src="docs/assets/mindflow-banner.svg" alt="MindFlow" width="100%"/>
</p>

<p align="center">
  <strong>Your notes, schedule, and study system — with an agent that lives in the vault.</strong><br/>
  Built locally. Private by default. Powered by open models on your own machine.
</p>

<p align="center">
  <a href="#how-it-works">How it works</a> ·
  <a href="#inspiration">Inspiration</a> ·
  <a href="#built-with-strata">Built with Strata</a> ·
  <a href="#quick-start">Quick start</a> ·
  <a href="#features">Features</a>
</p>

---

## What is MindFlow?

**MindFlow** is a Flutter desktop & mobile knowledge workspace for students and makers who want one place for:

- long-form **pages** (block editor, nested notes)
- **wikilinks**, backlinks, and a **graph** view
- **databases** (table / board / gallery / calendar / list)
- a **command palette**, full-text search, and quick capture
- **study tools** — spaced-repetition review and exam planning
- an **AI agent** that can create reminders, reorganize views, and write into your vault

Your data stays in a personal local vault (JSON + markdown mirrors). Optional passphrase sync keeps a laptop and phone aligned — no account, no user id.

---

## How it works

```text
┌─────────────┐     chat / tools      ┌──────────────────┐
│  MindFlow   │ ───────────────────► │  Local LLM API   │
│  (Flutter)  │ ◄─────────────────── │  e.g. Strata     │
└──────┬──────┘   OpenAI-compatible  └──────────────────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│  Personal vault                              │
│  nodes/  views/  vault/*.md  memory.md       │
│  chat.jsonl  links.json  search.json         │
└──────────────────────────────────────────────┘
       │
       ▼  optional
┌──────────────────┐
│  Sync server or  │  same passphrase on each device
│  local Wi‑Fi sync│
└──────────────────┘
```

1. **You write and organize** in a Notion-style shell — pages, databases, calendar, graph.
2. **The agent reads your vault** through tools (`list_nodes`, `search`, `create_page`, `schedule_reminder`, …) instead of guessing.
3. **A local model** (Strata, LM Studio, or any OpenAI-compatible endpoint) plans and acts. Nothing has to leave your machine.
4. **Saves hit disk immediately** — JSON is source of truth; markdown mirrors are generated for portability.

### The agent loop

Every chat turn injects the live local datetime, then the model may call tools for several rounds: inspect → act → summarize. Reminders, due dates, and “tomorrow” are grounded in your clock, not vibes.

### Sync (optional)

- **Passphrase vault sync** — run `tools/sync_server`, put the same URL + passphrase on each device, hit **Sync now**.
- **Direct device sync** — Wi‑Fi (and platform-specific Bluetooth/USB where available). See [doc/device-sync.md](doc/device-sync.md) and [doc/sync-feature.md](doc/sync-feature.md).

---

## Inspiration

MindFlow sits in the gap between three things students actually use:

| World | What we stole (lovingly) |
| --- | --- |
| **Notion** | Nested pages, block editing, polished databases, a calm shell |
| **Obsidian** | `[[wikilinks]]`, backlinks, graph, a vault you can hold on disk |
| **A real semester** | Assignments, class schedules, exam countdown, review cards |

The goal was never “another chatbot.” It was a **workspace that remembers**, where an agent can *do the chores* — capture a deadline, wire a reminder, open a study plan — while you keep ownership of the files.

---

## Built with Strata

MindFlow’s agent was developed and run against **[Strata](https://github.com/Niko1221/Strata)** — Niko’s open-source local inference stack that runs a large Qwen-class model on a normal PC, with an OpenAI-compatible API on localhost.

> Strata: [https://github.com/Niko1221/Strata](https://github.com/Niko1221/Strata)

That mattered for this project:

- **Privacy** — school notes and chat stay on your hardware.
- **Iteration speed** — no rate limits while shaping prompts, tools, and UI.
- **Honest local-first design** — MindFlow defaults to `http://127.0.0.1:8080/v1`, the same shape Strata exposes.

### Point MindFlow at Strata

1. Install and start Strata from its repo (Windows `START-HERE.bat` / Linux `./setup.sh`).
2. In MindFlow → **Settings**:
   - **Base URL:** `http://127.0.0.1:8080/v1`
   - **Model:** the model name Strata reports (or any label it accepts)
   - **API key:** leave blank for local
3. Open **Chat** and ask it to capture something due this week.

Any other OpenAI-compatible server (LM Studio, Ollama proxies, etc.) works the same way.

---

## Features

- **Pages & blocks** — headings, lists, todos, callouts; nested under spaces
- **Links & graph** — wikilinks, backlinks, unlinked mentions, graph view
- **Databases** — filtered / sorted views over your nodes
- **Command palette & search** — jump anywhere; full-text with snippets
- **Study loop** — review deck + exam planner tied to notes and assignments
- **Calendar & schedule** — weekly classes, due dates, ICS import
- **Integrations (optional)** — Blackboard, Aktiv, Outlook, ntfy phone pushes
- **Cross-device sync** — passphrase server and/or local Wi‑Fi pairing
- **Windows · Linux · Web · iOS** targets via Flutter

---

## Quick start

### Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) (stable; see `pubspec.yaml` for SDK constraint)
- Optional: [Strata](https://github.com/Niko1221/Strata) or another local OpenAI-compatible model server

### Run

```bash
git clone https://github.com/ANIjin/mindflow-public.git
cd mindflow-public
flutter pub get
flutter run -d windows   # or linux / macos / chrome / ios
```

### Windows release build

```bash
flutter config --enable-windows-desktop
flutter pub get
flutter build windows --release
# build\windows\x64\runner\Release\mindflow.exe
```

### Device sync server

```bash
cd tools/sync_server
dart pub get
dart run bin/server.dart
# http://0.0.0.0:8787
```

Then **Settings → Device sync**: same URL + passphrase on each device → **Sync now**.

More: [doc/device-sync.md](doc/device-sync.md) · [doc/ios-sideload.md](doc/ios-sideload.md) · [doc/page-editor.md](doc/page-editor.md)

---

## Project layout

```text
lib/
  app_state.dart          # app bootstrap, chat, settings, sync hooks
  core/ai/                # agent, tools, OpenAI-compatible client
  core/memory/            # vault, search, links, databases, study
  core/sync/              # passphrase sync + direct device sync
  core/integrations/      # Blackboard, Outlook, Aktiv, ntfy
  ui/                     # shell, editor, graph, calendar, settings
tools/sync_server/        # tiny personal vault sync server
doc/                      # feature guides
test/                     # unit + widget tests
```

---

## Tests

```bash
flutter test
flutter analyze
```

---

## Credits

- **MindFlow** — designed and built as a local-first student workspace.
- **[Strata](https://github.com/Niko1221/Strata)** by **Niko** — the local LLM stack used to develop and drive the agent ([Niko1221/Strata](https://github.com/Niko1221/Strata)).
- UI ideas borrowed from the best of Notion and Obsidian; implementation is original Flutter.

---

## License

This public release is provided as source for learning and personal use. Check the repository license file for terms. Third-party packages and any local model weights keep their own licenses (Strata / Qwen / etc.).
