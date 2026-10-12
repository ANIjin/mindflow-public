import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/sync/sync_models.dart';
import 'package:mindflow/core/sync/transport_status.dart';

void main() {
  const laptop = DeviceIdentity(
    id: 'laptop',
    name: 'Laptop',
    platform: SyncPlatform.windows,
  );
  const phone = DeviceIdentity(
    id: 'phone',
    name: 'Phone',
    platform: SyncPlatform.ios,
  );

  test('WiFi is universal and Bluetooth/USB are iPhone-Windows only', () {
    final crossPlatform = SyncTransportMatrix.capabilities(laptop, phone,
        available: {SyncTransport.wifi, SyncTransport.usb});
    expect(crossPlatform[0].available, isTrue);
    expect(crossPlatform[1].supported, isTrue);
    expect(crossPlatform[2].available, isTrue);

    final windowsOnly = SyncTransportMatrix.capabilities(laptop, laptop);
    expect(windowsOnly[0].supported, isTrue);
    expect(windowsOnly[1].supported, isFalse);
    expect(windowsOnly[2].supported, isFalse);
  });

  test('WiFi issue exposes retryability and compatible alternatives', () {
    final issue = SyncTransportMatrix.wifiIssue(
        Exception('permission denied'), laptop, phone);

    expect(issue.kind, TransportIssueKind.permissionDenied);
    expect(issue.retryable, isTrue);
    expect(issue.alternatives, containsAll([SyncTransport.bluetooth, SyncTransport.usb]));
    expect(issue.message, contains('permissions'));
  });
}