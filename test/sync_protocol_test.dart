import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/sync/sync_models.dart';
import 'package:mindflow/core/sync/sync_protocol.dart';

void main() {
  final codec = SyncFrameCodec();

  test('frames round-trip and handshake identifies the peer', () {
    const device = DeviceIdentity(
      id: 'device-a',
      name: 'Laptop',
      platform: SyncPlatform.windows,
    );
    final frame = SyncHandshake.request(device);
    final peer = SyncHandshake.accept(codec.decode(codec.encode(frame)));

    expect(peer.id, 'device-a');
    expect(peer.platform, SyncPlatform.windows);
  });

  test('codec rejects malformed, tampered, and incompatible frames', () {
    final bytes = codec.encode(const SyncFrame(
      version: 1,
      type: 'ping',
      payload: {'value': 1},
    ));
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    json['payload'] = {'value': 2};

    expect(() => codec.decode(Uint8List.fromList(utf8.encode(jsonEncode(json)))),
        throwsA(isA<SyncProtocolException>()));
    expect(() => codec.decode(Uint8List.fromList(utf8.encode('not json'))),
        throwsA(isA<SyncProtocolException>()));
    expect(
        () => codec.encode(const SyncFrame(
              version: 2,
              type: 'ping',
              payload: {},
            )),
        throwsA(isA<SyncProtocolException>()));
  });

  test('staging rejects incomplete transfers and accepts duplicate chunks', () {
    final staging = SyncStagingArea(expectedChunks: 2);
    staging.addChunk(1, Uint8List.fromList([3]));
    expect(() => staging.commit(), throwsA(isA<SyncProtocolException>()));
    expect(staging.addChunk(1, Uint8List.fromList([3])), isTrue);
    expect(staging.addChunk(0, Uint8List.fromList([1, 2])), isTrue);
    expect(staging.complete, isTrue);
    expect(staging.commit(), orderedEquals([1, 2, 3]));
    expect(staging.addChunk(0, Uint8List.fromList([9])), isFalse);
  });
}