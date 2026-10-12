import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/memory/memory_store.dart';

const int recentsCap = 10;
const double shellWideBreakpoint = 700;

enum ShellDestination { board, calendar, chat, memory, settings, page, graph }

class ShellState extends ChangeNotifier {
  final MemoryStore? store;

  final List<String> panes = [];
  int activePane = 0;
  String? currentPage;
  bool sidebarCollapsed = false;
  bool paletteOpen = false;
  bool searchOpen = false;
  bool quickCaptureOpen = false;
  int focusEditorTick = 0;
  ShellDestination destination = ShellDestination.board;
  final List<String> captureQueue = [];

  final List<String> recents = [];
  final Set<String> favorites = {};
  final Set<String> expanded = {};

  ShellState({this.store}) {
    final f = store?.settings['favorites'];
    if (f is List) {
      favorites.addAll(f.map((e) => e as String));
    }
  }

  void setDestination(ShellDestination dest) {
    if (destination == dest && dest != ShellDestination.page) return;
    destination = dest;
    if (dest != ShellDestination.page) {
      currentPage = null;
    }
    notifyListeners();
  }

  void openPalette() {
    if (paletteOpen) return;
    paletteOpen = true;
    searchOpen = false;
    notifyListeners();
  }

  void closePalette() {
    if (!paletteOpen) return;
    paletteOpen = false;
    notifyListeners();
  }

  void openSearch() {
    searchOpen = true;
    paletteOpen = true;
    notifyListeners();
  }

  void openQuickCapture() {
    quickCaptureOpen = true;
    paletteOpen = false;
    notifyListeners();
  }

  void closeQuickCapture() {
    if (!quickCaptureOpen) return;
    quickCaptureOpen = false;
    notifyListeners();
  }

  void enqueueCapture(String text) {
    captureQueue.add(text);
    notifyListeners();
  }

  String? dequeueCapture() {
    if (captureQueue.isEmpty) return null;
    final v = captureQueue.removeAt(0);
    notifyListeners();
    return v;
  }

  void requestFocusEditor() {
    focusEditorTick++;
    notifyListeners();
  }

  void _pushRecent(String id) {
    recents.remove(id);
    recents.insert(0, id);
    if (recents.length > recentsCap) {
      recents.removeRange(recentsCap, recents.length);
    }
  }

  void openPage(String id) {
    _pushRecent(id);
    if (panes.isEmpty) {
      panes.add(id);
      activePane = 0;
    } else {
      panes[activePane] = id;
    }
    currentPage = id;
    destination = ShellDestination.page;
    notifyListeners();
  }

  void openInNewPane(String id) {
    _pushRecent(id);
    if (panes.length < 2) {
      panes.add(id);
      activePane = panes.length - 1;
    } else {
      panes[activePane] = id;
    }
    currentPage = id;
    destination = ShellDestination.page;
    notifyListeners();
  }

  void setActivePane(int index) {
    if (index < 0 || index >= panes.length || index == activePane) return;
    activePane = index;
    currentPage = panes[index];
    _pushRecent(panes[index]);
    notifyListeners();
  }

  void closePane(int index) {
    if (index < 0 || index >= panes.length) return;
    panes.removeAt(index);
    if (panes.isEmpty) {
      activePane = 0;
      currentPage = null;
    } else {
      activePane = index < panes.length ? index : panes.length - 1;
      currentPage = panes[activePane];
    }
    notifyListeners();
  }

  void toggleSidebar() {
    sidebarCollapsed = !sidebarCollapsed;
    notifyListeners();
  }

  void setSidebarCollapsed(bool collapsed) {
    if (sidebarCollapsed == collapsed) return;
    sidebarCollapsed = collapsed;
    notifyListeners();
  }

  void toggleFavorite(String id) {
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    if (store != null) {
      store!.settings['favorites'] = favorites.toList();
      // Persist without awaiting so widget tests stay on the fake async clock.
      unawaited(store!.saveSettings());
    }
    notifyListeners();
  }

  void toggleExpanded(String id) {
    if (expanded.contains(id)) {
      expanded.remove(id);
    } else {
      expanded.add(id);
    }
    notifyListeners();
  }
}
