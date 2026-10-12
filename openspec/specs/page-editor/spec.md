# page-editor Specification

## Purpose
Provides the markdown-first page editor students type in: live preview, typed blocks, slash commands, drag reorder, wikilinks, and tags, replacing the single plain-text body field.

## Requirements

### Requirement: Markdown-first editing with live preview
The system SHALL edit page bodies as markdown, showing the raw markdown as the user types and rendering formatted output alongside, and SHALL save the body as markdown text.

#### Scenario: Type heading
- **WHEN** the user types `# Notes` at the start of a line
- **THEN** the preview renders it as a heading and the saved body contains the literal markdown

#### Scenario: Legacy body migration
- **WHEN** a node saved before this change has a plain-text body
- **THEN** its body is shown in the editor as markdown with the original text intact

### Requirement: Typed blocks
The system SHALL support these block types: paragraph, heading (levels 1-3), todo, toggle (collapsible), callout, code, quote, bulleted list, numbered list, table, divider, and image, and SHALL render each with its own styling.

#### Scenario: Toggle block
- **WHEN** the user adds a toggle block with content
- **THEN** the block shows a chevron that collapses and expands its children

#### Scenario: Todo block
- **WHEN** the user checks a todo block
- **THEN** the block is marked done and its markdown is saved with the checked state

### Requirement: Slash command menu
The system SHALL open a slash-command menu when the user types `/` on an empty line, listing block types and template actions, filtered by the text typed after the slash, and SHALL insert the chosen block.

#### Scenario: Insert table
- **WHEN** the user types `/tab` and picks Table
- **THEN** a table block is inserted at the cursor position

### Requirement: Drag-to-reorder blocks
The system SHALL let the user reorder blocks by dragging a block handle, and SHALL persist the new order.

#### Scenario: Move block down
- **WHEN** the user drags a block below another block and releases
- **THEN** the blocks swap order in the editor and in the saved body

### Requirement: Wikilink typing
The system SHALL autocomplete `[[` with page titles, insert the chosen page as a wikilink, and render the link as a clickable reference that opens that page.

#### Scenario: Link to existing page
- **WHEN** the user types `[[Calc` and picks "Calculus I"
- **THEN** the editor shows a link to Calculus I and clicking it opens that page

#### Scenario: Link to missing page
- **WHEN** the user types a wikilink to a title that does not exist
- **THEN** the link renders as unresolved and offers to create the page

### Requirement: Tag autocomplete
The system SHALL autocomplete `#` with existing tags and SHALL render tags as clickable chips that filter to that tag.

#### Scenario: Add existing tag
- **WHEN** the user types `#phys` and picks `physics`
- **THEN** the tag chip `#physics` is inserted in the body

### Requirement: Autosave
The system SHALL save the page body automatically within two seconds of the last edit, without a save button, and SHALL show a saved indicator.

#### Scenario: Edit then idle
- **WHEN** the user stops typing for two seconds
- **THEN** the page is persisted and the indicator shows "Saved"
