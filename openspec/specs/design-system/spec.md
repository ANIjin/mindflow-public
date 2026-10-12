# design-system Specification

## Purpose
Defines the shared visual language and responsive application shell that every MindFlow screen is built on, so the app looks and behaves coherently across desktop and mobile.

## Requirements

### Requirement: Dark-first themes with purple accent
The system SHALL default to a dark theme with a purple accent, SHALL provide a light theme built from the same design tokens, and SHALL let the user choose light, dark, or follow-system, persisting the choice across launches.

#### Scenario: First launch
- **WHEN** the app launches with no saved theme choice
- **THEN** every screen renders in dark with the purple accent

#### Scenario: Theme switch
- **WHEN** the user selects dark mode in settings
- **THEN** every screen renders with dark tokens immediately and the choice is restored on the next launch

#### Scenario: Follow system
- **WHEN** the user selects "follow system" and the OS switches to light mode
- **THEN** the app re-renders with light tokens without a restart

### Requirement: Shared design tokens
The system SHALL define tokens for color, spacing, radius, typography scale, elevation, and motion duration, and every UI component SHALL consume tokens rather than hard-coded values.

#### Scenario: Token-only styling
- **WHEN** a new screen is added to the app
- **THEN** its colors, spacing, and type sizes come from the token set, and changing a token updates that screen

### Requirement: Responsive workspace shell
The system SHALL present a workspace shell: on wide screens (≥700px) a collapsible sidebar plus one or more content panes; on narrow screens a stacked layout with a single pane and a collapsible navigation drawer.

#### Scenario: Desktop layout
- **WHEN** the window is at least 700px wide
- **THEN** the sidebar and content pane are visible simultaneously and the sidebar can be collapsed to an icon rail

#### Scenario: Mobile layout
- **WHEN** the window is narrower than 700px
- **THEN** only one pane is visible and navigation opens as a drawer over the content

### Requirement: Keyboard-first desktop interaction
The system SHALL support keyboard shortcuts for core actions (open palette, new page, search, toggle sidebar, focus editor) and SHALL show visible focus indicators on all interactive elements when navigating by keyboard.

#### Scenario: Shortcut opens palette
- **WHEN** the user presses Ctrl+K (Cmd+K on macOS) on desktop
- **THEN** the command palette opens without any mouse interaction

### Requirement: Consistent motion
The system SHALL animate view changes, panel opens, and item insertions with durations and easing drawn from the motion tokens, and SHALL respect the OS reduced-motion preference by disabling non-essential animation.

#### Scenario: Reduced motion
- **WHEN** the OS reports reduced-motion preference
- **THEN** transitions between views are instant and no looping animations run
