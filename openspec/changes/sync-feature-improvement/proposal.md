# Proposal: Simplify Device Sync

## Change
Add a direct, guided device-sync feature with three connection methods: WiFi, Bluetooth, and USB. WiFi is available for every supported Windows/iOS pairing. Bluetooth and USB are available only between an iPhone and a Windows PC. The flow should let a user connect a phone to a laptop or a laptop to a desktop without configuring a hosted service.

## Why
The current application has an `IntegrationManager` for pulling data from external services and an automatic integration refresh timer, but it does not yet provide device-to-device sync for MindFlow content. A separate, purpose-built sync flow is needed so users can move and reconcile their own pages, databases, and graph data with a small number of understandable steps.

## User outcome
- Choose **Connect devices** and see only methods supported by the two device types.
- Pair two devices with a short confirmation step and reuse that pairing later.
- Start a bidirectional sync over the selected transport and see progress, completion, or a recoverable error.
- Sync without a cloud account, server deployment, or manually managed credential file.

## Areas affected
- **New sync domain layer:** device identity, pairing records, session protocol, snapshot/delta transfer, progress, and deterministic conflict recovery.
- **Transports:** LAN WiFi discovery and transfer for Windows/iOS; platform adapters for iPhone-to-Windows Bluetooth and USB.
- **UI:** a connect-devices entry point, method availability, guided setup, paired-device status, sync progress, and failure recovery.
- **Persistence:** sync metadata and conflict variants stored separately from the existing node model; existing integration settings and auto-sync remain unchanged.
- **Platform configuration:** iOS and Windows permissions/capabilities required by the selected transports.

## Affected spec area
- `sync-feature`: transport availability, pairing, bidirectional content sync, conflict handling, persistence, and unsupported-platform behavior.
