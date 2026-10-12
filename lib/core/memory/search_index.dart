import 'dart:convert';

import '../models/blocks.dart';
import '../models/node.dart';

class SearchHit {
  final String nodeId;
  final int blockIndex;
  final int offset;
  final String snippet;
  final double score;

  SearchHit(
      {required this.nodeId,
      required this.blockIndex,
      required this.offset,
      required this.snippet,
      required this.score});
}

const _titleWeight = 3.0;
const _tagWeight = 2.0;
const _bodyWeight = 1.0;

List<String> _tokenize(String text) {
  return text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9_]+'))
      .where((t) => t.length > 1)
      .toList();
}

class SearchIndex {
  final index = <String, List<Map<String, dynamic>>>{};

  void indexNode(MindNode node) {
    unindexNode(node.id);
    final blocks = parseBlocks(node.body);
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final md = b.toMarkdown();
      final fields = [
        (b.text, 0),
        (b.items.join(' '), md.indexOf(b.items.join(' ')) >= 0 ? md.indexOf(b.items.join(' ')) : 0),
        (b.rows.map((r) => r.join(' ')).join(' '),
            md.indexOf(b.rows.map((r) => r.join(' ')).join(' ')) >= 0
                ? md.indexOf(b.rows.map((r) => r.join(' ')).join(' '))
                : 0),
      ];
      for (final (field, fieldOffset) in fields) {
        for (final t in _tokenize(field)) {
          final match = RegExp(t).firstMatch(field);
          index.putIfAbsent(t, () => []).add({
            'id': node.id,
            'block': i,
            'offset': b.start + fieldOffset + (match?.start ?? 0),
          });
        }
      }
    }
    for (final t in _tokenize(node.title)) {
      index.putIfAbsent(t, () => []).add({
        'id': node.id,
        'block': -1,
        'offset': 0,
      });
    }
    for (final t in node.tags) {
      for (final tok in _tokenize(t)) {
        index.putIfAbsent(tok, () => []).add({
          'id': node.id,
          'block': -2,
          'offset': 0,
        });
      }
    }
    for (final entry in node.properties.entries) {
      final value = entry.value;
      final raw = value is String
          ? value
          : value is num || value is bool
              ? value.toString()
              : value is List
                  ? value.join(' ')
                  : '';
      for (final tok in _tokenize('${entry.key} $raw')) {
        index.putIfAbsent(tok, () => []).add({
          'id': node.id,
          'block': -3,
          'offset': 0,
        });
      }
    }
  }

  void unindexNode(String id) {
    for (final key in index.keys.toList()) {
      index[key]!.removeWhere((e) => e['id'] == id);
      if (index[key]!.isEmpty) index.remove(key);
    }
  }

  List<SearchHit> search(String query, Map<String, MindNode> nodes) {
    final tokens = _tokenize(query);
    if (tokens.isEmpty) return [];
    final scores = <String, double>{};
    final firstBlock = <String, int>{};
    final firstOffset = <String, int>{};
    for (final tok in tokens) {
      final postings = index[tok];
      if (postings == null || postings.isEmpty) return [];
      final matched = <String>{};
      for (final e in postings) {
        final id = e['id'] as String;
        if (matched.contains(id)) continue;
        matched.add(id);
        final block = e['block'] as int;
        final weight = block == -1
            ? _titleWeight
            : (block == -2 || block == -3)
                ? _tagWeight
                : _bodyWeight;
        scores[id] = (scores[id] ?? 0) + weight;
        if (!firstBlock.containsKey(id)) {
          firstBlock[id] = block;
          firstOffset[id] = e['offset'] as int;
        }
      }
      scores.removeWhere((id, _) => !matched.contains(id));
      if (scores.isEmpty) return [];
    }
    final hits = <SearchHit>[];
    for (final e in scores.entries) {
      final node = nodes[e.key];
      if (node == null) continue;
      final block = firstBlock[e.key] ?? -1;
      final offset = firstOffset[e.key] ?? 0;
      hits.add(SearchHit(
        nodeId: e.key,
        blockIndex: block,
        offset: offset,
        snippet: _snippet(node, block, offset),
        score: e.value,
      ));
    }
    hits.sort((a, b) {
      final c = b.score.compareTo(a.score);
      if (c != 0) return c;
      return a.nodeId.compareTo(b.nodeId);
    });
    return hits;
  }

  String _snippet(MindNode node, int block, int offset) {
    String text;
    if (block == -1) {
      text = node.title;
    } else if (block >= 0) {
      final blocks = parseBlocks(node.body);
      text = block < blocks.length ? blocks[block].toMarkdown() : node.body;
    } else {
      text = node.body;
    }
    final start = offset.clamp(0, text.length);
    final from = (start - 40).clamp(0, text.length);
    final to = (start + 60).clamp(0, text.length);
    var snippet = text.substring(from, to).replaceAll('\n', ' ');
    if (from > 0) snippet = '...$snippet';
    if (to < text.length) snippet = '$snippet...';
    return snippet;
  }

  String encode() => jsonEncode({
        'v': 1,
        'index': index.map((k, v) => MapEntry(k, v)),
      });

  void load(String raw) {
    index.clear();
    try {
      final j = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final map = (j['index'] as Map?)?.cast<String, dynamic>() ?? {};
      for (final e in map.entries) {
        index[e.key] = (e.value as List)
            .map((p) => (p as Map).cast<String, dynamic>())
            .toList();
      }
    } catch (_) {}
  }
}
