# iOS sideload (IPA)

## Build the IPA

### Option A — GitHub Actions
1. Actions → **iOS release** → Run workflow.
2. Download the `mindflow-ios-ipa` artifact (`mindflow.ipa`).

### Option B — Mac locally

```bash
flutter pub get
flutter build ios --release --no-codesign
mkdir -p ipa/Payload
cp -R build/ios/iphoneos/Runner.app ipa/Payload/
(cd ipa && zip -qr ../mindflow.ipa Payload)
```

## Install on iPhone

Use **AltStore**, **Sideloadly**, or **TrollStore** (device-dependent):

1. Transfer `mindflow.ipa` to the install tool.
2. Sign with your Apple ID (free 7-day) or a developer cert.
3. On iPhone: Settings → General → VPN & Device Management → trust the cert.
4. Open MindFlow — it starts on your personal vault (no login).

Bundle id: `com.mindflow.mindflow`.

## Sync with your laptop

Info.plist allows local networking. See [device-sync.md](device-sync.md).

- Sync server on laptop: `http://192.168.x.x:8787`
- Same passphrase on phone and laptop

For LM Studio on your PC, base URL example: `http://192.168.x.x:1234/v1`.

Both devices must be on the same Wi‑Fi (or use a tunnel/VPN).

## Phone UI

The shell switches to a drawer layout under 700px width. Safe areas are
applied for notched devices.
