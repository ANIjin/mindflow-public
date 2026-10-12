# Tasks

## 1. Sync foundation

- [x] 1.1 Add sync domain models for device identity, transport capabilities, pairings, session phases, transfer manifests, revisions, and conflict records; verify serialization round-trips in focused unit tests.
- [x] 1.2 Add durable sync metadata storage separate from `MemoryStore` content records, including pairing removal and last successful session state; verify a reopen preserves pairings and does not alter existing integration settings.
- [x] 1.3 Define the transport contract and content snapshot adapter for pages, databases, graph nodes, and links; verify snapshot identifiers and payloads are stable across repeated reads.
- [x] 1.4 Implement the protocol handshake, version check, framed messages, checksums, acknowledgements, staged writes, and retry-safe commit flow; verify malformed frames, duplicate chunks, and interrupted sessions are rejected or safely retried.

## 2. Content reconciliation

- [x] 2.1 Implement bidirectional manifest comparison and delta selection for new, changed, and deleted supported records; verify a two-device fixture exchanges all supported content without duplicating records.
- [x] 2.2 Implement the deterministic revision winner rule and durable losing-version conflict records; verify concurrent edits produce the same winner on both peers and preserve the losing payload.
- [x] 2.3 Add sync result/progress events for discovery, pairing, transfer, conflict, completion, and failure; verify listeners receive terminal results for success, cancellation, and transport interruption.

## 3. WiFi transport

- [x] 3.1 Implement local-network device discovery and direct WiFi transport using the common transport contract; verify two local test peers discover, authenticate, exchange framed data, and close cleanly without a hosted service.
- [x] 3.2 Add WiFi capability/error handling for permissions, network isolation, timeout, and incompatible protocol versions; verify the UI-facing result offers retry or another compatible method without silently switching transports.
- [ ] 3.3 Document and configure the iOS and Windows network permissions required by WiFi sync; verify the app builds for both target platforms with the declared capabilities.

## 4. iPhone-to-Windows transports

- [ ] 4.1 Add platform capability adapters for Bluetooth discovery/connection and USB connection on iPhone-to-Windows pairs; verify unsupported Windows-to-Windows and iOS-to-iOS pairings report unavailable before a session starts.
- [ ] 4.2 Implement Bluetooth and USB framing over the common protocol, including missing-cable, disabled-Bluetooth, permission, disconnect, and retry states; verify adapter tests cover each unavailable condition.
- [ ] 4.3 Configure and document the native iOS/Windows permissions and plugin dependencies required by Bluetooth and USB; verify targeted platform builds and a hardware smoke path where the development environment supports it.

## 5. Connect-devices experience

- [ ] 5.1 Add a single connect-devices entry point and method selection view that filters WiFi, Bluetooth, and USB by detected device roles and live capabilities; verify widget tests cover the supported pairing matrix.
- [ ] 5.2 Add guided discovery, short-lived pairing confirmation, saved-device reconnect, pairing removal, and actionable unavailable-transport states; verify widget/integration tests cover first pairing and reconnect flows.
- [ ] 5.3 Add sync progress, completion summary, conflict notice, cancellation, and retry UI; verify the user can retry an interrupted session without showing partial content as complete.
- [ ] 5.4 Document the user flow and transport limitations in the relevant project documentation; verify the instructions match the implemented method matrix and error states.

## 6. Application integration and verification

- [ ] 6.1 Wire the sync manager into app state and navigation without changing `IntegrationManager` external-source refresh or its existing auto-sync timer; verify existing integration and app-state tests remain green.
- [ ] 6.2 Add end-to-end coverage for Windows laptop-to-desktop WiFi and iPhone-to-Windows setup using mocked platform transports; verify bidirectional content, conflict recovery, and reconnect behavior.
- [ ] 6.3 Run the focused sync test suite, `flutter analyze`, and the applicable Windows/iOS build checks; manually exercise connect, pair, sync, disconnect, retry, and conflict-result states in a running target before marking the change complete.