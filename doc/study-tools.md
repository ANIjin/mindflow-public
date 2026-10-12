# Study tools

## Review deck

Cards are built from:

- assignment pages
- notes tagged `review` / `flash`
- todo checkbox lines in page bodies

`dueTodayCount` counts nodes whose `review.due` is today or overdue.

## Grading

| Grade | Effect |
|---|---|
| again | reps→0, lapses+1, ease−0.2, due in 10 minutes |
| hard | reps+1, interval×1.2, ease−0.15, due in `interval` days |
| good | reps+1, interval×ease, due in `interval` days |
| easy | reps+1, ease+0.15, interval×ease×1.3, due in `interval` days |

Ease is clamped to `[1.3, 3.0]`. Interval days are clamped to `[1, 365]` after first reviews.

## Exam plan

`planExamStudy(examDate, days: N)` returns N calendar days before the exam for study blocks. Changing the exam date and calling again recomputes the set.

## Sessions

`StudySession(date, duration, cardsReviewed)` feeds `weeklySummary`, which reports session count, minutes, and cards for the last 7 days.
