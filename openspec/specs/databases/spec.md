# databases Specification

## Purpose
Replaces the six fixed board layouts with a Notion-style database engine: one collection of nodes rendered through configurable views (table, board, gallery, calendar, list) with properties, filters, sorts, and inline editing.

## Requirements

### Requirement: Database views over nodes
The system SHALL render the node collection through view layouts: table, board, gallery, calendar, and list, and SHALL let the user switch layouts for the same view without changing the underlying nodes.

#### Scenario: Switch layout
- **WHEN** the user changes a view from table to board
- **THEN** the same nodes render as board columns and no node data is modified

### Requirement: View properties
The system SHALL let the user choose which node fields (title, type, status, priority, due, tags, class, custom properties) appear as columns/cards in a view, and SHALL hide fields not selected.

#### Scenario: Add due column
- **WHEN** the user adds the `due` property to a table view
- **THEN** a due column appears showing each node's due date

### Requirement: Filters, sorts, grouping
The system SHALL support multiple filters (field, operator, value combined with AND), multiple sorts, and grouping by any field, applied in order, and SHALL show the resulting node count.

#### Scenario: Filter overdue assignments
- **WHEN** the user filters type equals `assignment` AND due before today AND status equals `active`
- **THEN** only overdue active assignments appear and the count updates

### Requirement: Inline editing
The system SHALL allow editing a node's title, status, priority, due, and tags directly from a view row/card, persisting the change immediately.

#### Scenario: Check off in table
- **WHEN** the user checks the status cell of a row in a table view
- **THEN** the node is marked done and the row updates without opening the page

### Requirement: Layout migration
The system SHALL migrate existing list, kanban, grid, calendar, focus, and timeline views into the database engine, preserving each view's name, filters, sorts, order, and pinned state.

#### Scenario: Existing view preserved
- **WHEN** the app launches after the change with views created before it
- **THEN** each old view renders through the database engine with its prior filters and order intact

### Requirement: AI-managed views
The system SHALL let the AI agent create, update, and delete database views with the same configuration surface the user has, and SHALL reflect those changes in the UI immediately.

#### Scenario: Agent reorganizes board
- **WHEN** the agent creates a new view "Deadlines this week"
- **THEN** the view appears in the board with its filters applied
