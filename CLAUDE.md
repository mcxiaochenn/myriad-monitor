# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Myriad (万镜)** — A decentralized, cross-platform system monitoring dashboard. Devices connect directly via IP, each instance acts as both Server (data collection) and Client (visualization). No central server required.

## Tech Stack

- **Framework**: Flutter 3.x (Desktop: Windows / macOS / Linux)
- **State Management**: Riverpod
- **System Info**: `system_info2` / `dart:ffi` for native API calls
- **Communication**: WebSocket (`shelf` + `web_socket_channel`)
- **Charts**: `fl_chart`
- **Blur Effects**: `BackdropFilter` + `ImageFilter.blur`
- **Local Storage**: `hive` / `shared_preferences`

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run desktop app (Windows)
flutter run -d windows

# Run desktop app (macOS)
flutter run -d macos

# Run desktop app (Linux)
flutter run -d linux

# Build release
flutter build windows
flutter build macos
flutter build linux

# Run tests
flutter test

# Run single test file
flutter test test/path/to/test.dart

# Analyze code
flutter analyze

# Format code
dart format .
```

## Architecture

```
┌─────────────────────────────────────────┐
│              Myriad App                 │
│  ┌──────────────┐  ┌──────────────────┐ │
│  │  Server 模块  │  │   Client 模块    │ │
│  │ · 系统信息采集 │  │ · 设备列表主页   │ │
│  │ · 实时数据推送 │  │ · 实时图表详情页 │ │
│  │ · WebSocket   │  │ · 数据可视化     │ │
│  └──────┬───────┘  └────────┬─────────┘ │
│         └───── 本地/网络 ────┘           │
└─────────────────────────────────────────┘
```

### Key Modules

- **Server Module**: Collects system metrics (CPU, memory, GPU, disk, network) and pushes via WebSocket
- **Client Module**: Displays device list and real-time monitoring charts
- **Each instance is both**: Can monitor other devices and be monitored

### Pages

1. **Home (设备列表页)**: Device cards with name, OS, status indicator; Gaussian blur background
2. **Detail (设备详情页)**: Real-time charts for CPU, memory, GPU, disk, network

## Code Style

- Follow Dart/Flutter conventions
- Use Riverpod for state management
- Prefer `const` constructors where possible
- Use meaningful widget names in Chinese comments for UI sections
