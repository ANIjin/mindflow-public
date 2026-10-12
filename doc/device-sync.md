# Device sync (laptop ↔ phone)

MindFlow stores your notes in a personal vault on each device. To keep your
laptop and phone in sync, run a small sync server and enter the **same
passphrase** on both devices.

No account, login, or user id — just a shared secret between your devices.

## 1. Start the sync server

On your laptop (or a home server / VPS):

```bash
cd tools/sync_server
dart pub get
dart run bin/server.dart
# listens on http://0.0.0.0:8787
```

## 2. Link each of your devices

In **Settings → Device sync** on laptop and phone:

| Field | Example |
|-------|---------|
| Sync server URL | Laptop: `http://127.0.0.1:8787` · Phone: `http://192.168.1.20:8787` |
| Sync passphrase | Any secret you invent (same on every device) |

Tap **Save sync settings**, then **Sync now**.

After that, sync also runs about every 5 minutes while the app is open.

## Tip for phone ↔ laptop on the same Wi‑Fi

1. Find your laptop’s LAN IP (`ipconfig` / `ip addr` / System Settings).
2. On the phone, set the sync URL to `http://<laptop-ip>:8787`.
3. Use the exact same passphrase as on the laptop.

## Optional page sharing

**Share current page** creates a code you can give someone. They redeem it on
their MindFlow install (linked to the same sync server); pages land under a
Shared space as copies. This is optional and unrelated to device sync.
