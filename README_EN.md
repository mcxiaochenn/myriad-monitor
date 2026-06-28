# Myriad — 万镜

> "All things observable, mirrored from myriad angles." Every device is a mirror, reflecting each other — no center needed.

**A decentralized, cross-platform system monitoring panel. Devices connect directly via IP — one side collects, the other renders.**

<p align="left">
  <a href="README.md"><img src="https://img.shields.io/badge/中文-README-blue" alt="中文"></a>
  <a href="README_EN.md"><img src="https://img.shields.io/badge/English-README-blue" alt="English"></a>
</p>

<p align="left">
  <img src="https://img.shields.io/github/license/mcxiaochenn/myriad-monitor" alt="License">
  <img src="https://img.shields.io/github/v/release/mcxiaochenn/myriad-monitor" alt="Release">
  <img src="https://img.shields.io/github/actions/workflow/status/mcxiaochenn/myriad-monitor/build.yml?label=CI" alt="Build">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Android%20%7C%20iOS-lightgrey" alt="Platform">
  <img src="https://img.shields.io/badge/Language-中文%20%7C%20English-green" alt="Language">
</p>

## Features

| Feature | Description |
|---|---|
| **Decentralized** | No central server — devices communicate directly via IP |
| **Client & Server in One** | Each instance is both a Server (collecting data) and a Client (displaying data) |
| **Cross-Platform** | Windows / macOS / Linux / Android / iOS — one Flutter codebase |
| **Real-time Monitoring** | CPU, memory, disk, network metrics with live chart rendering |
| **Auto Discovery** | UDP multicast protocol for automatic LAN device discovery |
| **Internationalization** | Chinese and English support, follows system language |
| **Theme Switching** | Light / Dark / Auto (follow system), preference persisted |
| **Visual Experience** | Gaussian blur backgrounds, continuous curvature rounded corners, smooth animations |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Myriad App                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Server       │  │  Discovery   │  │  Client       │  │
│  │ · System Info │  │ · UDP        │  │ · Device List │  │
│  │ · HTTP API    │  │ · Discovery  │  │ · Live Charts │  │
│  │ · JSON        │  │ · Heartbeat  │  │ · Visualization│ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         └─────────────────┴─────────────────┘           │
│                   Local / Network                       │
└─────────────────────────────────────────────────────────┘

Device A (Myriad) ◄──── IP Direct ────► Device B (Myriad)
   Server+Client                      Server+Client
```

## Tech Stack

| Layer | Solution |
|---|---|
| **UI Framework** | Flutter 3.x |
| **State Management** | Riverpod |
| **System Info** | `system_info2` / `dart:ffi` native API calls |
| **Device Communication** | HTTP API (`shelf`), SHA256 token auth, client polling |
| **Device Discovery** | UDP Multicast (`dart:io` RawDatagramSocket) |
| **Charts** | `fl_chart` |
| **Blur Effects** | `BackdropFilter` + `ImageFilter.blur` |
| **Local Storage** | `hive` / `shared_preferences` |
| **i18n** | Custom `AppLocalizations` |

## Quick Start

**Requirements**
- Flutter 3.x / Dart 3.x
- Desktop: Windows 10+ / macOS 10.15+ / Linux (X11/Wayland)
- Mobile: Android 6.0+ / iOS 12.0+

**Install & Run**

```bash
git clone https://github.com/mcxiaochenn/myriad-monitor.git
cd myriad-monitor
flutter pub get

# Desktop
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d linux      # Linux

# Mobile
flutter run -d android    # Android
flutter run -d ios        # iOS
```

**Build Release**

```bash
# Desktop
flutter build windows     # Windows (portable)
flutter build macos       # macOS (DMG)
flutter build linux       # Linux (tar.gz)

# Mobile
flutter build apk         # Android APK
flutter build ios         # iOS
```

## Download

Visit the [Releases](https://github.com/mcxiaochenn/myriad-monitor/releases) page to download the latest version.

All release files follow a unified naming convention: `myriad-monitor-v{version_name}_{version_code}-{platform}.{format}`, e.g. `myriad-monitor-v1.0.0_1-windows-portable.zip`. Version name is read from `pubspec.yaml`, version code is auto-computed from git commit history.

| Platform | Format | Description |
|------|------|------|
| Windows | `.exe` Installer | Standard installation |
| Windows | `.zip` Portable | Extract and run |
| macOS | `.dmg` | DMG installer |
| Linux | `.tar.gz` | tar.gz package |
| Android | `.apk` | Release / Debug |

## Project Structure

```
lib/
├── app/                    # App configuration
│   └── app.dart           # Theme config
├── core/                   # Core modules
│   ├── constants.dart     # Constants
│   ├── discovery/         # Device discovery
│   │   ├── udp_discovery.dart
│   │   ├── discovery_service.dart
│   │   └── discovery_integration.dart
│   ├── models/            # Data models
│   │   ├── device_info.dart
│   │   └── system_metrics.dart
│   └── storage/           # Local storage
│       ├── device_storage.dart
│       └── settings_storage.dart
├── client/                 # Client module
│   ├── client_service.dart
│   └── device_manager.dart
├── server/                 # Server module
│   ├── server_service.dart
│   ├── system_info_collector.dart
│   └── windows_collector.dart
├── features/               # Feature pages
│   ├── home/              # Home
│   ├── detail/            # Device detail
│   ├── server/            # Server status
│   ├── settings/          # Settings
│   └── about/             # About
└── l10n/                   # Internationalization
    ├── app_localizations.dart
    └── locale_provider.dart
```

## Roadmap

- [x] Basic framework
- [x] System info collector (Windows)
- [x] HTTP communication layer (SHA256 token auth)
- [x] Device list UI
- [x] Device detail UI
- [x] Real-time chart rendering
- [x] Auto device discovery (UDP multicast)
- [x] Gaussian blur visual effects
- [x] i18n support (Chinese / English)
- [x] Server config page
- [x] About page
- [x] Device data persistence
- [x] Light/Dark/Auto theme switching
- [x] SHA256 access token management
- [ ] System info collector (macOS/Linux/Android/iOS)
- [ ] Device detail page data integration
- [ ] Historical data storage and charts

## Contributing

Issues and Pull Requests are welcome.

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/xxx`)
3. Commit your changes (`git commit -m 'feat: Add xxx'`)
4. Push the branch (`git push origin feature/xxx`)
5. Open a Pull Request

Please follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

## License

MIT License - see [LICENSE](LICENSE)

## Star History

<a href="https://star-history.com/#mcxiaochenn/myriad-monitor&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=mcxiaochenn/myriad-monitor&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=mcxiaochenn/myriad-monitor&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=mcxiaochenn/myriad-monitor&type=Date" />
 </picture>
</a>
