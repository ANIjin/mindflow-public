import 'dart:async';

import 'package:uuid/uuid.dart';

import '../memory/memory_store.dart';
import '../models/node.dart';
import '../scheduler/notifications.dart';
import 'aktiv.dart';
import 'blackboard.dart';
import 'feed_item.dart';
import 'outlook.dart';

abstract class Connector {
  String get id;
  String get label;
  Map<String, dynamic> get cfg;
  bool get enabled;
  Future<List<FeedItem>> fetch();
}

Map<String, dynamic> integrationCfg(MemoryStore store, String id) =>
    ((store.settings['integrations'] as Map?)?[id] as Map?)
        ?.cast<String, dynamic>() ??
    {};

class IntegrationManager {
  final MemoryStore store;
  final List<Connector> connectors;
  final Map<String, String> status = {};
  bool busy = false;
  DateTime? lastSync;

  IntegrationManager(MemoryStore store)
      : store = store,
        connectors = [
          BlackboardConnector(store),
          AktivConnector(store),
          OutlookConnector(store),
        ];

  int get autoSyncMinutes =>
      (store.settings['integrations'] as Map?)?['autoSyncMinutes'] as int? ??
      15;

  Future<int> sync() async {
    if (busy) return 0;
    busy = true;
    int count = 0;
    for (final c in connectors) {
      if (!c.enabled) continue;
      try {
        final items = await c.fetch();
        for (final it in items) {
          count += await _apply(it);
        }
        status[c.id] =
            'ok - ${items.length} items @ ${DateTime.now().toIso8601String()}';
      } catch (e) {
        status[c.id] = 'error - $e';
      }
    }
    lastSync = DateTime.now();
    busy = false;
    return count;
  }

  Future<int> _apply(FeedItem it) async {
    MindNode? existing;
    for (final n in store.nodes.values) {
      if (n.meta['source'] == it.source && n.meta['ext'] == it.extId) {
        existing = n;
        break;
      }
    }
    final isNew = existing == null;
    final n = existing ?? MindNode(id: const Uuid().v4(), source: 'integration');
    n.type = it.kind;
    n.title = it.title;
    n.body = it.body;
    n.due = it.due;
    n.meta['source'] = it.source;
    n.meta['ext'] = it.extId;
    if (it.link.isNotEmpty) n.meta['link'] = it.link;
    if (it.start != null) n.meta['start'] = it.start!.toIso8601String();
    if (it.end != null) n.meta['end'] = it.end!.toIso8601String();
    if (n.type == 'event' && n.due == null && it.start != null) {
      n.due = it.start;
    }
    await store.saveNode(n);
    await NotificationService.syncNode(n);
    return isNew ? 1 : 0;
  }

  Future<String> outlookSignIn() async {
    final oc = connectors.whereType<OutlookConnector>().first;
    final code = await oc.startSignIn();
    unawaited(oc.pollSignIn().then((ok) async {
      if (ok) {
        status['outlook'] = 'ok - signed in';
        await sync();
      } else {
        status['outlook'] = 'error - sign-in failed or expired';
      }
    }));
    return code;
  }

  bool get outlookSignedIn =>
      connectors.whereType<OutlookConnector>().first.signedIn;
}
