import '../models/node.dart';
import '../models/view_def.dart';

class DatabaseResult {
  final List<MindNode> nodes;
  final Map<String, List<MindNode>> groups;
  final int count;
  const DatabaseResult({
    required this.nodes,
    required this.groups,
    required this.count,
  });
}

dynamic _fieldValue(MindNode n, String field) {
  switch (field) {
    case 'title':
      return n.title;
    case 'type':
      return n.type;
    case 'status':
      return n.status;
    case 'priority':
      return n.priority;
    case 'due':
      return n.due;
    case 'tags':
      return n.tags;
    case 'updated':
      return n.updated;
    case 'created':
      return n.created;
    default:
      return n.properties[field] ?? n.meta[field];
  }
}

bool _matchFilter(MindNode n, Map<String, dynamic> f) {
  final field = f['field'] as String? ?? '';
  final op = f['op'] as String? ?? 'eq';
  final value = f['value'];
  final actual = _fieldValue(n, field);

  switch (op) {
    case 'eq':
      if (actual is List) return actual.contains(value);
      return '$actual' == '$value';
    case 'neq':
      return '$actual' != '$value';
    case 'contains':
      if (actual is List) {
        return actual.any((e) => '$e'.toLowerCase().contains('$value'.toLowerCase()));
      }
      return '$actual'.toLowerCase().contains('$value'.toLowerCase());
    case 'before':
      if (actual is! DateTime || value == null) return false;
      final dt = value is DateTime ? value : DateTime.tryParse('$value');
      return dt != null && actual.isBefore(dt);
    case 'after':
      if (actual is! DateTime || value == null) return false;
      final dt = value is DateTime ? value : DateTime.tryParse('$value');
      return dt != null && actual.isAfter(dt);
    default:
      return true;
  }
}

int _compare(MindNode a, MindNode b, String sort, bool ascending) {
  int cmp;
  switch (sort) {
    case 'priority':
      cmp = a.priority.compareTo(b.priority);
    case 'updated':
      cmp = a.updated.compareTo(b.updated);
    case 'created':
      cmp = a.created.compareTo(b.created);
    case 'title':
      cmp = a.title.compareTo(b.title);
    case 'status':
      cmp = a.status.compareTo(b.status);
    case 'type':
      cmp = a.type.compareTo(b.type);
    case 'due':
    default:
      if (a.due == null && b.due == null) {
        cmp = 0;
      } else if (a.due == null) {
        cmp = 1;
      } else if (b.due == null) {
        cmp = -1;
      } else {
        cmp = a.due!.compareTo(b.due!);
      }
  }
  return ascending ? cmp : -cmp;
}

/// Applies ViewDef filters (AND), sorts, grouping, and limit.
DatabaseResult queryDatabase(Iterable<MindNode> source, ViewDef view) {
  var list = source.where((n) {
    // Legacy single-field filters still honored.
    if (view.types.isNotEmpty && !view.types.contains(n.type)) return false;
    if (view.status != null && n.status != view.status) return false;
    if (view.tags.isNotEmpty && !view.tags.any((t) => n.tags.contains(t))) {
      return false;
    }
    if (view.dueWithinDays != null) {
      if (n.due == null) return false;
      final limit = DateTime.now().add(Duration(days: view.dueWithinDays!));
      if (n.due!.isAfter(limit)) return false;
    }
    for (final f in view.filters) {
      if (!_matchFilter(n, f)) return false;
    }
    return true;
  }).toList();

  list.sort((a, b) => _compare(a, b, view.sort, view.ascending));

  if (view.limit != null && view.limit! > 0 && list.length > view.limit!) {
    list = list.take(view.limit!).toList();
  }

  final groups = <String, List<MindNode>>{};
  if (view.groupBy != 'none' && view.groupBy.isNotEmpty) {
    for (final n in list) {
      final key = '${_fieldValue(n, view.groupBy) ?? 'none'}';
      groups.putIfAbsent(key, () => []).add(n);
    }
  } else {
    groups['all'] = list;
  }

  return DatabaseResult(nodes: list, groups: groups, count: list.length);
}

List<String> visibleColumns(ViewDef view) {
  if (view.columns.isNotEmpty) return view.columns;
  return const ['title', 'status', 'priority', 'due', 'tags'];
}
