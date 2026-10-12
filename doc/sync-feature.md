# Device Sync

MindFlow device sync is direct and local. Open **Connect devices**, choose a
method that is available for the two devices, confirm the pairing value on both
devices, and start sync.

## Connection methods

| Method | Supported pairing | Prerequisites |
| --- | --- | --- |
| WiFi | Windows to Windows, iOS to iOS, iPhone to Windows | Both devices are on the same local network; allow MindFlow through the Windows firewall on a private network. |
| Bluetooth | iPhone to Windows only | Bluetooth is enabled and the app has the required platform permission. |
| USB | iPhone to Windows only | A data-capable USB cable is connected and the device trusts the Windows PC. |

MindFlow does not silently switch methods. If the selected method is blocked,
the setup flow explains why and lists compatible alternatives.

## Platform setup

iOS requests local-network access the first time WiFi sync is used. Windows
does not require an application network permission declaration; Windows Firewall
must allow MindFlow's local sync traffic on the active private network. Public
networks should remain blocked.

Bluetooth and USB use platform adapters and may require additional native
permissions or a supported cable. WiFi remains the fallback for every supported
Windows/iOS pairing.