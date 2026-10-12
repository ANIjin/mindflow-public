import 'dart:typed_data';

import 'sync_models.dart';

abstract interface class SyncTransportAdapter {
  SyncTransport get transport;

  Future<List<DeviceIdentity>> discover({Duration timeout = const Duration(seconds: 5)});

  Future<SyncTransportSession> connect(DeviceIdentity remote);
}

abstract interface class SyncTransportSession {
  Future<void> send(Uint8List frame);

  Future<Uint8List> receive();

  Future<void> close();
}

abstract interface class SyncCapabilityProvider {
  Future<TransportCapability> capability(
      DeviceIdentity local, DeviceIdentity remote);
}