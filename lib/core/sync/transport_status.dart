import 'sync_models.dart';

enum TransportIssueKind {
  unsupportedPair,
  permissionDenied,
  networkUnavailable,
  timedOut,
  incompatibleProtocol,
}

class SyncTransportIssue {
  final TransportIssueKind kind;
  final String message;
  final bool retryable;
  final List<SyncTransport> alternatives;

  const SyncTransportIssue({
    required this.kind,
    required this.message,
    required this.retryable,
    this.alternatives = const [],
  });
}

class SyncTransportMatrix {
  static List<TransportCapability> capabilities(
      DeviceIdentity local, DeviceIdentity remote,
      {Set<SyncTransport> available = const {}}) {
    return SyncTransport.values.map((transport) {
      final supported = _supports(local, remote, transport);
      return TransportCapability(
        transport: transport,
        supported: supported,
        available: supported && available.contains(transport),
        reason: supported ? null : _unsupportedReason(transport),
      );
    }).toList();
  }

  static SyncTransportIssue wifiIssue(
      Object error, DeviceIdentity local, DeviceIdentity remote) {
    final text = '$error'.toLowerCase();
    final kind = text.contains('permission')
        ? TransportIssueKind.permissionDenied
        : text.contains('timeout') || text.contains('timed out')
            ? TransportIssueKind.timedOut
            : text.contains('protocol')
                ? TransportIssueKind.incompatibleProtocol
                : TransportIssueKind.networkUnavailable;
    final alternatives = capabilities(local, remote)
        .where((capability) =>
            capability.supported && capability.transport != SyncTransport.wifi)
        .map((capability) => capability.transport)
        .toList();
    return SyncTransportIssue(
      kind: kind,
      message: _message(kind),
      retryable: kind != TransportIssueKind.incompatibleProtocol,
      alternatives: alternatives,
    );
  }

  static bool _supports(
      DeviceIdentity local, DeviceIdentity remote, SyncTransport transport) {
    if (transport == SyncTransport.wifi) return true;
    final platforms = {local.platform, remote.platform};
    return platforms.length == 2 &&
        platforms.contains(SyncPlatform.ios) &&
        platforms.contains(SyncPlatform.windows);
  }

  static String _unsupportedReason(SyncTransport transport) =>
      '${transport.name.toUpperCase()} is only available between iPhone and Windows';

  static String _message(TransportIssueKind kind) => switch (kind) {
        TransportIssueKind.permissionDenied =>
          'MindFlow cannot access the local network. Check permissions and retry.',
        TransportIssueKind.networkUnavailable =>
          'The devices could not reach each other on this WiFi network.',
        TransportIssueKind.timedOut =>
          'The WiFi connection timed out. Confirm both devices are on the same network and retry.',
        TransportIssueKind.incompatibleProtocol =>
          'These MindFlow versions cannot sync with each other.',
        TransportIssueKind.unsupportedPair =>
          'This device pair cannot use the selected transport.',
      };
}