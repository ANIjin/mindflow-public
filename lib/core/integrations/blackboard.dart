import 'dart:convert';

import 'package:http/http.dart' as http;

import '../memory/memory_store.dart';
import 'connector.dart';
import 'feed_item.dart';

class BlackboardConnector extends Connector {
  final MemoryStore store;
  BlackboardConnector(this.store);

  @override
  String get id => 'blackboard';
  @override
  String get label => 'Blackboard';

  @override
  Map<String, dynamic> get cfg => integrationCfg(store, 'blackboard');

  @override
  bool get enabled =>
      cfg['enabled'] == true &&
      (cfg['baseUrl'] as String? ?? '').toString().isNotEmpty &&
      (cfg['clientId'] as String? ?? '').toString().isNotEmpty;

  String get _base =>
      (cfg['baseUrl'] as String? ?? '').trim();

  String get _basic => base64Encode(
      utf8.encode('${cfg['clientId'] ?? ''}:${cfg['clientSecret'] ?? ''}'));

  Map<String, dynamic> get _tokens =>
      (cfg['tokens'] as Map?)?.cast<String, dynamic>() ?? {};

  bool get signedIn => (_tokens['access_token'] as String?)?.isNotEmpty == true;

  Future<String> requestAuthCode() async {
    final user = Uri.encodeComponent('${cfg['username'] ?? ''}');
    final r = await http.post(
      Uri.parse('$_base/learn/api/public/v1/oauth2/authorizationcode'
          '?userId=$user&scope=user,POST,GET,DELETE'),
      headers: {'Authorization': 'Basic $_basic'},
    ).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) {
      throw Exception('code request failed (${r.statusCode}) ${r.body}');
    }
    final j = (jsonDecode(r.body) as Map).cast<String, dynamic>();
    return '${j['code'] ?? ''}';
  }

  Future<bool> exchangeCode(String code) async {
    final r = await http.post(
      Uri.parse('$_base/learn/api/public/v1/oauth2/token'
          '?grant_type=authorization_code'
          '&code=${Uri.encodeComponent(code)}&redirect_uri='),
      headers: {'Authorization': 'Basic $_basic'},
    ).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) {
      throw Exception('code exchange failed (${r.statusCode}) ${r.body}');
    }
    final j = (jsonDecode(r.body) as Map).cast<String, dynamic>();
    await _saveTokens(j);
    return true;
  }

  Future<void> _saveTokens(Map<String, dynamic> j) async {
    final all = Map<String, dynamic>.from(
        (store.settings['integrations'] as Map?)?.cast<String, dynamic>() ??
            {});
    final bc = Map<String, dynamic>.from(all['blackboard'] as Map? ?? {});
    bc['tokens'] = {
      'access_token': j['access_token'],
      'refresh_token': j['refresh_token'],
      'expires': DateTime.now()
          .add(Duration(seconds: j['expires_in'] as int? ?? 3600))
          .toIso8601String(),
    };
    all['blackboard'] = bc;
    store.settings['integrations'] = all;
    await store.saveSettings();
  }

  Future<String> _validToken() async {
    final t = _tokens;
    if (t['access_token'] == null) {
      throw Exception('not signed in - request a code and exchange it');
    }
    final exp = DateTime.tryParse(t['expires'] as String? ?? '');
    if (exp != null && exp.isAfter(DateTime.now())) {
      return t['access_token'] as String;
    }
    final r = await http.post(
      Uri.parse('$_base/learn/api/public/v1/oauth2/token'
          '?grant_type=refresh_token'
          '&refresh_token=${Uri.encodeComponent(t['refresh_token'] as String? ?? '')}'),
      headers: {'Authorization': 'Basic $_basic'},
    ).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) {
      throw Exception('token refresh failed (${r.statusCode}) - sign in again');
    }
    final j = (jsonDecode(r.body) as Map).cast<String, dynamic>();
    await _saveTokens(j);
    return j['access_token'] as String;
  }

  Future<Map<String, dynamic>> _get(String path, String token) async {
    final r = await http.get(
      Uri.parse('$_base$path'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) {
      throw Exception('blackboard API error ${r.statusCode} on $path');
    }
    return (jsonDecode(r.body) as Map).cast<String, dynamic>();
  }

  @override
  Future<List<FeedItem>> fetch() async {
    final token = await _validToken();
    final items = <FeedItem>[];
    final courses = await _get(
        '/learn/api/public/v1/users/me/courses?limit=50', token);
    for (final c in (courses['children'] as List?) ?? []) {
      final cm = (c as Map).cast<String, dynamic>();
      final cid = (cm['id'] as String? ?? '');
      final cname = cm['name'] as String? ?? '';
      try {
        final contents = await _get(
            '/learn/api/public/v1/courses/$cid/contents?limit=100', token);
        for (final e in (contents['children'] as List?) ?? []) {
          final em = (e as Map).cast<String, dynamic>();
          final title = em['title'] as String? ?? '';
          if (title.isEmpty) continue;
          final low = title.toLowerCase();
          final kind = (low.contains('assignment') ||
                  low.contains('quiz') ||
                  low.contains('lab') ||
                  low.contains('homework') ||
                  low.contains('exam'))
              ? 'assignment'
              : 'note';
          items.add(FeedItem(
            source: 'blackboard',
            extId: '${em['id']}',
            kind: kind,
            title: title,
            body: 'Course: $cname',
            link: '$_base/webapps/blackboard/execute/content'
                '?course_id=$cid&content_id=${em['id']}',
          ));
        }
      } catch (_) {}
    }
    return items;
  }
}
