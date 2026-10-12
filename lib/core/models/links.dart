import 'blocks.dart';
import 'node.dart';

class LinkRef {
  String target;
  String? alias;
  int start;
  int end;

  LinkRef(this.target, {this.alias, this.start = 0, this.end = 0});
}

String normalizeTitle(String title) => title.trim().toLowerCase();

String _maskCodeBlocks(String body) {
  final chars = body.codeUnits.toList();
  for (final b in parseBlocks(body)) {
    if (b.type == BlockType.code) {
      for (var i = b.start; i <= b.end && i < chars.length; i++) {
        chars[i] = 32;
      }
    }
  }
  return String.fromCharCodes(chars);
}

List<LinkRef> extractWikilinks(String body) {
  final masked = _maskCodeBlocks(body);
  final pattern = RegExp(r'\[\[([^\]]+)\]\]');
  final refs = <LinkRef>[];
  for (final m in pattern.allMatches(masked)) {
    final raw = m.group(1) ?? '';
    final parts = raw.split('|');
    final target = parts.first.trim();
    final alias = parts.length > 1 ? parts.sublist(1).join('|').trim() : null;
    if (target.isEmpty) continue;
    refs.add(LinkRef(target, alias: alias, start: m.start, end: m.end));
  }
  return refs;
}

List<String> extractTags(String body) {
  final masked = _maskCodeBlocks(body);
  final pattern = RegExp(r'(^|[\s(\[])#([A-Za-z0-9_\-]+)');
  final tags = <String>[];
  for (final m in pattern.allMatches(masked)) {
    final tag = (m.group(2) ?? '').toLowerCase();
    if (tag.isEmpty) continue;
    if (!tags.contains(tag)) tags.add(tag);
  }
  return tags;
}

bool _insideCode(int pos, List<Block> blocks) {
  for (final b in blocks) {
    if (b.type == BlockType.code && pos >= b.start && pos <= b.end) return true;
  }
  return false;
}

String replaceWikilinkTitle(String body, String oldTitle, String newTitle) {
  final blocks = parseBlocks(body);
  final normOld = normalizeTitle(oldTitle);
  final pattern = RegExp(r'\[\[([^\]]+)\]\]');
  final out = StringBuffer();
  var last = 0;
  for (final m in pattern.allMatches(body)) {
    out.write(body.substring(last, m.start));
    final raw = m.group(1) ?? '';
    final parts = raw.split('|');
    final target = parts.first.trim();
    final alias = parts.length > 1 ? parts.sublist(1).join('|') : null;
    if (!_insideCode(m.start, blocks) && normalizeTitle(target) == normOld) {
      out.write(alias == null ? '[[${newTitle}]]' : '[[${newTitle}|${alias}]]');
    } else {
      out.write(m.group(0));
    }
    last = m.end;
  }
  out.write(body.substring(last));
  return out.toString();
}

List<LinkRef> extractUnresolvedLinks(String body, Map<String, String> titleToId) {
  return extractWikilinks(body)
      .where((r) => titleToId[normalizeTitle(r.target)] == null)
      .toList();
}

List<String> _stringList(dynamic value) =>
    value is List ? value.map((e) => e.toString()).toList() : <String>[];

void syncNodeLinks(MindNode node, Map<String, String> titleToId) {
  final resolved = <String>[];
  for (final ref in extractWikilinks(node.body)) {
    final id = titleToId[normalizeTitle(ref.target)];
    if (id != null && !resolved.contains(id)) resolved.add(id);
  }

  final previous = _stringList(node.meta['bodyLinks']);
  final preserved = node.links.where((id) => !previous.contains(id)).toList();
  final merged = List<String>.from(preserved);
  for (final id in resolved) {
    if (!merged.contains(id)) merged.add(id);
  }

  node.links = merged;
  node.meta['bodyLinks'] = resolved;
}

void syncNodeTags(MindNode node) {
  final bodyTags = extractTags(node.body);
  final previous = _stringList(node.meta['bodyTags']);
  final preserved = node.tags.where((t) => !previous.contains(t)).toList();
  final merged = List<String>.from(preserved);
  for (final tag in bodyTags) {
    if (!merged.contains(tag)) merged.add(tag);
  }

  node.tags = merged;
  node.meta['bodyTags'] = bodyTags;
}

void syncNodeLinksAndTags(MindNode node, Map<String, String> titleToId) {
  syncNodeLinks(node, titleToId);
  syncNodeTags(node);
}
