import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../integrations/connector.dart';
import '../integrations/phone.dart';
import '../memory/knowledge_base.dart';
import '../memory/memory_store.dart';
import '../memory/study_tools.dart';
import '../models/node.dart';
import '../models/view_def.dart';
import '../scheduler/notifications.dart';
import '../scheduler/schedule.dart';

const _uuid = Uuid();

DateTime? _dt(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

List<String> _strs(dynamic v) =>
    (v as List?)?.map((e) => e.toString()).toList() ?? [];

List<DateTime> _dts(dynamic v) =>
    (v as List?)?.map((e) => DateTime.parse(e.toString())).toList() ?? [];

final List<Map<String, dynamic>> toolSchemas = [
  _fn('list_nodes', 'List nodes with optional filters. Returns compact summaries.', {
    'type': 'object',
    'properties': {
      'type': {'type': 'string'},
      'status': {'type': 'string'},
      'tag': {'type': 'string'},
      'text': {'type': 'string', 'description': 'substring match in title/body'},
      'limit': {'type': 'integer'},
    },
  }),
  _fn('create_node', 'Create a MindNode. ISO-8601 local datetimes for due/reminders.', {
    'type': 'object',
    'properties': {
      'type': {'type': 'string', 'description': 'assignment|obligation|goal|task|project|note|habit|event or new type'},
      'title': {'type': 'string'},
      'body': {'type': 'string'},
      'due': {'type': 'string', 'description': 'ISO-8601'},
      'reminders': {'type': 'array', 'items': {'type': 'string'}, 'description': 'ISO-8601 datetimes'},
      'priority': {'type': 'integer', 'description': '0 low, 1 normal, 2 high, 3 urgent'},
      'tags': {'type': 'array', 'items': {'type': 'string'}},
      'links': {'type': 'array', 'items': {'type': 'string'}, 'description': 'node ids'},
      'meta': {'type': 'object'},
      'style': {'type': 'object'},
    },
    'required': ['type', 'title'],
  }),
  _fn('update_node', 'Update fields of a node (partial).', {
    'type': 'object',
    'properties': {
      'id': {'type': 'string'},
      'title': {'type': 'string'},
      'body': {'type': 'string'},
      'due': {'type': 'string'},
      'priority': {'type': 'integer'},
      'status': {'type': 'string', 'description': 'active|done|blocked|dropped'},
      'tags': {'type': 'array', 'items': {'type': 'string'}},
      'links': {'type': 'array', 'items': {'type': 'string'}},
      'meta': {'type': 'object'},
      'style': {'type': 'object'},
      'add_reminders': {'type': 'array', 'items': {'type': 'string'}},
      'remove_reminders': {'type': 'array', 'items': {'type': 'string'}},
    },
    'required': ['id'],
  }),
  _fn('delete_node', 'Delete a node by id.', {
    'type': 'object',
    'properties': {'id': {'type': 'string'}},
    'required': ['id'],
  }),
  _fn('complete_node', 'Mark a node done.', {
    'type': 'object',
    'properties': {'id': {'type': 'string'}},
    'required': ['id'],
  }),
  _fn('link_nodes', 'Link two nodes (relationship).', {
    'type': 'object',
    'properties': {'a': {'type': 'string'}, 'b': {'type': 'string'}},
    'required': ['a', 'b'],
  }),
  _fn('schedule_reminder', 'Add a notification reminder to a node.', {
    'type': 'object',
    'properties': {
      'node_id': {'type': 'string'},
      'when': {'type': 'string', 'description': 'ISO-8601 local datetime'},
    },
    'required': ['node_id', 'when'],
  }),
  _fn('create_view', 'Create a UI view the user sees on their board.', {
    'type': 'object',
    'properties': {
      'name': {'type': 'string'},
      'layout': {'type': 'string', 'description': 'list|kanban|grid|calendar|focus|timeline'},
      'types': {'type': 'array', 'items': {'type': 'string'}},
      'tags': {'type': 'array', 'items': {'type': 'string'}},
      'status': {'type': 'string'},
      'due_within_days': {'type': 'integer'},
      'sort': {'type': 'string', 'description': 'due|priority|updated|created|title'},
      'ascending': {'type': 'boolean'},
      'group_by': {'type': 'string', 'description': 'none|type|tag|priority|status'},
      'order': {'type': 'integer'},
      'pinned': {'type': 'boolean'},
    },
    'required': ['name', 'layout'],
  }),
  _fn('update_view', 'Update a view (partial).', {
    'type': 'object',
    'properties': {
      'id': {'type': 'string'},
      'name': {'type': 'string'},
      'layout': {'type': 'string'},
      'types': {'type': 'array', 'items': {'type': 'string'}},
      'tags': {'type': 'array', 'items': {'type': 'string'}},
      'status': {'type': 'string'},
      'due_within_days': {'type': 'integer'},
      'sort': {'type': 'string'},
      'ascending': {'type': 'boolean'},
      'group_by': {'type': 'string'},
      'order': {'type': 'integer'},
      'pinned': {'type': 'boolean'},
    },
    'required': ['id'],
  }),
  _fn('delete_view', 'Delete a view by id.', {
    'type': 'object',
    'properties': {'id': {'type': 'string'}},
    'required': ['id'],
  }),
  _fn('list_views', 'List current views.', {
    'type': 'object',
    'properties': {},
  }),
  _fn('read_memory', 'Read long-term memory (memory.md).', {
    'type': 'object',
    'properties': {},
  }),
  _fn('write_memory', 'Append a dated entry to long-term memory.', {
    'type': 'object',
    'properties': {'entry': {'type': 'string'}},
    'required': ['entry'],
  }),
  _fn('read_log', 'Read recent event log entries.', {
    'type': 'object',
    'properties': {'n': {'type': 'integer'}},
  }),
  _fn('get_summary', 'Counts of nodes by type/status, overdue items, upcoming due dates.', {
    'type': 'object',
    'properties': {},
  }),
  _fn('sync_integrations',
      'Sync enabled external sources (Blackboard, Aktiv, Outlook). '
      'Creates/updates nodes tagged with source blackboard|aktiv|outlook. Returns status per connector.',
      {'type': 'object', 'properties': {}}),
  _fn('list_schedule', 'List the user\'s weekly class schedule slots.', {
    'type': 'object',
    'properties': {},
  }),
  _fn('add_class', 'Add a weekly class schedule slot.', {
    'type': 'object',
    'properties': {
      'name': {'type': 'string'},
      'weekday': {'type': 'integer', 'description': '1=Mon .. 7=Sun'},
      'start': {'type': 'string', 'description': 'HH:mm'},
      'end': {'type': 'string', 'description': 'HH:mm'},
      'location': {'type': 'string'},
    },
    'required': ['name', 'weekday', 'start', 'end'],
  }),
  _fn('remove_class', 'Remove a class schedule slot by id.', {
    'type': 'object',
    'properties': {'id': {'type': 'string'}},
    'required': ['id'],
  }),
  _fn('import_ics', 'Import ICS calendar text into the weekly class schedule.', {
    'type': 'object',
    'properties': {'text': {'type': 'string'}},
    'required': ['text'],
  }),
  _fn('notify_phone',
      'Send a push notification to the user\'s phone via ntfy. Use for '
      'urgent alerts, quick updates, or messages the user asks to be sent '
      'to their phone. Requires phone notifications enabled in Settings.', {
    'type': 'object',
    'properties': {
      'title': {'type': 'string'},
      'body': {'type': 'string'},
      'when': {'type': 'string',
          'description': 'optional ISO-8601 local datetime for delayed delivery'},
      'priority': {'type': 'integer', 'description': '1..5, default 4'},
    },
    'required': ['title', 'body'],
  }),
  _fn('create_page', 'Create a knowledge-base page (optionally nested).', {
    'type': 'object',
    'properties': {
      'title': {'type': 'string'},
      'body': {'type': 'string'},
      'parent_id': {'type': 'string'},
      'space_id': {'type': 'string'},
      'icon': {'type': 'string'},
    },
    'required': ['title'],
  }),
  _fn('update_page_body', 'Replace a page body with markdown.', {
    'type': 'object',
    'properties': {
      'id': {'type': 'string'},
      'body': {'type': 'string'},
    },
    'required': ['id', 'body'],
  }),
  _fn('append_block', 'Append a markdown block to a page body.', {
    'type': 'object',
    'properties': {
      'id': {'type': 'string'},
      'markdown': {'type': 'string'},
    },
    'required': ['id', 'markdown'],
  }),
  _fn('link_pages', 'Link two pages by id (adds wikilink + links field).', {
    'type': 'object',
    'properties': {
      'from_id': {'type': 'string'},
      'to_id': {'type': 'string'},
    },
    'required': ['from_id', 'to_id'],
  }),
  _fn('search', 'Full-text search across the vault.', {
    'type': 'object',
    'properties': {
      'query': {'type': 'string'},
      'limit': {'type': 'integer'},
    },
    'required': ['query'],
  }),
  _fn('create_database_view', 'Create a database view over nodes.', {
    'type': 'object',
    'properties': {
      'name': {'type': 'string'},
      'layout': {'type': 'string'},
      'types': {'type': 'array', 'items': {'type': 'string'}},
      'filters': {'type': 'array', 'items': {'type': 'object'}},
      'columns': {'type': 'array', 'items': {'type': 'string'}},
      'sort': {'type': 'string'},
      'group_by': {'type': 'string'},
    },
    'required': ['name'],
  }),
  _fn('add_review_card', 'Ensure a page has review state and is in the deck.', {
    'type': 'object',
    'properties': {
      'id': {'type': 'string'},
      'due': {'type': 'string'},
    },
    'required': ['id'],
  }),
  _fn('grade_card', 'Grade a review card: again|hard|good|easy.', {
    'type': 'object',
    'properties': {
      'id': {'type': 'string'},
      'grade': {'type': 'string'},
    },
    'required': ['id', 'grade'],
  }),
  _fn('plan_exams', 'Plan study blocks for an exam date.', {
    'type': 'object',
    'properties': {
      'exam_date': {'type': 'string'},
      'days': {'type': 'integer'},
      'title': {'type': 'string'},
    },
    'required': ['exam_date'],
  }),
];

Map<String, dynamic> _fn(String name, String desc, Map<String, dynamic> params) =>
    {
      'type': 'function',
      'function': {'name': name, 'description': desc, 'parameters': params},
    };

class ToolExecutor {
  final MemoryStore store;
  final IntegrationManager? integrations;
  final ScheduleStore? schedule;
  final List<String> activities = [];

  ToolExecutor(this.store, [this.integrations, this.schedule]);

  Future<String> execute(String name, Map<String, dynamic> args) async {
    try {
      return await _run(name, args);
    } catch (e) {
      return 'ERROR: $e';
    }
  }

  Future<String> _run(String name, Map<String, dynamic> args) async {
    switch (name) {
      case 'list_nodes':
        final type = args['type'] as String?;
        final status = args['status'] as String?;
        final tag = args['tag'] as String?;
        final text = args['text'] as String?;
        final limit = args['limit'] as int? ?? 40;
        final matches = store.nodes.values.where((n) {
          if (type != null && n.type != type) return false;
          if (status != null && n.status != status) return false;
          if (tag != null && !n.tags.contains(tag)) return false;
          if (text != null &&
              !n.title.toLowerCase().contains(text.toLowerCase()) &&
              !n.body.toLowerCase().contains(text.toLowerCase())) {
            return false;
          }
          return true;
        }).take(limit);
        return matches.map((n) => n.toSummary()).join('\n');
      case 'create_node':
        final n = MindNode(
          id: _uuid.v4(),
          type: args['type'] as String? ?? 'task',
          title: args['title'] as String? ?? 'untitled',
          body: args['body'] as String? ?? '',
          due: _dt(args['due']),
          reminders: _dts(args['reminders']),
          priority: args['priority'] as int? ?? 1,
          tags: _strs(args['tags']),
          links: _strs(args['links']),
          meta: (args['meta'] as Map?)?.cast<String, dynamic>(),
          style: (args['style'] as Map?)?.cast<String, dynamic>(),
          source: 'ai',
        );
        await store.saveNode(n);
        await NotificationService.syncNode(n);
        activities.add('created ${n.type} node "${n.title}" (${n.id})');
        return 'created node ${n.id}';
      case 'update_node':
        final n = store.nodes[args['id']];
        if (n == null) return 'ERROR: node ${args['id']} not found';
        if (args['title'] != null) n.title = args['title'] as String;
        if (args['body'] != null) n.body = args['body'] as String;
        if (args.containsKey('due')) n.due = _dt(args['due']);
        if (args['priority'] != null) n.priority = args['priority'] as int;
        if (args['status'] != null) n.status = args['status'] as String;
        if (args['tags'] != null) n.tags = _strs(args['tags']);
        if (args['links'] != null) n.links = _strs(args['links']);
        if (args['meta'] != null) n.meta = (args['meta'] as Map).cast<String, dynamic>();
        if (args['style'] != null) n.style = (args['style'] as Map).cast<String, dynamic>();
        if (args['add_reminders'] != null) {
          n.reminders.addAll(_dts(args['add_reminders']));
          n.reminders.sort();
        }
        if (args['remove_reminders'] != null) {
          final rm = _dts(args['remove_reminders']);
          n.reminders.removeWhere((d) => rm.contains(d));
        }
        await store.saveNode(n);
        await NotificationService.syncNode(n);
        activities.add('updated node "${n.title}"');
        return 'updated node ${n.id}';
      case 'delete_node':
        await store.deleteNode(args['id'] as String);
        activities.add('deleted node ${args['id']}');
        return 'deleted';
      case 'complete_node':
        final n = store.nodes[args['id']];
        if (n == null) return 'ERROR: node not found';
        n.status = 'done';
        await store.saveNode(n);
        await NotificationService.syncNode(n);
        activities.add('completed "${n.title}"');
        return 'completed';
      case 'link_nodes':
        final a = store.nodes[args['a']], b = store.nodes[args['b']];
        if (a == null || b == null) return 'ERROR: node not found';
        if (!a.links.contains(b.id)) a.links.add(b.id);
        if (!b.links.contains(a.id)) b.links.add(a.id);
        await store.saveNode(a);
        await store.saveNode(b);
        activities.add('linked "${a.title}" <-> "${b.title}"');
        return 'linked';
      case 'schedule_reminder':
        final n = store.nodes[args['node_id']];
        if (n == null) return 'ERROR: node not found';
        final when = DateTime.parse(args['when'] as String);
        n.reminders.add(when);
        n.reminders.sort();
        await store.saveNode(n);
        await NotificationService.syncNode(n);
        activities.add('reminder for "${n.title}" at $when');
        return 'reminder scheduled at $when';
      case 'create_view':
        final v = ViewDef(
          id: _uuid.v4(),
          name: args['name'] as String? ?? 'View',
          layout: args['layout'] as String? ?? 'list',
          types: _strs(args['types']),
          tags: _strs(args['tags']),
          status: args['status'] as String?,
          dueWithinDays: args['due_within_days'] as int?,
          sort: args['sort'] as String? ?? 'due',
          ascending: args['ascending'] as bool? ?? true,
          groupBy: args['group_by'] as String? ?? 'none',
          order: args['order'] as int? ?? store.views.length,
          pinned: args['pinned'] as bool? ?? false,
        );
        await store.saveView(v);
        activities.add('created view "${v.name}" (${v.layout})');
        return 'created view ${v.id}';
      case 'update_view':
        final v = store.views[args['id']];
        if (v == null) return 'ERROR: view ${args['id']} not found';
        if (args['name'] != null) v.name = args['name'] as String;
        if (args['layout'] != null) v.layout = args['layout'] as String;
        if (args['types'] != null) v.types = _strs(args['types']);
        if (args['tags'] != null) v.tags = _strs(args['tags']);
        if (args.containsKey('status')) v.status = args['status'] as String?;
        if (args.containsKey('due_within_days')) {
          v.dueWithinDays = args['due_within_days'] as int?;
        }
        if (args['sort'] != null) v.sort = args['sort'] as String;
        if (args['ascending'] != null) v.ascending = args['ascending'] as bool;
        if (args['group_by'] != null) v.groupBy = args['group_by'] as String;
        if (args['order'] != null) v.order = args['order'] as int;
        if (args['pinned'] != null) v.pinned = args['pinned'] as bool;
        await store.saveView(v);
        activities.add('updated view "${v.name}"');
        return 'updated view ${v.id}';
      case 'delete_view':
        await store.deleteView(args['id'] as String);
        activities.add('deleted view ${args['id']}');
        return 'deleted';
      case 'list_views':
        return store.views.values
            .toList()
            .map((v) => v.toSummary())
            .join('\n');
      case 'read_memory':
        return await store.readMemory();
      case 'write_memory':
        await store.appendMemory(args['entry'] as String);
        activities.add('wrote to long-term memory');
        return 'memory updated';
      case 'read_log':
        final entries = await store.readLog(args['n'] as int? ?? 30);
        return entries.map((e) => '${e['ts']} ${e['event']} ${e['ref']} ${e['detail']}').join('\n');
      case 'get_summary':
        final byType = <String, int>{};
        final byStatus = <String, int>{};
        for (final n in store.nodes.values) {
          byType[n.type] = (byType[n.type] ?? 0) + 1;
          byStatus[n.status] = (byStatus[n.status] ?? 0) + 1;
        }
        final overdue = store.nodes.values.where((n) => n.isOverdue).map((n) => n.toSummary());
        final now = DateTime.now();
        final upcoming = store.activeNodes
            .where((n) => n.due != null && n.due!.isAfter(now) && n.due!.isBefore(now.add(const Duration(days: 7))))
            .toList()
          ..sort((a, b) => a.due!.compareTo(b.due!));
        return 'now=${now.toIso8601String()}\n'
            'byType=${jsonEncode(byType)}\nbyStatus=${jsonEncode(byStatus)}\n'
            'overdue:\n${overdue.join('\n')}\n'
            'upcoming7d:\n${upcoming.map((n) => n.toSummary()).join('\n')}';
      case 'sync_integrations':
        if (integrations == null) return 'ERROR: integrations unavailable';
        final c = await integrations!.sync();
        final st = integrations!.status.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
        activities.add('synced integrations ($c new items)');
        return 'sync complete, $c new nodes\n$st';
      case 'list_schedule':
        if (schedule == null) return 'ERROR: schedule unavailable';
        if (schedule!.slots.isEmpty) return '(empty schedule)';
        final s = schedule!.slots.toList()
          ..sort((a, b) =>
              a.weekday != b.weekday ? a.weekday.compareTo(b.weekday) : a.startMin.compareTo(b.startMin));
        return s.map((e) => e.toSummary()).join('\n');
      case 'add_class':
        if (schedule == null) return 'ERROR: schedule unavailable';
        final sm = _hm(args['start'] as String);
        final em = _hm(args['end'] as String);
        final slot = ClassSlot(
          id: _uuid.v4(),
          name: args['name'] as String? ?? 'class',
          weekday: args['weekday'] as int? ?? 1,
          startMin: sm,
          endMin: em,
          location: args['location'] as String? ?? '',
        );
        await schedule!.addSlot(slot);
        final classPage = ensureClassPage(store.nodes.values, slot);
        await store.saveNode(classPage);
        activities.add('added class "${slot.name}" day ${slot.weekday} ${slot.startLabel}-${slot.endLabel}');
        return 'added class ${slot.id} (page ${classPage.id})';
      case 'remove_class':
        if (schedule == null) return 'ERROR: schedule unavailable';
        await schedule!.removeSlot(args['id'] as String);
        activities.add('removed class ${args['id']}');
        return 'removed';
      case 'import_ics':
        if (schedule == null) return 'ERROR: schedule unavailable';
        final n = await schedule!.importIcs(args['text'] as String? ?? '');
        activities.add('imported $n schedule slots from ICS');
        return 'imported $n slots';
      case 'notify_phone':
        final r = await PhoneNotifier.send(
          args['title'] as String? ?? 'MindFlow',
          args['body'] as String? ?? '',
          delay: _dt(args['when']),
          priority: args['priority'] as int? ?? 4,
        );
        if (r == 'sent' || r.startsWith('phone push')) {
          activities.add('phone push "${args['title']}"');
        }
        return r;
      case 'create_page':
        final n = MindNode(
          id: _uuid.v4(),
          type: 'page',
          title: args['title'] as String? ?? 'Untitled',
          body: args['body'] as String? ?? '',
          parentId: args['parent_id'] as String?,
          spaceId: args['space_id'] as String? ?? 'MindFlow',
          icon: args['icon'] as String?,
        );
        await store.saveNode(n);
        activities.add('created page ${n.title}');
        return n.id;
      case 'update_page_body':
        final n = store.nodes[args['id']];
        if (n == null) return 'ERROR: missing page';
        n.body = args['body'] as String? ?? '';
        await store.saveNode(n);
        activities.add('updated page body ${n.id}');
        return 'ok';
      case 'append_block':
        final n = store.nodes[args['id']];
        if (n == null) return 'ERROR: missing page';
        final md = args['markdown'] as String? ?? '';
        n.body = n.body.trimEmptyAppend(md);
        await store.saveNode(n);
        activities.add('appended block to ${n.id}');
        return 'ok';
      case 'link_pages':
        final from = store.nodes[args['from_id']];
        final to = store.nodes[args['to_id']];
        if (from == null || to == null) return 'ERROR: missing page';
        if (!from.links.contains(to.id)) from.links.add(to.id);
        if (!from.body.contains('[[${to.title}]]')) {
          from.body = from.body.trimEmptyAppend('[[${to.title}]]');
        }
        await store.saveNode(from);
        activities.add('linked ${from.id} -> ${to.id}');
        return 'ok';
      case 'search':
        final q = args['query'] as String? ?? '';
        final limit = args['limit'] as int? ?? 20;
        final hits = store.searchIndex.search(q, store.nodes).take(limit);
        return hits
            .map((h) =>
                '${h.nodeId}\t${store.nodes[h.nodeId]?.title ?? ''}\t${h.snippet}')
            .join('\n');
      case 'create_database_view':
        final v = ViewDef(
          id: _uuid.v4(),
          name: args['name'] as String? ?? 'View',
          layout: args['layout'] as String? ?? 'table',
          types: _strs(args['types']),
          filters: (args['filters'] as List?)
                  ?.map((e) => (e as Map).cast<String, dynamic>())
                  .toList() ??
              [],
          columns: _strs(args['columns']),
          sort: args['sort'] as String? ?? 'due',
          groupBy: args['group_by'] as String? ?? 'none',
          order: store.views.length,
        );
        await store.saveView(v);
        activities.add('created view ${v.name}');
        return v.id;
      case 'add_review_card':
        final n = store.nodes[args['id']];
        if (n == null) return 'ERROR: missing page';
        n.review ??= ReviewState(due: _dt(args['due']) ?? DateTime.now());
        if (args['due'] != null) n.review!.due = _dt(args['due']);
        if (!n.tags.contains('review')) n.tags.add('review');
        await store.saveNode(n);
        activities.add('added review card ${n.id}');
        return 'ok';
      case 'grade_card':
        final n = store.nodes[args['id']];
        if (n == null) return 'ERROR: missing page';
        final g = switch ((args['grade'] as String? ?? 'good').toLowerCase()) {
          'again' => ReviewGrade.again,
          'hard' => ReviewGrade.hard,
          'easy' => ReviewGrade.easy,
          _ => ReviewGrade.good,
        };
        applyGrade(n, g);
        await store.saveNode(n);
        activities.add('graded ${n.id} $g');
        return jsonEncode(n.review?.toJson() ?? {});
      case 'plan_exams':
        final exam = _dt(args['exam_date']);
        if (exam == null) return 'ERROR: bad exam_date';
        final days = args['days'] as int? ?? 7;
        final title = args['title'] as String? ?? 'Exam';
        final blocks = planExamStudy(exam, days: days);
        final page = MindNode(
          id: _uuid.v4(),
          title: '$title study plan',
          type: 'exam-plan',
          body:
              '# $title\n\nExam: ${exam.toIso8601String().split('T').first}\n\n## Study blocks\n${blocks.map((d) => '- [ ] ${d.toIso8601String().split('T').first}').join('\n')}\n',
        );
        await store.saveNode(page);
        activities.add('planned exam $title');
        return page.id;
      default:
        return 'ERROR: unknown tool $name';
    }
  }
}

extension on String {
  String trimEmptyAppend(String md) {
    if (trim().isEmpty) return md;
    return '${trimRight()}\n\n$md';
  }
}

int _hm(String s) {
  final parts = s.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}
