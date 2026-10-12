# graph-and-links Specification

## Purpose
Makes the vault linked like Obsidian: every `[[wikilink]]` resolves to a page, backlinks and unlinked mentions are surfaced, and a graph view shows how pages connect.

## Requirements

### Requirement: Link resolution
The system SHALL resolve every `[[wikilink]]` in a page body to a page by title, and SHALL maintain an index of outgoing and incoming links that is rebuilt whenever a page is saved.

#### Scenario: Save page with links
- **WHEN** a page is saved containing `[[Linear Algebra]]`
- **THEN** the index records an outgoing link to that page and the target page's incoming links include this page

#### Scenario: Rename linked page
- **WHEN** a linked page is renamed
- **THEN** all wikilinks pointing to the old title are updated to the new title

### Requirement: Backlinks panel
The system SHALL show, on each page, a panel of pages that link to it, grouped by the block containing the link, and clicking a backlink opens the linking page at that block.

#### Scenario: Open backlink
- **WHEN** the user clicks a backlink entry
- **THEN** the linking page opens scrolled to the block containing the link

### Requirement: Forward links panel
The system SHALL show, on each page, a panel of pages it links to, and clicking an entry opens that page.

#### Scenario: Open forward link
- **WHEN** the user clicks a forward-link entry
- **THEN** the linked page opens

### Requirement: Unlinked mentions
The system SHALL detect plain-text occurrences of other page titles that are not wikilinks, list them on the page, and offer to convert each into a wikilink.

#### Scenario: Convert mention
- **WHEN** the user accepts conversion of an unlinked mention
- **THEN** the text is replaced with a wikilink and the link index updates

### Requirement: Graph view
The system SHALL render a graph of pages and nodes with edges for links, color-coded by node type, support pan/zoom, node selection that opens the page, and a filter by node type, tag, and link direction.

#### Scenario: Select graph node
- **WHEN** the user clicks a node in the graph
- **THEN** that page opens in the editor

#### Scenario: Filter graph
- **WHEN** the user filters the graph to type `assignment`
- **THEN** only assignment nodes and their edges are drawn

### Requirement: Node link parity
The system SHALL keep the existing node `links` field in sync with wikilinks, so a link created by the AI agent appears as a wikilink-capable reference and a wikilink typed by the user appears in the node's links.

#### Scenario: Agent creates link
- **WHEN** the agent links node A to node B
- **THEN** page A shows B in its forward-links panel and B shows A in its backlinks panel
