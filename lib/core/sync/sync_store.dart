import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'sync_models.dart';

class SyncStore {
  static const _fileName = 'state.json';

  final String root;
  final DeviceIdentity localDevice;
  final Map<String, Pairing> pairings;
  final Map<String, ConflictRecord> conflicts;

  SyncStore._({
    required this.root,
    required this.localDevice,
    required this.pairings,
    required this.conflicts,
  });

  String get _directory => p.join(root, 'sync');
  String get _file => p.join(_directory, _fileName);

  static Future<SyncStore> open({
    required String root,
    String? deviceName,
    SyncPlatform platform = SyncPlatform.windows,
    String appVersion = '1.0.0',
  }) async {
    final file = File(p.join(root, 'sync', _fileName));
    final fallback = DeviceIdentity(
      id: const Uuid().v4(),
      name: deviceName ?? 'MindFlow device',
      platform: platform,
      appVersion: appVersion,
    );
    if (!file.existsSync()) {
        final store = SyncStore._(
          root: root, localDevice: fallback, pairings: {}, conflicts: {});
      await store._save();
      return store;
    }
    try {
      final json = (jsonDecode(await file.readAsString()) as Map)
          .cast<String, dynamic>();
      final identity = json['localDevice'] is Map
          ? DeviceIdentity.fromJson(
              (json['localDevice'] as Map).cast<String, dynamic>())
          : fallback;
      final pairings = <String, Pairing>{};
      for (final item in (json['pairings'] as List? ?? [])) {
        final pairing = Pairing.fromJson((item as Map).cast<String, dynamic>());
        pairings[pairing.id] = pairing;
      }
      final conflicts = <String, ConflictRecord>{};
      for (final item in (json['conflicts'] as List? ?? [])) {
        final conflict =
            ConflictRecord.fromJson((item as Map).cast<String, dynamic>());
        conflicts[conflict.id] = conflict;
      }
      return SyncStore._(
          root: root,
          localDevice: identity,
          pairings: pairings,
          conflicts: conflicts);
    } catch (_) {
      final store = SyncStore._(
          root: root, localDevice: fallback, pairings: {}, conflicts: {});
      await store._save();
      return store;
    }
  }

  Future<void> savePairing(Pairing pairing) async {
    pairings[pairing.id] = pairing;
    await _save();
  }

  Future<void> removePairing(String id) async {
    pairings.remove(id);
    await _save();
  }

  Future<void> recordSync(String pairingId, {required String cursor}) async {
    final pairing = pairings[pairingId];
    if (pairing == null) return;
    pairings[pairingId] = pairing.copyWith(
      lastSyncAt: DateTime.now().toUtc(),
      cursor: cursor,
    );
    await _save();
  }

  Future<void> saveConflict(ConflictRecord conflict) async {
    conflicts[conflict.id] = conflict;
    await _save();
  }

  Future<void> _save() async {
    final directory = Directory(_directory);
    if (!directory.existsSync()) directory.createSync(recursive: true);
    final temp = File('$_file.tmp');
    await temp.writeAsString(jsonEncode({
      'localDevice': localDevice.toJson(),
      'pairings': pairings.values.map((pairing) => pairing.toJson()).toList(),
      'conflicts': conflicts.values.map((conflict) => conflict.toJson()).toList(),
    }));
    if (File(_file).existsSync()) File(_file).deleteSync();
    await temp.rename(_file);
  }
}