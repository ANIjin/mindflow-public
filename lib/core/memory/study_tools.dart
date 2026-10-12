import '../models/node.dart';

class ReviewCard {
  final String nodeId;
  final String prompt;
  final String source;
  ReviewCard(
      {required this.nodeId, required this.prompt, required this.source});
}

enum ReviewGrade { again, hard, good, easy }

List<ReviewCard> buildReviewDeck(Iterable<MindNode> nodes) {
  final cards = <ReviewCard>[];
  for (final n in nodes) {
    if (n.type == 'assignment') {
      cards.add(ReviewCard(
          nodeId: n.id, prompt: n.title, source: 'assignment'));
    }
    for (final tag in n.tags) {
      if (tag.toLowerCase().contains('review') ||
          tag.toLowerCase().contains('flash')) {
        cards.add(ReviewCard(
            nodeId: n.id, prompt: n.title, source: 'tag:$tag'));
      }
    }
    for (final line in n.body.split('\n')) {
      final m = RegExp(r'^- \[[ xX]\] (.+)$').firstMatch(line.trim());
      if (m != null) {
        cards.add(ReviewCard(
            nodeId: n.id, prompt: m.group(1)!, source: 'todo'));
      }
    }
  }
  return cards;
}

int dueTodayCount(Iterable<MindNode> nodes, [DateTime? now]) {
  final today = now ?? DateTime.now();
  var count = 0;
  for (final n in nodes) {
    final r = n.review;
    if (r?.due == null) continue;
    final d = r!.due!;
    if (d.year == today.year && d.month == today.month && d.day == today.day) {
      count++;
    } else if (d.isBefore(DateTime(today.year, today.month, today.day))) {
      count++;
    }
  }
  return count;
}

void applyGrade(MindNode node, ReviewGrade grade, [DateTime? now]) {
  final at = now ?? DateTime.now();
  final review = node.review ?? ReviewState();
  switch (grade) {
    case ReviewGrade.again:
      review.reps = 0;
      review.lapses += 1;
      review.interval = 0;
      review.ease = (review.ease - 0.2).clamp(1.3, 3.0);
      review.due = at.add(const Duration(minutes: 10));
    case ReviewGrade.hard:
      review.reps += 1;
      review.interval = review.interval < 1 ? 1 : review.interval * 1.2;
      review.ease = (review.ease - 0.15).clamp(1.3, 3.0);
      review.due = at.add(Duration(days: review.interval.round().clamp(1, 365)));
    case ReviewGrade.good:
      review.reps += 1;
      review.interval = review.interval < 1 ? 1 : review.interval * review.ease;
      review.due = at.add(Duration(days: review.interval.round().clamp(1, 365)));
    case ReviewGrade.easy:
      review.reps += 1;
      review.ease = (review.ease + 0.15).clamp(1.3, 3.0);
      review.interval =
          review.interval < 1 ? 2 : review.interval * review.ease * 1.3;
      review.due = at.add(Duration(days: review.interval.round().clamp(1, 365)));
  }
  node.review = review;
}

class StudySession {
  final DateTime date;
  final Duration duration;
  final int cardsReviewed;
  StudySession(
      {required this.date,
      required this.duration,
      required this.cardsReviewed});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'durationMinutes': duration.inMinutes,
        'cardsReviewed': cardsReviewed,
      };
}

String weeklySummary(List<StudySession> sessions, [DateTime? now]) {
  final today = now ?? DateTime.now();
  final weekAgo = today.subtract(const Duration(days: 7));
  final recent =
      sessions.where((s) => s.date.isAfter(weekAgo)).toList();
  final minutes =
      recent.fold<int>(0, (a, s) => a + s.duration.inMinutes);
  final cards =
      recent.fold<int>(0, (a, s) => a + s.cardsReviewed);
  return 'This week: ${recent.length} sessions, $minutes min, $cards cards.';
}

List<DateTime> planExamStudy(DateTime examDate, {int days = 7}) {
  final blocks = <DateTime>[];
  for (var i = days; i >= 1; i--) {
    blocks.add(DateTime(examDate.year, examDate.month, examDate.day)
        .subtract(Duration(days: i)));
  }
  return blocks;
}

List<String> _idList(dynamic raw) {
  if (raw is List) {
    return raw.map((e) => e.toString()).toList();
  }
  return <String>[];
}

/// Bidirectional note ↔ assignment link with coverage tracking.
void linkNoteToAssignment(MindNode note, MindNode assignment) {
  final noteAssignments = _idList(note.properties['assignments']);
  if (!noteAssignments.contains(assignment.id)) {
    noteAssignments.add(assignment.id);
  }
  note.properties['assignments'] = noteAssignments;

  final assignmentNotes = _idList(assignment.properties['notes']);
  if (!assignmentNotes.contains(note.id)) {
    assignmentNotes.add(note.id);
  }
  assignment.properties['notes'] = assignmentNotes;

  if (!note.links.contains(assignment.id)) note.links.add(assignment.id);
  if (!assignment.links.contains(note.id)) assignment.links.add(note.id);

  if (!note.body.contains('[[${assignment.title}]]')) {
    final section = note.body.contains('## Assignments')
        ? note.body
        : '${note.body.trimRight()}\n\n## Assignments\n';
    note.body = section.contains('[[${assignment.title}]]')
        ? section
        : '$section\n- [[${assignment.title}]]\n';
  }
  if (!assignment.body.contains('[[${note.title}]]')) {
    final section = assignment.body.contains('## Study notes')
        ? assignment.body
        : '${assignment.body.trimRight()}\n\n## Study notes\n';
    assignment.body = section.contains('[[${note.title}]]')
        ? section
        : '$section\n- [[${note.title}]]\n';
  }
}

/// Count of notes linked as study coverage for an assignment.
int assignmentCoverage(MindNode assignment) =>
    _idList(assignment.properties['notes']).length;

List<String> linkedAssignmentIds(MindNode note) =>
    _idList(note.properties['assignments']);

List<String> linkedNoteIds(MindNode assignment) =>
    _idList(assignment.properties['notes']);
