# Spec Delta

## Purpose

Puts a keyboard-driven entry point in front of the whole app: a command palette, global full-text search, and quick capture, so students never have to hunt through menus.

## ADDED Requirements

### Requirement: Command palette
The system SHALL open a command palette on Ctrl+K (Cmd+K on macOS) listing commands (new page, open page, toggle theme, open daily note, run sync, ask the agent), fuzzy-matching the typed query, and executing the selected command.

#### Scenario: Run command
- **WHEN** the user opens the palette, types "daily", and selects "Open daily note"
- **THEN** today's daily note opens

#### Scenario: No matches
- **WHEN** the typed query matches no command
- **THEN** the palette shows a "no results" state and offers a search over page content

### Requirement: Global full-text search
The system SHALL search page titles, bodies, tags, and properties across the whole vault, rank results by relevance, show matching snippets, and open the selected page at the matching block.

#### Scenario: Search finds body text
- **WHEN** the user searches for a phrase that appears inside a page body
- **THEN** that page is listed with a snippet highlighting the phrase and selecting it opens the page at that block

#### Scenario: Search respects deletions
- **WHEN** a page is deleted
- **THEN** it no longer appears in search results

### Requirement: Quick capture
The system SHALL provide a quick-capture field (global shortcut) that accepts a single line of text, saves it as a captured note, and asks the agent to file it into the appropriate page, class, and view, reporting where it was filed.

#### Scenario: Capture a thought
- **WHEN** the user captures "quiz ch. 4 Friday" via quick capture
- **THEN** a note is created and the agent files it as an assignment linked to the matching class page, and the app shows where it landed

#### Scenario: Capture while agent busy
- **WHEN** the user captures text while the agent is working
- **THEN** the capture is saved immediately and queued for filing when the agent is free
