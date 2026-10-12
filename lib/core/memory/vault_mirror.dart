import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/node.dart';

String _sanitize(String name) =>
    name.replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ').trim();

String _yamlQuote(String value) =>
    '"${value.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', ' ')}"';

String frontMatter(MindNode n) {
  final lines = [
    '---',
    'id: ${n.id}',
    'type: ${n.type}',
    'title: ${_yamlQuote(n.title)}',
    'status: ${n.status}',
    'priority: ${n.priority}',
    if (n.due != null) 'due: ${n.due!.toIso8601String()}',
    'tags: [${n.tags.map(_yamlQuote).join(', ')}]',
    if (n.icon != null) 'icon: ${_yamlQuote(n.icon!)}',
    if (n.cover != null) 'cover: ${_yamlQuote(n.cover!)}',
    if (n.spaceId != null) 'space: ${n.spaceId}',
    if (n.parentId != null) 'parent: ${n.parentId}',
    'created: ${n.created.toIso8601String()}',
    'updated: ${n.updated.toIso8601String()}',
    '---',
  ];
  return lines.join('\n');
}

String mirrorContent(MindNode n) => '${frontMatter(n)}\n\n${n.body}\n';

String? frontMatterId(String raw) {
  final lines = raw.split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') return null;
  for (var i = 1; i < lines.length; i++) {
    final l = lines[i].trim();
    if (l == '---') return null;
    if (l.startsWith('id:')) return l.substring(3).trim();
  }
  return null;
}

class VaultMirror {
  final String root;
  final paths = <String, String>{};

  VaultMirror(this.root);

  String get vaultDir => p.join(root, 'vault');

  void scan() {
    paths.clear();
    final dir = Directory(vaultDir);
    if (!dir.existsSync()) return;
    for (final f in dir.listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.md')) {
        final id = frontMatterId(f.readAsStringSync());
        if (id != null) paths[id] = p.relative(f.path, from: vaultDir);
      }
    }
  }

  String _ownerOf(String rel) {
    for (final e in paths.entries) {
      if (e.value == rel) return e.key;
    }
    return '';
  }

  Future<void> writeMirror(MindNode n) async {
    final old = paths[n.id];
    final space = n.spaceId != null ? _sanitize(n.spaceId!) : 'general';
    final base = _sanitize(n.title);
    final name = base.isEmpty ? n.id : base;
    var rel = p.join(space, '$name.md');
    final owner = _ownerOf(rel);
    if (owner.isNotEmpty && owner != n.id) {
      rel = p.join(space, '$base-${n.id}.md');
    }
    final file = File(p.join(vaultDir, rel));
    file.parent.createSync(recursive: true);
    await file.writeAsString(mirrorContent(n));
    paths[n.id] = rel;
    if (old != null && old != rel) {
      final oldFile = File(p.join(vaultDir, old));
      if (oldFile.existsSync()) oldFile.deleteSync();
    }
  }

  Future<void> removeMirror(String id) async {
    final rel = paths.remove(id);
    if (rel == null) return;
    final f = File(p.join(vaultDir, rel));
    if (f.existsSync()) f.deleteSync();
  }
}
