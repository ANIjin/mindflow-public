# Sync Feature Spec Delta

## Scope
This change adds direct device-to-device synchronization for MindFlow content. It does not change the existing external-service integration refresh handled by `IntegrationManager`.

## ADDED Requirements

### Requirement: Supported connection methods
The system SHALL provide WiFi, Bluetooth, and USB connection methods from a single connect-devices flow.

WiFi SHALL be available for Windows-to-Windows, iOS-to-iOS, and iPhone-to-Windows pairings. Bluetooth and USB SHALL be available only for an iPhone-to-Windows pairing. The UI SHALL hide methods that are impossible for the detected device pair and SHALL explain when no method is currently available.

#### Scenario: Windows laptop and desktop over WiFi
- **Given** two Windows devices running MindFlow on the same local network
- **When** the user opens connect devices
- **Then** WiFi is offered, the devices can discover each other locally, and no hosted sync service is required

#### Scenario: iPhone and Windows over WiFi
- **Given** an iPhone and a Windows device running MindFlow on the same local network
- **When** the user opens connect devices
- **Then** WiFi is offered and can establish a sync session

#### Scenario: Bluetooth and USB availability
- **Given** an iPhone and a Windows device
- **When** the user opens connect devices
- **Then** Bluetooth and USB are offered when the corresponding platform capability is available
- **Given** two Windows devices or two iOS devices
- **When** the user opens connect devices
- **Then** Bluetooth and USB are not offered

### Requirement: Guided pairing
The system SHALL guide the user through selecting a method, identifying the second device, confirming a short-lived pairing code or equivalent confirmation, and seeing a clear success or failure state. A successful pairing SHALL be saved locally for later reconnection, and the user SHALL be able to remove a saved pairing.

#### Scenario: First-time pairing
- **Given** two compatible devices with no saved pairing
- **When** the user selects an available method and follows the prompts on both devices
- **Then** both devices show the same confirmation value, save the pairing only after confirmation, and offer sync

#### Scenario: Reconnect a known device
- **Given** two devices with a saved pairing
- **When** the user starts sync
- **Then** the application attempts to reconnect using the saved pairing and asks for setup again only when the pairing is unavailable or revoked

### Requirement: Bidirectional content synchronization
The system SHALL synchronize pages, databases, graph nodes, and graph links between paired devices in both directions. A session SHALL show its current phase and transfer result, and it SHALL be resumable or safely restartable after a transport interruption without corrupting local data.

#### Scenario: Sync differing content
- **Given** two paired devices with different MindFlow content
- **When** the user starts a sync session
- **Then** each device receives the other device's new or changed supported content and the session reports a completion result

#### Scenario: Interrupted transfer
- **Given** an active sync session loses its connection
- **When** the user retries
- **Then** the application resumes from verified transfer state or restarts safely, and it does not expose partial records as completed content

### Requirement: Deterministic conflict recovery
When the same item changed on both devices since their last successful sync, the system SHALL apply a deterministic winner rule, preserve the losing version as a recoverable conflict variant, and report that a conflict occurred. Sync SHALL NOT silently discard either version.

#### Scenario: Concurrent page edits
- **Given** both devices changed the same page independently
- **When** they sync
- **Then** the same winner is selected on both devices, the other version is retained for recovery, and the conflict is visible in the sync result

### Requirement: Direct local transport
The system SHALL transfer sync data directly over the selected WiFi, Bluetooth, or USB connection. The feature SHALL not require a cloud account, hosted sync server, or manually managed server credential file. Existing external integration credentials and refresh behavior SHALL remain unchanged.

#### Scenario: Direct session without hosted service
- **Given** two paired devices and a selected connection method
- **When** the user starts sync with no cloud account or hosted server configured
- **Then** the devices transfer the supported MindFlow content directly and the existing external integration credentials remain unchanged

### Requirement: Unsupported and unavailable transports
The system SHALL report when a selected transport is unavailable because of platform support, permissions, network isolation, missing cable, Bluetooth state, or an incompatible device pair. It SHALL offer the user another compatible method when one exists and SHALL not silently fall back to a different transport.

#### Scenario: Unavailable selected transport
- **Given** the selected transport is blocked by permissions, network isolation, a missing cable, disabled Bluetooth, or an incompatible device pair
- **When** the user attempts to connect
- **Then** the application explains the blocking condition, offers another compatible method when available, and does not silently switch transports

## REMOVED Requirements

### Requirement: Server-backed device sync
**Reason**: The requested product behavior is direct personal-device sync, not hosted synchronization. No server-backed device-sync credential model is present in the current implementation to migrate.
**Migration**: Existing local MindFlow data and external integration settings remain untouched. Users create pairings through the new connect-devices flow.
