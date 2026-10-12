import 'dart:convert';
import 'dart:typed_data';

import 'sync_models.dart';

class SyncProtocolException implements Exception {
  final String message;

  const SyncProtocolException(this.message);

  @override
  String toString() => 'SyncProtocolException: $message';
}

class SyncFrame {
  final int version;
  final String type;
  final Map<String, dynamic> payload;

  const SyncFrame({
    required this.version,
    required this.type,
    required this.payload,
  });
}

class SyncFrameCodec {
  static const currentVersion = 1;

  Uint8List encode(SyncFrame frame) {
    if (frame.version != currentVersion) {
      throw const SyncProtocolException('unsupported protocol version');
    }
    final checksum = _checksum(frame.version, frame.type, frame.payload);
    return Uint8List.fromList(utf8.encode(jsonEncode({
          'version': frame.version,
          'type': frame.type,
          'payload': frame.payload,
          'checksum': checksum,
        })));
  }

  SyncFrame decode(Uint8List bytes) {
    late Map<String, dynamic> json;
    try {
      json = (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>();
    } catch (_) {
      throw const SyncProtocolException('invalid frame encoding');
    }
    final version = (json['version'] as num?)?.toInt();
    final type = json['type'] as String?;
    final payload = (json['payload'] as Map?)?.cast<String, dynamic>();
    final checksum = json['checksum'] as String?;
    if (version == null || type == null || payload == null || checksum == null) {
      throw const SyncProtocolException('incomplete frame');
    }
    if (version != currentVersion) {
      throw const SyncProtocolException('unsupported protocol version');
    }
    if (checksum != _checksum(version, type, payload)) {
      throw const SyncProtocolException('checksum mismatch');
    }
    return SyncFrame(version: version, type: type, payload: payload);
  }

  String _checksum(int version, String type, Map<String, dynamic> payload) {
    final input = '$version|$type|${jsonEncode(payload)}';
    var hash = 0xcbf29ce484222325;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}

class SyncHandshake {
  static SyncFrame request(DeviceIdentity local) => SyncFrame(
        version: SyncFrameCodec.currentVersion,
        type: 'handshake',
        payload: {'device': local.toJson()},
      );

  static DeviceIdentity accept(SyncFrame frame) {
    if (frame.type != 'handshake') {
      throw const SyncProtocolException('expected handshake');
    }
    final device = frame.payload['device'];
    if (device is! Map) {
      throw const SyncProtocolException('handshake has no device');
    }
    return DeviceIdentity.fromJson(device.cast<String, dynamic>());
  }
}

class SyncStagingArea {
  final int expectedChunks;
  final Map<int, Uint8List> _chunks = {};

  SyncStagingArea({required this.expectedChunks})
      : assert(expectedChunks > 0);

  bool addChunk(int index, Uint8List bytes) {
    if (index < 0 || index >= expectedChunks) {
      throw const SyncProtocolException('chunk index out of range');
    }
    final existing = _chunks[index];
    if (existing != null) {
      return _sameBytes(existing, bytes);
    }
    _chunks[index] = Uint8List.fromList(bytes);
    return true;
  }

  bool get complete => _chunks.length == expectedChunks;

  Uint8List commit() {
    if (!complete) {
      throw const SyncProtocolException('transfer is incomplete');
    }
    final result = BytesBuilder();
    for (var i = 0; i < expectedChunks; i++) {
      result.add(_chunks[i]!);
    }
    return result.takeBytes();
  }

  static bool _sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}