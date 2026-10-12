import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'sync_models.dart';
import 'sync_protocol.dart';
import 'sync_transport.dart';

typedef WifiSessionHandler = FutureOr<void> Function(WifiSyncSession session);

class WifiSyncSession implements SyncTransportSession {
  final Socket _socket;
  final List<int> _buffer = [];
  final List<Completer<Uint8List>> _waiters = [];
  bool _closed = false;

  WifiSyncSession(this._socket) {
    _socket.listen(_onData, onDone: _onDone, onError: (_) => _onDone());
  }

  Future<void> sendFrame(SyncFrame frame) async {
    await send(SyncFrameCodec().encode(frame));
  }

  Future<SyncFrame> receiveFrame() async =>
      SyncFrameCodec().decode(await receive());

  @override
  Future<void> send(Uint8List frame) async {
    if (_closed) throw const SyncProtocolException('session is closed');
    final header = ByteData(4)..setUint32(0, frame.length);
    _socket.add([...header.buffer.asUint8List(), ...frame]);
    await _socket.flush();
  }

  @override
  Future<Uint8List> receive() {
    if (_buffer.length >= 4) {
      final length = ByteData.sublistView(Uint8List.fromList(_buffer), 0, 4)
          .getUint32(0);
      if (_buffer.length >= length + 4) {
        final frame = Uint8List.fromList(_buffer.sublist(4, length + 4));
        _buffer.removeRange(0, length + 4);
        return Future.value(frame);
      }
    }
    if (_closed) return Future.error(const SyncProtocolException('session closed'));
    final completer = Completer<Uint8List>();
    _waiters.add(completer);
    return completer.future;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final waiter in _waiters) {
      if (!waiter.isCompleted) {
        waiter.completeError(const SyncProtocolException('session closed'));
      }
    }
    _waiters.clear();
    await _socket.close();
  }

  void _onData(List<int> data) {
    _buffer.addAll(data);
    while (_waiters.isNotEmpty && _buffer.length >= 4) {
      final length = ByteData.sublistView(Uint8List.fromList(_buffer), 0, 4)
          .getUint32(0);
      if (_buffer.length < length + 4) return;
      final frame = Uint8List.fromList(_buffer.sublist(4, length + 4));
      _buffer.removeRange(0, length + 4);
      _waiters.removeAt(0).complete(frame);
    }
  }

  void _onDone() {
    _closed = true;
    for (final waiter in _waiters) {
      if (!waiter.isCompleted) {
        waiter.completeError(const SyncProtocolException('session closed'));
      }
    }
    _waiters.clear();
  }
}

class WifiTransportAdapter implements SyncTransportAdapter {
  static const discoveryPort = 45821;
  static final Map<String, _WifiEndpoint> _registry = {};

  final DeviceIdentity local;
  final WifiSessionHandler? onSession;
  ServerSocket? _server;
  RawDatagramSocket? _discoverySocket;
  final Map<String, _WifiEndpoint> _discovered = {};

  WifiTransportAdapter(this.local, {this.onSession});

  @override
  SyncTransport get transport => SyncTransport.wifi;

  Future<void> start({int port = 0}) async {
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
    final endpoint = _WifiEndpoint(local, InternetAddress.loopbackIPv4.address,
        _server!.port);
    _registry[local.id] = endpoint;
    _server!.listen((socket) {
      final session = WifiSyncSession(socket);
      final handler = onSession;
      if (handler != null) unawaited(Future<void>.sync(() => handler(session)));
    });
    try {
      _discoverySocket = await RawDatagramSocket.bind(
          InternetAddress.loopbackIPv4, discoveryPort,
          reuseAddress: true, reusePort: true);
      _discoverySocket!.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = _discoverySocket!.receive();
        if (datagram == null) return;
        try {
          final message = (jsonDecode(utf8.decode(datagram.data)) as Map)
              .cast<String, dynamic>();
          if (message['type'] == 'discover') {
            _discoverySocket!.send(
                utf8.encode(jsonEncode({
                  'type': 'mindflow-sync',
                  ...endpoint.toJson(),
                })),
                datagram.address,
                datagram.port);
          }
        } catch (_) {}
      });
    } catch (_) {
      _discoverySocket = null;
    }
  }

  @override
  Future<List<DeviceIdentity>> discover({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final found = <String, DeviceIdentity>{};
    for (final endpoint in _registry.values) {
      if (endpoint.identity.id != local.id) {
        found[endpoint.identity.id] = endpoint.identity;
        _discovered[endpoint.identity.id] = endpoint;
      }
    }
    final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    try {
      socket.broadcastEnabled = true;
      socket.send(utf8.encode(jsonEncode({'type': 'discover'})),
          InternetAddress.loopbackIPv4, discoveryPort);
      final completer = Completer<void>();
      late StreamSubscription<RawSocketEvent> subscription;
      subscription = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket.receive();
        if (datagram == null) return;
        try {
          final message = (jsonDecode(utf8.decode(datagram.data)) as Map)
              .cast<String, dynamic>();
          if (message['type'] != 'mindflow-sync') return;
          final endpoint = _WifiEndpoint.fromJson(message);
          if (endpoint.identity.id != local.id) {
            found[endpoint.identity.id] = endpoint.identity;
            _discovered[endpoint.identity.id] = endpoint;
          }
        } catch (_) {}
      });
      Timer(timeout, () {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;
      await subscription.cancel();
    } finally {
      socket.close();
    }
    return found.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  Future<WifiSyncSession> connect(DeviceIdentity remote) async {
    final endpoint = _discovered[remote.id] ?? _registry[remote.id];
    if (endpoint == null) {
      throw const SyncProtocolException('device was not discovered');
    }
    final socket = await Socket.connect(endpoint.host, endpoint.port);
    return WifiSyncSession(socket);
  }

  Future<void> stop() async {
    _registry.remove(local.id);
    _discoverySocket?.close();
    await _server?.close();
    _server = null;
  }
}

class _WifiEndpoint {
  final DeviceIdentity identity;
  final String host;
  final int port;

  const _WifiEndpoint(this.identity, this.host, this.port);

  Map<String, dynamic> toJson() => {
        'id': identity.id,
        'name': identity.name,
        'platform': identity.toJson()['platform'],
        'appVersion': identity.appVersion,
        'host': host,
        'port': port,
      };

  factory _WifiEndpoint.fromJson(Map<String, dynamic> json) => _WifiEndpoint(
        DeviceIdentity.fromJson(json),
        json['host'] as String,
        (json['port'] as num).toInt(),
      );
}