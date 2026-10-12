class ViewDef {
  String id;
  String name;
  String layout;
  List<String> types;
  List<String> tags;
  String? status;
  int? dueWithinDays;
  String sort;
  bool ascending;
  String groupBy;
  int order;
  bool pinned;
  Map<String, dynamic> style;
  List<String> columns;
  List<Map<String, dynamic>> filters;
  int? limit;

  ViewDef({
    required this.id,
    this.name = 'View',
    this.layout = 'list',
    List<String>? types,
    List<String>? tags,
    this.status,
    this.dueWithinDays,
    this.sort = 'due',
    this.ascending = true,
    this.groupBy = 'none',
    this.order = 0,
    this.pinned = false,
    Map<String, dynamic>? style,
    List<String>? columns,
    List<Map<String, dynamic>>? filters,
    this.limit,
  })  : types = types ?? [],
        tags = tags ?? [],
        style = style ?? {},
        columns = columns ?? [],
        filters = filters ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'layout': layout,
        'types': types,
        'tags': tags,
        'status': status,
        'due_within_days': dueWithinDays,
        'sort': sort,
        'ascending': ascending,
        'group_by': groupBy,
        'order': order,
        'pinned': pinned,
        'style': style,
        'columns': columns,
        'filters': filters,
        'limit': limit,
      };

  factory ViewDef.fromJson(Map<String, dynamic> j) => ViewDef(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'View',
        layout: j['layout'] as String? ?? 'list',
        types: (j['types'] as List?)?.map((e) => e as String).toList(),
        tags: (j['tags'] as List?)?.map((e) => e as String).toList(),
        status: j['status'] as String?,
        dueWithinDays: j['due_within_days'] as int?,
        sort: j['sort'] as String? ?? 'due',
        ascending: j['ascending'] as bool? ?? true,
        groupBy: j['group_by'] as String? ?? 'none',
        order: j['order'] as int? ?? 0,
        pinned: j['pinned'] as bool? ?? false,
        style: (j['style'] as Map?)?.cast<String, dynamic>(),
        columns: (j['columns'] as List?)?.map((e) => e as String).toList(),
        filters: (j['filters'] as List?)
            ?.map((e) => (e as Map).cast<String, dynamic>())
            .toList(),
        limit: j['limit'] as int?,
      );

  String toSummary() =>
      '[$id] "$name" layout=$layout types=${types.join(',')} tags=${tags.join(',')} '
      'status=${status ?? 'any'} dueWithin=${dueWithinDays ?? 'any'} '
      'sort=$sort(${ascending ? 'asc' : 'desc'}) group=$groupBy order=$order pinned=$pinned';
}
