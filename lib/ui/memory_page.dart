import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'tokens.dart';
import 'widgets/apple.dart';

class MemoryPage extends StatelessWidget {
  const MemoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppState>().store;
    final t = tk(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader('Memory', subtitle: store.root),
        Expanded(
          child: Scrollbar(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              children: [
                Text('Long-term memory (memory.md)',
                    style: TextStyle(
                        fontSize: t.textTitle,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: t.label)),
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: store.readMemory(),
                  builder: (_, s) => s.hasData
                      ? SectionCard(
                          child: SelectableText(s.data!,
                              style: TextStyle(
                                  color: t.secondary,
                                  fontFamily: 'Consolas',
                                  fontSize: 13,
                                  height: 1.5)),
                        )
                      : const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CupertinoActivityIndicator(),
                        ),
                ),
                const SizedBox(height: 24),
                Text('Recent activity (log.jsonl)',
                    style: TextStyle(
                        fontSize: t.textTitle,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: t.label)),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: store.readLog(40),
                  builder: (_, s) {
                    if (!s.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CupertinoActivityIndicator(),
                      );
                    }
                    final entries = s.data!.reversed.toList();
                    return SectionCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final e in entries)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${e['ts']}  ${e['event']}  ${e['ref']}  ${e['detail']}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: t.secondary,
                                    fontFamily: 'Consolas'),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
