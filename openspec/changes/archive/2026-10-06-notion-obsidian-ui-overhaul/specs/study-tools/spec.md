# Spec Delta

## Purpose

Turns the vault into a study system: spaced-repetition review built from notes and assignments, an exam planner that sequences study work, and explicit links between notes and the assignments they support.

## ADDED Requirements

### Requirement: Review deck from the vault
The system SHALL build a review deck from cards derived from todo blocks, tagged notes, and assignment pages, each card carrying a spaced-repetition state (due date, interval, ease), and SHALL show the deck with the count of cards due today.

#### Scenario: Deck counts due cards
- **WHEN** the user opens the review deck on a day with 5 cards due
- **THEN** the deck shows 5 due cards and the next due date for the rest

#### Scenario: New note becomes a card
- **WHEN** the user marks a note block as a review card
- **THEN** the card enters the deck with an initial state due the next day

### Requirement: Review session
The system SHALL present one due card at a time showing the card content, accept a self-grade (again/hard/good/easy), update the card's interval per the grade, schedule its next due date, and continue until no cards are due.

#### Scenario: Grade good
- **WHEN** the user grades a due card as "good"
- **THEN** the card's interval increases and its next due date moves later

#### Scenario: Grade again
- **WHEN** the user grades a card as "again"
- **THEN** the card returns to the same session shortly with a shortened interval

### Requirement: Exam planner
The system SHALL let the user register exams with date and weight, show a countdown, and generate a study plan that schedules review sessions and assignment work into the days before each exam, surfacing the plan on the calendar and in the daily note.

#### Scenario: Exam added
- **WHEN** the user registers an exam two weeks out
- **THEN** a countdown appears and study blocks are scheduled on days before the exam

#### Scenario: Exam date moved
- **WHEN** the user changes an exam date
- **THEN** the countdown and the generated study plan are recomputed

### Requirement: Note-to-assignment linking
The system SHALL let the user link a note page to an assignment node, show that link on both pages, and count linked notes as study coverage for the assignment.

#### Scenario: Link note to assignment
- **WHEN** the user links a note page to an assignment
- **THEN** the assignment page lists the note and the note shows the assignment in its links

### Requirement: Study session tracking
The system SHALL record completed review sessions and study blocks with date and duration, and show a weekly study summary (cards reviewed, minutes studied, assignments touched).

#### Scenario: Weekly summary
- **WHEN** the user completes 3 review sessions this week
- **THEN** the weekly summary shows cards reviewed per day and total minutes
