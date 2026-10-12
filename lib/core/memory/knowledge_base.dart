import 'package:uuid/uuid.dart';

import '../models/node.dart';
import '../scheduler/schedule.dart';

class PageTemplate {
  final String id;
  final String name;
  final String body;
  const PageTemplate(this.id, this.name, this.body);
}

const pageTemplates = <PageTemplate>[
  PageTemplate('blank', 'Blank', ''),
  PageTemplate(
      'class-notes',
      'Class notes',
      '# Class notes\n\n## Agenda\n\n## Notes\n\n## Action items\n\n- [ ] \n'),
  PageTemplate(
      'assignment',
      'Assignment brief',
      '# Assignment\n\n**Due:**\n\n## Prompt\n\n## Checklist\n\n- [ ] Read prompt\n- [ ] Draft\n- [ ] Submit\n'),
  PageTemplate(
      'weekly',
      'Weekly plan',
      '# Weekly plan\n\n## Goals\n\n## Schedule\n\n## Review\n'),
  PageTemplate(
      'meeting',
      'Meeting notes',
      '# Meeting\n\n**Attendees:**\n\n## Notes\n\n## Decisions\n\n## Follow-ups\n\n- [ ] \n'),
];

MindNode pageFromTemplate(PageTemplate t,
    {String? parentId, String? spaceId, String? title}) {
  return MindNode(
    id: const Uuid().v4(),
    title: title ?? t.name,
    type: 'page',
    body: t.body,
    parentId: parentId,
    spaceId: spaceId ?? 'MindFlow',
  );
}

MindNode createChildPage(MindNode parent, {String title = 'Untitled'}) {
  return MindNode(
    id: const Uuid().v4(),
    title: title,
    type: 'page',
    parentId: parent.id,
    spaceId: parent.spaceId,
  );
}

MindNode duplicatePage(MindNode source) {
  return MindNode(
    id: const Uuid().v4(),
    title: '${source.title} (copy)',
    type: source.type,
    body: source.body,
    parentId: source.parentId,
    spaceId: source.spaceId,
    tags: List.of(source.tags),
    properties: Map.of(source.properties),
    icon: source.icon,
    cover: source.cover,
  );
}

/// Re-parent children of [deleted] to [deleted.parentId].
List<MindNode> reparentChildren(
    Iterable<MindNode> all, MindNode deleted) {
  final out = <MindNode>[];
  for (final n in all) {
    if (n.parentId == deleted.id) {
      n.parentId = deleted.parentId;
      out.add(n);
    }
  }
  return out;
}

String dailyNoteTitle([DateTime? date]) {
  final d = date ?? DateTime.now();
  return 'Daily ${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

MindNode dailyNoteBody(DateTime day,
    {List<String> classes = const [], List<MindNode> due = const []}) {
  final title = dailyNoteTitle(day);
  final classLines =
      classes.isEmpty ? '- None' : classes.map((c) => '- $c').join('\n');
  final dueLines = due.isEmpty
      ? '- None'
      : due.map((n) => '- [ ] [[${n.title}]]').join('\n');
  return MindNode(
    id: const Uuid().v4(),
    title: title,
    type: 'daily',
    spaceId: 'Daily',
    body: '# $title\n\n## Classes\n$classLines\n\n## Due today\n$dueLines\n',
  );
}

/// Assignments tagged or property-linked to [className].
List<MindNode> assignmentsForClass(
    Iterable<MindNode> nodes, String className) {
  final key = className.trim().toLowerCase();
  return nodes.where((n) {
    if (n.type != 'assignment') return false;
    final prop = (n.properties['class'] ?? n.properties['className'] ?? '')
        .toString()
        .toLowerCase();
    if (prop == key) return true;
    return n.tags.any((t) => t.toLowerCase() == key);
  }).toList();
}

MindNode? findClassPage(Iterable<MindNode> nodes, String scheduleId) {
  for (final n in nodes) {
    if (n.type == 'class' &&
        (n.properties['scheduleId']?.toString() == scheduleId)) {
      return n;
    }
  }
  return null;
}

String classPageBody(ClassSlot slot, List<MindNode> assignments) {
  final assignLines = assignments.isEmpty
      ? '- None yet'
      : assignments.map((a) => '- [[${a.title}]]').join('\n');
  final loc = slot.location.isEmpty ? 'TBD' : slot.location;
  return '# ${slot.name}\n\n'
      '**Schedule:** weekday ${slot.weekday} '
      '${slot.startLabel}–${slot.endLabel}\n'
      '**Location:** $loc\n\n'
      '## Assignments\n$assignLines\n\n'
      '## Notes\n\n'
      '## Links\n\n';
}

/// Create or refresh the class page for a schedule slot.
MindNode ensureClassPage(
  Iterable<MindNode> existing,
  ClassSlot slot, {
  List<MindNode>? assignments,
}) {
  final assigns =
      assignments ?? assignmentsForClass(existing, slot.name);
  final found = findClassPage(existing, slot.id);
  if (found != null) {
    found.title = slot.name;
    found.body = classPageBody(slot, assigns);
    found.spaceId = 'Classes';
    found.properties['scheduleId'] = slot.id;
    found.properties['weekday'] = slot.weekday;
    found.properties['location'] = slot.location;
    found.updated = DateTime.now();
    return found;
  }
  return MindNode(
    id: const Uuid().v4(),
    title: slot.name,
    type: 'class',
    spaceId: 'Classes',
    icon: '📚',
    body: classPageBody(slot, assigns),
    properties: {
      'scheduleId': slot.id,
      'weekday': slot.weekday,
      'location': slot.location,
    },
  );
}
