import 'dart:convert';

enum SyncPlatform { windows, ios }

enum SyncTransport { wifi, bluetooth, usb }

enum SyncPhase {
  idle,
  discovering,
  pairing,
  connecting,
  transferring,
  reconciling,
  completed,
  failed,
  cancelled,
}

String _enumValue(Object value) => value.toString().split('.').last;

T _enumByName<T extends Enum>(Iterable<T> values, String? value, T fallback) {
  for (final candidate in values) {
    if (_enumValue(candidate) == value) return candidate;
  }
  return fallback;
}

class DeviceIdentity {
  final String id;
  final String name;
  final SyncPlatform platform;
  final String appVersion;

  const DeviceIdentity({
    required this.id,
    required this.name,
    required this.platform,
    this.appVersion = '1.0.0',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'platform': _enumValue(platform),
        'appVersion': appVersion,
      };

  factory DeviceIdentity.fromJson(Map<String, dynamic> json) => DeviceIdentity(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'MindFlow device',
        platform: _enumByName(
            SyncPlatform.values, json['platform'] as String?, SyncPlatform.windows),
        appVersion: json['appVersion'] as String? ?? '1.0.0',
      );

  String encode() => jsonEncode(toJson());

  factory DeviceIdentity.decode(String value) =>
      DeviceIdentity.fromJson((jsonDecode(value) as Map).cast<String, dynamic>());
}

class TransportCapability {
  final SyncTransport transport;
  final bool supported;
  final bool available;
  final String? reason;

  const TransportCapability({
    required this.transport,
    required this.supported,
    required this.available,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'transport': _enumValue(transport),
        'supported': supported,
        'available': available,
        if (reason != null) 'reason': reason,
      };

  factory TransportCapability.fromJson(Map<String, dynamic> json) =>
      TransportCapability(
        transport: _enumByName(
            SyncTransport.values, json['transport'] as String?, SyncTransport.wifi),
        supported: json['supported'] == true,
        available: json['available'] == true,
        reason: json['reason'] as String?,
      );
}

class Pairing {
  final String id;
  final DeviceIdentity remote;
  final SyncTransport transport;
  final String confirmation;
  final DateTime createdAt;
  final DateTime? lastSyncAt;
  final String? cursor;

  const Pairing({
    required this.id,
    required this.remote,
    required this.transport,
    required this.confirmation,
    required this.createdAt,
    this.lastSyncAt,
    this.cursor,
  });

  Pairing copyWith({DateTime? lastSyncAt, String? cursor}) => Pairing(
        id: id,
        remote: remote,
        transport: transport,
        confirmation: confirmation,
        createdAt: createdAt,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        cursor: cursor ?? this.cursor,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'remote': remote.toJson(),
        'transport': _enumValue(transport),
        'confirmation': confirmation,
        'createdAt': createdAt.toIso8601String(),
        if (lastSyncAt != null) 'lastSyncAt': lastSyncAt!.toIso8601String(),
        if (cursor != null) 'cursor': cursor,
      };

  factory Pairing.fromJson(Map<String, dynamic> json) => Pairing(
        id: json['id'] as String? ?? '',
        remote: DeviceIdentity.fromJson(
            (json['remote'] as Map).cast<String, dynamic>()),
        transport: _enumByName(
            SyncTransport.values, json['transport'] as String?, SyncTransport.wifi),
        confirmation: json['confirmation'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        lastSyncAt: DateTime.tryParse(json['lastSyncAt'] as String? ?? ''),
        cursor: json['cursor'] as String?,
      );
}

class SyncRevision {
  final String deviceId;
  final int counter;
  final DateTime changedAt;

  const SyncRevision({
    required this.deviceId,
    required this.counter,
    required this.changedAt,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'counter': counter,
        'changedAt': changedAt.toIso8601String(),
      };

  factory SyncRevision.fromJson(Map<String, dynamic> json) => SyncRevision(
        deviceId: json['deviceId'] as String? ?? '',
        counter: (json['counter'] as num?)?.toInt() ?? 0,
        changedAt: DateTime.tryParse(json['changedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class SyncRecord {
  final String id;
  final String kind;
  final Map<String, dynamic> payload;
  final SyncRevision revision;
  final bool deleted;

  const SyncRecord({
    required this.id,
    required this.kind,
    required this.payload,
    required this.revision,
    this.deleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'payload': payload,
        'revision': revision.toJson(),
        'deleted': deleted,
      };

  factory SyncRecord.fromJson(Map<String, dynamic> json) => SyncRecord(
        id: json['id'] as String? ?? '',
        kind: json['kind'] as String? ?? 'node',
        payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? {},
        revision: SyncRevision.fromJson(
            (json['revision'] as Map).cast<String, dynamic>()),
        deleted: json['deleted'] == true,
      );
}

class SyncManifest {
  final String sessionId;
  final List<SyncRecord> records;

  const SyncManifest({required this.sessionId, required this.records});

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'records': records.map((record) => record.toJson()).toList(),
      };

  factory SyncManifest.fromJson(Map<String, dynamic> json) => SyncManifest(
        sessionId: json['sessionId'] as String? ?? '',
        records: (json['records'] as List? ?? [])
            .map((record) =>
                SyncRecord.fromJson((record as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class ConflictRecord {
  final String id;
  final String recordId;
  final SyncRecord winner;
  final SyncRecord variant;
  final DateTime createdAt;

  const ConflictRecord({
    required this.id,
    required this.recordId,
    required this.winner,
    required this.variant,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'recordId': recordId,
        'winner': winner.toJson(),
        'variant': variant.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory ConflictRecord.fromJson(Map<String, dynamic> json) => ConflictRecord(
        id: json['id'] as String? ?? '',
        recordId: json['recordId'] as String? ?? '',
        winner: SyncRecord.fromJson(
            (json['winner'] as Map).cast<String, dynamic>()),
        variant: SyncRecord.fromJson(
            (json['variant'] as Map).cast<String, dynamic>()),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class SyncProgress {
  final SyncPhase phase;
  final int completed;
  final int total;
  final String? message;

  const SyncProgress({
    required this.phase,
    this.completed = 0,
    this.total = 0,
    this.message,
  });
}