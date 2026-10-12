import 'dart:convert';

import '../models/links.dart';
import '../models/node.dart';

class LinkIndex {
  final out = <String, Set<String>>{};
  final in_ = <String, Set<String>>{};

  Map<String, String> titleIndex(Iterable<MindNode> nodes) {
    final map = <String, String>{};
    for (final n in nodes) {
      map[normalizeTitle(n.title)] = n.id;
    }
    return map;
  }

  void rebuild(Iterable<MindNode> nodes) {
    out.clear();
    in_.clear();
    final ids = nodes.map((n) => n.id).toSet();
    final titles = titleIndex(nodes);
    for (final id in ids) {
      out[id] = <String>{};
      in_[id] = <String>{};
    }
    for (final n in nodes) {
      for (final target in n.links) {
        if (ids.contains(target) && target != n.id) {
          out[n.id]!.add(target);
          in_[target]!.add(n.id);
        }
      }
      for (final ref in extractWikilinks(n.body)) {
        final target = titles[normalizeTitle(ref.target)];
        if (target != null && target != n.id) {
          out[n.id]!.add(target);
          in_[target]!.add(n.id);
        }
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'out': out.map((k, v) => MapEntry(k, v.toList())),
        'in': in_.map((k, v) => MapEntry(k, v.toList())),
      };

  String encode() => jsonEncode(toJson());

  void load(String raw) {
    out.clear();
    in_.clear();
    try {
      final j = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final outMap = (j['out'] as Map?)?.cast<String, dynamic>() ?? {};
      final inMap = (j['in'] as Map?)?.cast<String, dynamic>() ?? {};
      for (final e in outMap.entries) {
        out[e.key] = (e.value as List).map((v) => v as String).toSet();
      }
      for (final e in inMap.entries) {
        in_[e.key] = (e.value as List).map((v) => v as String).toSet();
      }
    } catch (_) {}
  }
}
