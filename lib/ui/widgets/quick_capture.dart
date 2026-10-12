import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../app_state.dart';
import '../../core/models/node.dart';
import '../shell_state.dart';
import '../tokens.dart';

class QuickCaptureOverlay extends StatefulWidget {
  const QuickCaptureOverlay({super.key});

  @override
  State<QuickCaptureOverlay> createState() => _QuickCaptureOverlayState();
}

class _QuickCaptureOverlayState extends State<QuickCaptureOverlay> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final state = context.read<AppState>();
    final shell = context.read<ShellState>();
    final n = MindNode(
      id: const Uuid().v4(),
      title: text.length > 48 ? '${text.substring(0, 48)}…' : text,
      type: 'capture',
      body: text,
      spaceId: 'Inbox',
    );
    await state.saveNode(n);
    if (state.busy) {
      shell.enqueueCapture(n.id);
    } else {
      // Ask agent to file when idle.
      await state.sendChat(
          'File this capture into the right page/class/view and reply with where it landed:\n$text');
    }
    shell.closeQuickCapture();
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellState>();
    if (!shell.quickCaptureOpen) return const SizedBox.shrink();
    final t = tk(context);
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            key: const ValueKey('quick-capture'),
            color: t.card,
            borderRadius: BorderRadius.circular(t.radiusLg),
            child: Padding(
              padding: EdgeInsets.all(t.md),
              child: Row(
                children: [
                  Icon(CupertinoIcons.pencil_ellipsis_rectangle,
                      color: t.accent),
                  SizedBox(width: t.sm),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('capture-input'),
                      controller: _controller,
                      focusNode: _focus,
                      decoration: const InputDecoration(
                        hintText: 'Capture a thought…',
                        border: InputBorder.none,
                        filled: false,
                      ),
                      onSubmitted: (_) => _submit(context),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _submit(context),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
