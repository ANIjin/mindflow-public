import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../memory/memory_store.dart';
import 'connector.dart';
import 'feed_item.dart';

class OutlookConnector extends Connector {
  final MemoryStore store;
  OutlookConnector(this.store);

  @override
  String get id => 'outlook';
  @override
  String get label => 'Outlook (school)';

  @override
  Map<String, dynamic> get cfg => integrationCfg(store, 'outlook');

  @override
  bool get enabled => cfg['enabled'] == true;

  String get clientId =>
      (cfg['clientId'] as String? ?? '14d82eec-204b-4c2f-b7e8-296a70d99351')
          .trim();

  Map<String, dynamic> get _tokens =>
      (cfg['tokens'] as Map?)?.cast<String, dynamic>() ?? {};

  bool get signedIn => (_tokens['access_token'] as String?)?.isNotEmpty == true;

  Future<String> startSignIn() async {
    final r = await http.post(
      Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/deviceflow'),
      body: {'client_id': clientId, 'scope': 'Calendars.Read Mail.Read'},
    ).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) {
      throw Exception('device flow failed (${r.statusCode}) ${r.body}');
    }
    final j = (jsonDecode(r.body) as Map).cast<String, dynamic>();
    final t = Map<String, dynamic>.from(cfg);
    t['device_code'] = j['device_code'];
    t['interval'] = j['interval'];
    t['expires_in'] = j['expires_in'];
    t['verification_uri'] = j['verification_uri'];
    final all = Map<String, dynamic>.from(
        (store.settings['integrations'] as Map?)?.cast<String, dynamic>() ?? {});
    all['outlook'] = t;
    store.settings['integrations'] = all;
    await store.saveSettings();
    return j['user_code'] as String? ?? '';
  }

  Future<bool> pollSignIn() async {
    final t = cfg;
    final code = t['device_code'] as String? ?? '';
    if (code.isEmpty) return false;
    final interval = (t['interval'] as int?) ?? 5;
    final deadline = DateTime.now().add(
        Duration(seconds: (t['expires_in'] as int?) ?? 900));
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(Duration(seconds: interval));
      final r = await http.post(
        Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token'),
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          'client_id': clientId,
          'device_code': code,
        },
      ).timeout(const Duration(seconds: 30));
      final j = (jsonDecode(r.body) as Map).cast<String, dynamic>();
      if (j['access_token'] != null) {
        await _saveTokens(j);
        return true;
      }
      final err = j['error'] as String? ?? '';
      if (err == 'authorization_pending') continue;
      if (err == 'slow_down') {
        await Future.delayed(Duration(seconds: interval));
        continue;
      }
      return false;
    }
    return false;
  }

  Future<void> _saveTokens(Map<String, dynamic> j) async {
    final all = Map<String, dynamic>.from(
        (store.settings['integrations'] as Map?)?.cast<String, dynamic>() ?? {});
    final oc = Map<String, dynamic>.from(all['outlook'] as Map? ?? {});
    oc['tokens'] = {
      'access_token': j['access_token'],
      'refresh_token': j['refresh_token'],
      'expires': DateTime.now()
          .add(Duration(seconds: j['expires_in'] as int? ?? 3600))
          .toIso8601String(),
    };
    all['outlook'] = oc;
    store.settings['integrations'] = all;
    await store.saveSettings();
  }

  Future<String> _validToken() async {
    var t = _tokens;
    final exp = DateTime.tryParse(t['expires'] as String? ?? '');
    if (t['access_token'] == null) throw Exception('not signed in');
    if (exp != null && exp.isAfter(DateTime.now())) {
      return t['access_token'] as String;
    }
    final r = await http.post(
      Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token'),
      body: {
        'grant_type': 'refresh_token',
        'client_id': clientId,
        'scope': 'Calendars.Read Mail.Read',
        'refresh_token': t['refresh_token'] ?? '',
      },
    ).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) {
      throw Exception('token refresh failed (${r.statusCode}) - sign in again');
    }
    final j = (jsonDecode(r.body) as Map).cast<String, dynamic>();
    await _saveTokens(j);
    return j['access_token'] as String;
  }

  Future<List<Map<String, dynamic>>> _graph(String url, String token) async {
    final r = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) {
      throw Exception('graph error ${r.statusCode} on $url');
    }
    final j = (jsonDecode(r.body) as Map).cast<String, dynamic>();
    return ((j['value'] as List?) ?? [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  @override
  Future<List<FeedItem>> fetch() async {
    final token = await _validToken();
    final items = <FeedItem>[];
    final start = DateTime.now().subtract(const Duration(days: 7));
    final end = DateTime.now().add(const Duration(days: 30));
    final events = await _graph(
      'https://graph.microsoft.com/v1.0/me/calendar/events'
      '?start=${start.toIso8601String()}&end=${end.toIso8601String()}'
      '&limit=50&\$orderby=start/date&\$select=id,subject,start,end,bodyPreview,webLink,isAllDay',
      token,
    );
    for (final e in events) {
      final s = (e['start'] as Map?)?['dateTime'] as String?;
      final en = (e['end'] as Map?)?['dateTime'] as String?;
      final preview = e['bodyPreview'] as String? ?? '';
      items.add(FeedItem(
        source: 'outlook',
        extId: '${e['id']}',
        kind: 'event',
        title: e['subject'] as String? ?? '(event)',
        body: preview.substring(0, preview.length.clamp(0, 300)),
        start: s != null ? DateTime.parse(s).toLocal() : null,
        end: en != null ? DateTime.parse(en).toLocal() : null,
        link: e['webLink'] as String? ?? '',
      ));
    }
    if (cfg['fetchMail'] == true) {
      final mail = await _graph(
        'https://graph.microsoft.com/v1.0/me/messages'
        '?\$top=15&\$orderby=receivedDateTime desc'
        '&\$select=id,subject,bodyPreview,receivedDateTime,webLink',
        token,
      );
      for (final m in mail) {
        final preview = m['bodyPreview'] as String? ?? '';
        items.add(FeedItem(
          source: 'outlook',
          extId: '${m['id']}',
          kind: 'note',
          title: m['subject'] as String? ?? '(mail)',
          body: preview.substring(0, preview.length.clamp(0, 300)),
          due: DateTime.tryParse(m['receivedDateTime'] as String? ?? '')
              ?.toLocal(),
          link: m['webLink'] as String? ?? '',
        ));
      }
    }
    return items;
  }
}
