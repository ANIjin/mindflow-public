import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'tokens.dart';
import 'widgets/apple.dart';

List<TextSpan> _inline(String s, Color color) {
  final parts = s.split('**');
  final spans = <TextSpan>[];
  for (int i = 0; i < parts.length; i++) {
    if (parts[i].isEmpty) continue;
    spans.add(TextSpan(
      text: parts[i],
      style: TextStyle(
          fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.w400,
          color: color),
    ));
  }
  return spans;
}

Widget _md(String content, Color color) {
  final out = <Widget>[];
  for (final raw in content.split('\n')) {
    if (raw.trim().isEmpty) {
      out.add(const SizedBox(height: 6));
      continue;
    }
    final bullet =
        RegExp(r'^\s*(?:[-*]|\d+[.)])\s+').matchAsPrefix(raw);
    final clean = bullet != null ? raw.substring(bullet.end) : raw;
    out.add(Padding(
      padding: EdgeInsets.only(left: bullet != null ? 12 : 0, bottom: 4),
      child: RichText(
        text: TextSpan(
          text: bullet != null ? '\u{2022}   ' : '',
          style: TextStyle(
              fontSize: 14, height: 1.45, color: color),
          children: _inline(clean, color),
        ),
      ),
    ));
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: out,
  );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final FocusNode _focus;
  int _lastLen = 0;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode(onKeyEvent: _onKeyEvent);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter) return KeyEventResult.ignored;
    // Shift+Enter inserts a newline; bare Enter sends.
    if (HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    final state = context.read<AppState>();
    if (state.busy) return KeyEventResult.handled;
    _send(state);
    return KeyEventResult.handled;
  }

  void _send(AppState state) {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    state.sendChat(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = tk(context);
    if (state.chat.length != _lastLen) {
      _lastLen = state.chat.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
    return Column(
      children: [
        const PageHeader('Chat',
            subtitle: 'Tell the agent what you need'),
        Expanded(
          child: Scrollbar(
            controller: _scroll,
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              children: [
                for (final m in state.chat)
                  Align(
                    alignment: m.role == 'user'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      constraints: const BoxConstraints(maxWidth: 640),
                        decoration: BoxDecoration(
                          color: m.role == 'user'
                              ? t.accent
                              : t.elevated,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (m.role == 'user')
                            SelectableText(
                              m.content,
                              style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Colors.white),
                            )
                            else
                              _md(m.content, t.label),
                            if (m.activity.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                    height: 1,
                                    color: t.hairline),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  for (final a in m.activity)
                                    TagChip(t.secondary, a),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (state.busy)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: TypingBubble(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: t.hairline),
                    boxShadow: [t.shadowHigh],
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  child: TextField(
                    key: const ValueKey('chat-input'),
                    controller: _input,
                    focusNode: _focus,
                    enabled: !state.busy,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!state.busy) _send(state);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Tell the agent what you need… (Enter to send)',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AppleButton(
                '',
                icon: CupertinoIcons.paperplane,
                onPressed: state.busy ? null : () => _send(state),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
