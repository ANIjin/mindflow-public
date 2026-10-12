import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'node_editor.dart';
import 'tokens.dart';
import 'widgets/apple.dart';
import 'widgets/database_workspace.dart';

class BoardPage extends StatelessWidget {
  const BoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = tk(context);
    return Column(
      key: const ValueKey('board-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader('Board',
            subtitle: 'Database views over your nodes',
            trailing: [
              AppleButton('Reorganize',
                  icon: CupertinoIcons.sparkles,
                  tone: AppleTone.tinted,
                  onPressed: state.busy ? null : () => state.reorganize()),
              const SizedBox(width: 10),
              AppleButton('New Node',
                  icon: CupertinoIcons.plus,
                  onPressed: () => showNodeEditor(context, state)),
            ]),
        if (state.busy)
          Padding(
            padding: EdgeInsets.fromLTRB(t.lg, 0, t.lg, t.sm),
            child: const AppleProgress(),
          ),
        const Expanded(child: DatabaseWorkspace()),
      ],
    );
  }
}
