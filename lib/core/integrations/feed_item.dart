class FeedItem {
  final String source;
  final String extId;
  final String kind;
  final String title;
  final String body;
  final DateTime? due;
  final DateTime? start;
  final DateTime? end;
  final String link;

  FeedItem({
    required this.source,
    required this.extId,
    this.kind = 'note',
    this.title = '',
    this.body = '',
    this.due,
    this.start,
    this.end,
    this.link = '',
  });
}
