import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/models/links.dart';
import 'package:mindflow/core/models/node.dart';

void main() {
  test('extracts wikilinks with aliases', () {
    final refs = extractWikilinks('See [[Calculus I|Calc]] and [[Linear Algebra]].');
    expect(refs.length, 2);
    expect(refs[0].target, 'Calculus I');
    expect(refs[0].alias, 'Calc');
    expect(refs[1].target, 'Linear Algebra');
    expect(refs[1].alias, isNull);
  });

  test('extracts tags and ignores headings, code, and url fragments', () {
    final body = '''
# Notes

See #physics and #study-skills.

```dart
[[Code]] #tag
```

https://example.com/#section
''';
    final tags = extractTags(body);
    expect(tags, ['physics', 'study-skills']);
    expect(extractWikilinks(body), isEmpty);
  });

  test('unresolved links are reported separately from resolved links', () {
    final titleToId = {'calculus i': 'calc1'};
    final body = '[[Calculus I]] [[Missing Page]]';
    final unresolved = extractUnresolvedLinks(body, titleToId);
    expect(unresolved.map((r) => r.target), ['Missing Page']);
  });

  test('sync adds resolved wikilinks, leaves unresolved links out, and preserves agent links', () {
    final node = MindNode(
      id: 'n1',
      title: 'Notes',
      body: '[[Calculus I]] [[Missing Page]]',
      links: ['agent1'],
    );
    syncNodeLinks(node, {'calculus i': 'calc1'});
    expect(node.links, ['agent1', 'calc1']);
    expect(node.meta['bodyLinks'], ['calc1']);
  });

  test('sync removes links created by removed wikilinks and keeps agent links', () {
    final node = MindNode(
      id: 'n1',
      title: 'Notes',
      body: '[[Calculus I]]',
      links: ['agent1'],
    );
    syncNodeLinks(node, {'calculus i': 'calc1', 'linear algebra': 'lin1'});
    expect(node.links, ['agent1', 'calc1']);

    node.body = '[[Linear Algebra]]';
    syncNodeLinks(node, {'calculus i': 'calc1', 'linear algebra': 'lin1'});
    expect(node.links, ['agent1', 'lin1']);
    expect(node.meta['bodyLinks'], ['lin1']);
  });

  test('sync tags adds body tags, preserves existing tags, and removes removed body tags', () {
    final node = MindNode(
      id: 'n1',
      title: 'Notes',
      body: '#physics #study',
      tags: ['school'],
    );
    syncNodeTags(node);
    expect(node.tags, ['school', 'physics', 'study']);

    node.body = '#physics';
    syncNodeTags(node);
    expect(node.tags, ['school', 'physics']);
    expect(node.meta['bodyTags'], ['physics']);
  });
}
