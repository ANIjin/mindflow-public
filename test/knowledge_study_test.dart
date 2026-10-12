import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/memory/knowledge_base.dart';
import 'package:mindflow/core/memory/study_tools.dart';
import 'package:mindflow/core/models/node.dart';
import 'package:mindflow/core/scheduler/schedule.dart';

void main() {
  test('templates create pre-filled pages', () {
    final t = pageTemplates.firstWhere((e) => e.id == 'class-notes');
    final n = pageFromTemplate(t);
    expect(n.body.contains('## Agenda'), isTrue);
    expect(n.title, 'Class notes');
  });

  test('delete with children reparents', () {
    final parent = MindNode(id: 'p', title: 'Parent');
    final child = MindNode(id: 'c', title: 'Child', parentId: 'p');
    final moved = reparentChildren([parent, child], parent);
    expect(moved.single.parentId, isNull);
  });

  test('daily note includes due items', () {
    final due = MindNode(id: 'd', title: 'Essay', due: DateTime.now());
    final n = dailyNoteBody(DateTime(2026, 10, 5),
        classes: ['Calc'], due: [due]);
    expect(n.title, 'Daily 2026-10-05');
    expect(n.body.contains('Calc'), isTrue);
    expect(n.body.contains('[[Essay]]'), isTrue);
  });

  test('review deck and grading', () {
    final n = MindNode(
        id: 'a',
        title: 'HW',
        type: 'assignment',
        body: '- [ ] Derive limit\n');
    final deck = buildReviewDeck([n]);
    expect(deck.length, greaterThanOrEqualTo(2));
    applyGrade(n, ReviewGrade.good, DateTime(2026, 10, 5));
    expect(n.review?.reps, 1);
    expect(n.review?.due, isNotNull);
    applyGrade(n, ReviewGrade.again, DateTime(2026, 10, 5));
    expect(n.review!.lapses, 1);
  });

  test('exam planner schedules study blocks and recomputes', () {
    final exam = DateTime(2026, 10, 12);
    final plan = planExamStudy(exam, days: 5);
    expect(plan.length, 5);
    expect(plan.last.isBefore(exam), isTrue);
    final shifted = planExamStudy(exam.add(const Duration(days: 2)), days: 5);
    expect(shifted.last.day, exam.add(const Duration(days: 1)).day);
  });

  test('weekly summary aggregates sessions', () {
    final sessions = [
      StudySession(
          date: DateTime.now(),
          duration: const Duration(minutes: 25),
          cardsReviewed: 10),
      StudySession(
          date: DateTime.now().subtract(const Duration(days: 2)),
          duration: const Duration(minutes: 15),
          cardsReviewed: 5),
    ];
    expect(weeklySummary(sessions), contains('2 sessions'));
    expect(weeklySummary(sessions), contains('40 min'));
  });

  test('class page from schedule lists tagged assignments', () {
    final slot = ClassSlot(
        id: 'slot-1', name: 'Calculus', weekday: 1, startMin: 540, endMin: 630);
    final hw = MindNode(
        id: 'hw1',
        title: 'Problem set 3',
        type: 'assignment',
        tags: ['Calculus']);
    final page = ensureClassPage([hw], slot);
    expect(page.type, 'class');
    expect(page.spaceId, 'Classes');
    expect(page.title, 'Calculus');
    expect(page.body.contains('[[Problem set 3]]'), isTrue);
    expect(page.properties['scheduleId'], 'slot-1');

    final refreshed = ensureClassPage([page, hw], slot);
    expect(refreshed.id, page.id);
    expect(refreshed.body.contains('[[Problem set 3]]'), isTrue);
  });

  test('note-to-assignment linking shows on both with coverage', () {
    final note = MindNode(id: 'n1', title: 'Derivatives notes', type: 'page');
    final hw =
        MindNode(id: 'a1', title: 'Calc HW', type: 'assignment', body: '# HW');
    linkNoteToAssignment(note, hw);
    expect(linkedAssignmentIds(note), contains('a1'));
    expect(linkedNoteIds(hw), contains('n1'));
    expect(assignmentCoverage(hw), 1);
    expect(note.body.contains('[[Calc HW]]'), isTrue);
    expect(hw.body.contains('[[Derivatives notes]]'), isTrue);
  });
}
