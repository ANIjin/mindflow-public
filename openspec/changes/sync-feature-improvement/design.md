# Design

## Context

The current Flutter app persists MindFlow content through `MemoryStore` and uses `IntegrationManager` for external feed refreshes. There is no existing device-sync transport or pairing subsystem. This change therefore introduces a separate sync domain rather than extending the external integration connector abstraction. See `proposal.md` for motivation and `specs/sync-feature/spec.md` for externally observable behavior.

## Goals / Non-Goals

**Goals:**

- Provide one guided entry point that selects compatible WiFi, Bluetooth, or USB transports.
- Keep pairing, transfer state, and conflict recovery durable and independent of content records.
- Make sync bidirectional, interruption-safe, and testable without requiring real hardware for most logic.
- Keep Windows and iOS platform capability checks behind transport adapters.

**Non-Goals:**

- Replacing or changing external-service integration sync.
- Building a cloud relay, account system, or multi-user collaboration service.
- Supporting Bluetooth or USB for Windows-to-Windows or iOS-to-iOS.

## Decisions

### Separate sync domain from integrations

Create a sync manager/protocol layer under `lib/core` that consumes a content snapshot adapter for `MemoryStore`. The existing `IntegrationManager.sync()` remains responsible for Blackboard, Aktiv, and Outlook. This avoids conflating external imports with peer replication and preserves current auto-sync behavior.

### Transport interface with platform adapters

Define a common transport contract for discovery, connection, framed bytes, cancellation, and capability reporting. Implement WiFi first with a local discovery/handshake flow, then Bluetooth and USB through Windows/iOS platform adapters. The UI consumes capability results instead of knowing platform APIs. This is preferable to embedding three transport implementations in widgets and makes unsupported combinations explicit.

### Pairing and protocol

Represent a pairing with local device identity, remote identity, allowed transport, confirmation metadata, and last successful sync cursor. Pairing confirmation uses a short-lived displayed value or equivalent user confirmation before persistence. Sessions exchange protocol version, device identity, content manifest, chunks, acknowledgements, and a final commit marker. Writes are staged until verified so an interrupted transfer cannot appear complete.

### Content snapshots and conflict variants

Add a content adapter that produces stable records for pages, databases, nodes, and links without changing their public model shape. Each record carries a stable id, revision metadata, and serialized payload. Use a deterministic revision comparison for the winner and store the losing payload in a dedicated conflict record that can be inspected or restored. The exact conflict UI can follow the existing node/page conventions, but the protocol must preserve both versions.

### Capability-driven setup UI

Expose one connect-devices page with method cards or a segmented choice, filtered by device roles and live capability checks. The page shows discovery, confirmation, transfer progress, completion, and actionable errors. It should never silently switch transports because the user needs to know whether a cable, Bluetooth permission, or shared network is involved.

## Risks / Trade-offs

- [Platform API limits] iOS Bluetooth and USB behavior may require native plugin work and permissions → keep adapters isolated, document capabilities, and make WiFi a complete fallback.
- [Network isolation] WiFi discovery may be blocked by guest networks or OS firewalls → show a manual retry/error state and offer Bluetooth/USB for iPhone-to-Windows.
- [Large vaults] Full snapshots can be slow → use manifests and chunked deltas after the initial sync, with checksums and resumable acknowledgements.
- [Conflict UX] Preserving variants increases storage and UI complexity → store variants separately and report them in the sync result before adding richer merge tooling.
- [Protocol evolution] Paired devices may run different app versions → exchange protocol versions and fail with an upgrade message when incompatible.

## Migration Plan

1. Add the sync domain and persistence without changing existing integration refreshes.
2. Ship WiFi pairing and transfer first, then add Bluetooth and USB capability adapters for iPhone-to-Windows.
3. Keep existing local data in place; create sync metadata lazily when the user pairs a device.
4. On rollback, disable the connect-devices entry point and leave local content and integration settings untouched.

## Open Questions

- The initial implementation can choose the concrete native Bluetooth/USB plugin after validating iOS and Windows support; this does not alter the user-facing transport matrix or protocol.