import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'ui/app_shell.dart';
import 'ui/shell_state.dart';
import 'ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  final state = await AppState.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider(
            create: (_) => ShellState(store: state.store)),
      ],
      child: const MindFlowApp(),
    ),
  );
}

class MindFlowApp extends StatelessWidget {
  const MindFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final mode = switch (state.themeChoice) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    return MaterialApp(
      title: 'MindFlow',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      darkTheme: theme(),
      themeMode: mode,
      scrollBehavior: const _MindFlowScrollBehavior(),
      home: const AppShell(),
    );
  }
}

class _MindFlowScrollBehavior extends MaterialScrollBehavior {
  const _MindFlowScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
