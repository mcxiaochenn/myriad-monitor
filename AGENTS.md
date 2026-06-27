# AGENTS.md

> Compact guide for agent sessions working in this repository.

## Project at a glance

**Myriad (万镜)** — decentralized cross-platform system monitoring dashboard. Each instance is both Server (collects metrics) and Client (displays dashboards). Devices connect via direct IP, no central server.

## Key rules (from CLAUDE.md)

- **All communication in Chinese** — replies, explanations, code comments
- **Commit only, never push** unless user explicitly says "推送" or "push"
- **Conventional Commits** — `feat:`, `fix:`, `docs:`, `refactor:`, `perf:`, `test:`, `chore:`, `ci:`, `revert:`
- **Ask when uncertain** — don't guess

## Tech stack

- **Framework**: Flutter 3.x (Dart >=3.0.0 <4.0.0)
- **State management**: Riverpod (`flutter_riverpod`)
- **System info**: `system_info2` + `dart:ffi` + `win32` (Windows-specific)
- **Networking**: WebSocket via `shelf` + `web_socket_channel`; UDP multicast via `dart:io` RawDatagramSocket
- **Charts**: `fl_chart`
- **Storage**: `hive` / `shared_preferences`
- **L10n**: Custom `AppLocalizations` class (NOT flutter gen-l10n)

## Commands

Flutter is at `D:\flutter\bin` on this machine. Use `flutter` directly (already in PATH or prepend).

```bash
flutter pub get                    # install deps
flutter run -d windows             # run on Windows
flutter analyze                    # static analysis
dart format .                      # format code
flutter test                       # run tests
flutter test test/path/to_test.dart # single test file
flutter build windows              # release build
```

No `lint`, `typecheck`, or `codegen` steps beyond `flutter analyze`. Always run `flutter analyze` before committing.

## Repository structure

```
lib/
├── main.dart              # entry point, ProviderScope, MainPage with bottom nav
├── app/app.dart           # AppRoutes, AppTheme, placeholder pages
├── client/                # WebSocket client + DeviceManager
├── core/
│   ├── constants.dart     # all magic numbers/strings in typed constant classes
│   ├── discovery/         # UDP multicast device discovery (239.255.255.250:1900)
│   ├── models/            # DeviceInfo, SystemMetrics data classes
│   └── storage/           # Hive + SharedPreferences wrappers
├── features/
│   ├── home/              # device card list, sorting
│   ├── detail/            # per-device charts (chart_widget.dart)
│   ├── server/            # local server status page
│   ├── settings/          # config page
│   └── about/             # app info page
├── l10n/
│   ├── app_localizations.dart  # manual zh/en translations via getter methods
│   └── locale_provider.dart    # Riverpod locale state
└── server/
    ├── server_service.dart      # shelf WebSocket server, pushes systemInfo JSON
    ├── system_info_collector.dart # abstract collector interface
    └── windows_collector.dart    # Windows FFI implementation
```

## Non-obvious patterns

### Platform directories are generated, not committed

CI runs `flutter create --project-name myriad_monitor --platforms <platform> .` before building. The `android/`, `ios/`, `macos/`, `linux/`, `windows/` dirs may not exist locally until you run `flutter create` or `flutter run` for that platform. Only `windows/` is partially committed (for the Inno Setup installer script at `windows/installer.iss`).

### Adding a new user-visible string

All UI text must go through `AppLocalizations` in `lib/l10n/app_localizations.dart`. Add a getter (or method for parameterized strings) with a `zh`/`en` switch. Access in widgets via `AppLocalizations.of(context).yourKey`. Never hardcode user-facing strings in widget code.

### Network protocol constants

Default ports and intervals are in `lib/core/constants.dart` — `NetworkConstants`, `RefreshConstants`, `UIConstants`, `StorageConstants`. Don't hardcode numbers in feature code; import from there.

### Discovery message format

UDP messages are JSON-encoded `DiscoveryMessage` objects with snake_case keys (`device_id`, `device_name`). Types: `announce`, `heartbeat`, `heartbeat_ack`. See `lib/core/discovery/discovery_message.dart`.

### WebSocket server data push

`ServerService` pushes `{"type": "systemInfo", "data": {...}}` JSON to all connected clients at a configurable interval. The collector interface is `SystemInfoCollector`; only `WindowsCollector` (FFI-based) is implemented.

### Riverpod usage

Widgets extend `ConsumerWidget` and use `ref.watch()` / `ref.read()`. The top-level `ProviderScope` wraps the app in `main.dart`. Page navigation uses `IndexedStack` with a `StateProvider<int>` for the current tab index — not the `AppRouter` in `app.dart` (which is a placeholder).

### Testing

No tests exist yet. When adding tests, place them in `test/` mirroring the `lib/` structure. Use `flutter test`.

## CI

Three workflows in `.github/workflows/`:
- **build.yml** — builds all 5 platforms on push/PR to main
- **release.yml** — triggered by `v*` tags; builds, packages (ZIP/DMG/tar.gz/APK), creates GitHub Release
- **cleanup.yml** — manual workflow to prune old CI runs

## Gotchas

- `pubspec.lock` is committed — always run `flutter pub get` after pulling, not `flutter pub upgrade` unless intentional
- `analysis_options.yaml` only includes `package:flutter_lints/flutter.yaml` — no custom lint rules
- The `AppRouter` in `app/app.dart` is dead code; actual navigation uses `IndexedStack` in `main.dart`
- `ServerService` defaults collector to `WindowsCollector()` — other platform collectors are not yet implemented (Roadmap item)
