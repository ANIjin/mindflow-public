# knowledge-base Specification

## Purpose
Gives students a linked knowledge base: spaces, nested pages, templates, daily notes, and class pages, navigated from a persistent sidebar, on top of the existing node store.

## Requirements

### Requirement: Spaces and nested page tree
The system SHALL organize pages into spaces, and each page SHALL support parent/child nesting to any depth, with the tree persisted in the store.

#### Scenario: Create child page
- **WHEN** the user creates a page inside an existing page
- **THEN** the new page appears nested under its parent in the sidebar tree and opens as a page node in the store

#### Scenario: Deep nesting
- **WHEN** a page has children of children
- **THEN** the sidebar renders the full indentation and each level can be expanded or collapsed

### Requirement: Sidebar navigation
The system SHALL show a sidebar containing spaces, the page tree, favorites, and recently opened pages, and SHALL keep the currently open page highlighted.

#### Scenario: Favorites
- **WHEN** the user marks a page as favorite
- **THEN** it appears in the favorites section of the sidebar and opens on click

#### Scenario: Recents
- **WHEN** the user opens a page
- **THEN** that page appears at the top of the recents list, and the list is capped at the most recent 10 pages

### Requirement: Templates
The system SHALL provide page templates (blank, class notes, assignment brief, weekly plan, meeting notes) and SHALL create a new page pre-filled from the chosen template.

#### Scenario: New page from template
- **WHEN** the user creates a page from the "class notes" template
- **THEN** the page opens with the template's headings and prompts already present and editable

### Requirement: Daily notes
The system SHALL provide a daily note for each date, created on first access, linked into the sidebar, and SHALL surface the day's due items and classes inside it.

#### Scenario: Open today's daily note
- **WHEN** the user opens the daily note for today
- **THEN** the note is created if absent, and lists today's classes and any node due today

### Requirement: Class pages
The system SHALL generate one class page per entry in the user's schedule, named for the class, and SHALL list that class's assignments, notes, and links on the page.

#### Scenario: Schedule entry added
- **WHEN** the user adds a class to the schedule
- **THEN** a class page for it appears in the sidebar and its page lists assignments tagged to that class

### Requirement: Page metadata
The system SHALL let the user set a page icon, cover, and custom properties (text, select, date, checkbox), and SHALL display them on the page header.

#### Scenario: Set page icon
- **WHEN** the user picks an icon for a page
- **THEN** the icon shows in the page header and in the sidebar entry for that page

### Requirement: Page operations
The system SHALL support renaming, moving (re-parenting), duplicating, and deleting a page; deleting a page with children SHALL ask the user to confirm and SHALL move children to the parent.

#### Scenario: Delete page with children
- **WHEN** the user deletes a page that has children
- **THEN** the app asks for confirmation and, on confirm, the children are re-parented to the deleted page's parent
