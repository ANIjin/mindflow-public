import 'dart:convert';

class ReviewState {
  DateTime? due;
  double interval;
  double ease;
  int reps;
  int lapses;

  ReviewState({
    this.due,
    this.interval = 0,
    this.ease = 2.5,
    this.reps = 0,
    this.lapses = 0,
  });

  Map<String, dynamic> toJson() => {
        'due': due?.toIso8601String(),
        'interval': interval,
        'ease': ease,
        'reps': reps,
        'lapses': lapses,
      };

  factory ReviewState.fromJson(Map<String, dynamic> j) => ReviewState(
        due: j['due'] != null ? DateTime.parse(j['due'] as String) : null,
        interval: (j['interval'] as num?)?.toDouble() ?? 0,
        ease: (j['ease'] as num?)?.toDouble() ?? 2.5,
        reps: j['reps'] as int? ?? 0,
        lapses: j['lapses'] as int? ?? 0,
      );
}

class MindNode {
  String id;
  String type;
  String title;
  String body;
  DateTime? due;
  List<DateTime> reminders;
  int priority;
  String status;
  List<String> tags;
  List<String> links;
  Map<String, dynamic> meta;
  Map<String, dynamic> style;
  DateTime created;
  DateTime updated;
  String source;
  String? parentId;
  String? spaceId;
  Map<String, dynamic> properties;
  String? icon;
  String? cover;
  ReviewState? review;

  MindNode({
    required this.id,
    this.type = 'task',
    this.title = '',
    this.body = '',
    this.due,
    List<DateTime>? reminders,
    this.priority = 1,
    this.status = 'active',
    List<String>? tags,
    List<String>? links,
    Map<String, dynamic>? meta,
    Map<String, dynamic>? style,
    DateTime? created,
    DateTime? updated,
    this.source = 'user',
    this.parentId,
    this.spaceId,
    Map<String, dynamic>? properties,
    this.icon,
    this.cover,
    this.review,
  })  : reminders = reminders ?? [],
        tags = tags ?? [],
        links = links ?? [],
        meta = meta ?? {},
        style = style ?? {},
        properties = properties ?? {},
        created = created ?? DateTime.now(),
        updated = updated ?? DateTime.now();

  bool get isOverdue =>
      due != null && due!.isBefore(DateTime.now()) && status == 'active';

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'due': due?.toIso8601String(),
        'reminders': reminders.map((d) => d.toIso8601String()).toList(),
        'priority': priority,
        'status': status,
        'tags': tags,
        'links': links,
        'meta': meta,
        'style': style,
        'created': created.toIso8601String(),
        'updated': updated.toIso8601String(),
        'source': source,
        'parentId': parentId,
        'spaceId': spaceId,
        'properties': properties,
        'icon': icon,
        'cover': cover,
        'review': review?.toJson(),
      };

  factory MindNode.fromJson(Map<String, dynamic> j) => MindNode(
        id: j['id'] as String,
        type: j['type'] as String? ?? 'task',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        due: j['due'] != null ? DateTime.parse(j['due'] as String) : null,
        reminders: (j['reminders'] as List?)
                ?.map((e) => DateTime.parse(e as String))
                .toList() ??
            [],
        priority: j['priority'] as int? ?? 1,
        status: j['status'] as String? ?? 'active',
        tags: (j['tags'] as List?)?.map((e) => e as String).toList() ?? [],
        links: (j['links'] as List?)?.map((e) => e as String).toList() ?? [],
        meta: (j['meta'] as Map?)?.cast<String, dynamic>() ?? {},
        style: (j['style'] as Map?)?.cast<String, dynamic>() ?? {},
        created: j['created'] != null
            ? DateTime.parse(j['created'] as String)
            : null,
        updated: j['updated'] != null
            ? DateTime.parse(j['updated'] as String)
            : null,
        source: j['source'] as String? ?? 'user',
        parentId: j['parentId'] as String?,
        spaceId: j['spaceId'] as String?,
        properties:
            (j['properties'] as Map?)?.cast<String, dynamic>() ?? {},
        icon: j['icon'] as String?,
        cover: j['cover'] as String?,
        review: j['review'] != null
            ? ReviewState.fromJson(
                (j['review'] as Map).cast<String, dynamic>())
            : null,
      );

  String toSummary() {
    final parts = [type, 'status=$status', 'priority=$priority'];
    if (due != null) parts.add('due=${due!.toIso8601String()}');
    if (reminders.isNotEmpty) {
      parts.add('reminders=${reminders.map((d) => d.toIso8601String()).join(',')}');
    }
    if (tags.isNotEmpty) parts.add('tags=${tags.join(',')}');
    if (links.isNotEmpty) parts.add('links=${links.join(',')}');
    if (meta.isNotEmpty) parts.add('meta=${jsonEncode(meta)}');
    return '[$id] "$title" | ${parts.join(' | ')}';
  }
}
