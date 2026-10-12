import 'package:http/http.dart' as http;

import '../memory/memory_store.dart';
import 'connector.dart';
import 'feed_item.dart';

class AktivConnector extends Connector {
  final MemoryStore store;
  AktivConnector(this.store);

  @override
  String get id => 'aktiv';
  @override
  String get label => 'Aktiv (chemistry)';

  @override
  Map<String, dynamic> get cfg => integrationCfg(store, 'aktiv');

  @override
  bool get enabled =>
      cfg['enabled'] == true &&
      (cfg['loginUrl'] as String? ?? '').toString().isNotEmpty &&
      (cfg['username'] as String? ?? '').toString().isNotEmpty;

  @override
  Future<List<FeedItem>> fetch() async {
    final loginUrl = (cfg['loginUrl'] as String? ?? '').trim();
    final userField = (cfg['userField'] as String? ?? 'login').trim();
    final passField = (cfg['passField'] as String? ?? 'password').trim();
    final scrapeUrl =
        ((cfg['scrapeUrl'] as String? ?? '').trim().isEmpty
            ? loginUrl
            : (cfg['scrapeUrl'] as String).trim());

    final r = await http.post(
      Uri.parse(loginUrl),
      body: {
        userField: '${cfg['username'] ?? ''}',
        passField: '${cfg['password'] ?? ''}',
      },
    ).timeout(const Duration(seconds: 30));
    if (r.statusCode >= 400) {
      throw Exception('aktiv login failed (${r.statusCode})');
    }
    final cookies = (r.headers['set-cookie'] ?? '').split(';').first;
    final page = await http.get(
      Uri.parse(scrapeUrl),
      headers: {'Cookie': cookies},
    ).timeout(const Duration(seconds: 30));
    if (page.statusCode >= 400) {
      throw Exception('aktiv fetch failed (${page.statusCode})');
    }
    final html = page.body;
    final pattern = (cfg['itemRegex'] as String? ?? '').trim().isEmpty
        ? RegExp(r'<a[^>]*href="([^"]+)"[^>]*>([^<]{4,160})</a>')
        : RegExp(cfg['itemRegex'] as String);
    final seen = <String>{};
    final items = <FeedItem>[];
    for (final m in pattern.allMatches(html)) {
      final href = m.group(1) ?? '';
      final title = (m.group(2) ?? '').trim();
      if (href.isEmpty || title.isEmpty || seen.contains(href)) continue;
      seen.add(href);
      final low = title.toLowerCase();
      final kind = (low.contains('zadanie') ||
              low.contains('assignment') ||
              low.contains('hw') ||
              low.contains('quiz') ||
              low.contains('test') ||
              low.contains('lab'))
          ? 'assignment'
          : 'note';
      items.add(FeedItem(
        source: 'aktiv',
        extId: href,
        kind: kind,
        title: title,
        body: 'Aktiv: $href',
        link: href.startsWith('http') ? href : '',
      ));
    }
    return items;
  }
}
