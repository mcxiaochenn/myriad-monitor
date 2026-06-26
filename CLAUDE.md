# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 铁律（绝对不能违反）

1. **必须使用中文** — 所有交流、回复、解释一律使用中文，代码注释优先中文
2. **默认只 commit，绝对不要 push** — 完成修改后执行 `git commit` 即可，只有用户明确说「推送」或「push」时才执行 `git push`
3. **不确定就问，不要猜** — 任何不确定的事情都要先问用户，不要自作主张
4. **遵循 Conventional Commits** — commit message 格式：`feat: 新增 xxx`、`fix: 修复 xxx`、`docs: 更新 xxx`

## 项目概述

**Myriad (万镜)** — 去中心化的跨平台系统监控面板。设备间通过 IP 直连，每个实例既是 Server（采集数据）又是 Client（展示数据），无需中心服务器。

## 技术栈

- **框架**: Flutter 3.x (全平台: Windows / macOS / Linux / Android / iOS)
- **状态管理**: Riverpod
- **系统信息采集**: `system_info2` / `dart:ffi`
- **设备间通信**: WebSocket (`shelf` + `web_socket_channel`)
- **设备发现**: UDP 多播 (`dart:io` RawDatagramSocket)
- **图表渲染**: `fl_chart`
- **高斯模糊**: `BackdropFilter` + `ImageFilter.blur`
- **本地存储**: `hive` / `shared_preferences`
- **国际化**: 自定义 `AppLocalizations` (中文/英文)

## 常用命令

Flutter 路径：`D:\flutter\bin`

```bash
# 安装依赖
flutter pub get

# 运行应用
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d linux      # Linux
flutter run -d android    # Android
flutter run -d ios        # iOS

# 构建发布版
flutter build windows
flutter build macos
flutter build linux
flutter build apk         # Android APK
flutter build ios         # iOS

# 运行测试
flutter test
flutter test test/path/to/test.dart

# 代码分析
flutter analyze

# 格式化代码
dart format .
```

## 架构

```
┌─────────────────────────────────────────────────────────┐
│                      Myriad App                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Server 模块  │  │  Discovery   │  │   Client 模块 │  │
│  │ · 系统信息采集 │  │ · UDP 多播    │  │ · 设备列表    │  │
│  │ · WebSocket   │  │ · 设备发现    │  │ · 实时图表    │  │
│  │ · 数据推送    │  │ · 心跳检测    │  │ · 数据可视化  │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         └─────────────────┴─────────────────┘           │
│                    本地/网络通信                          │
└─────────────────────────────────────────────────────────┘
```

### 核心模块

- **Server 模块** (`lib/server/`): 采集系统指标（CPU、内存、磁盘、网络），通过 WebSocket 推送
  - `system_info_collector.dart`: 抽象接口
  - `windows_collector.dart`: Windows 平台实现（使用 dart:ffi）
  - `server_service.dart`: WebSocket 服务器

- **Discovery 模块** (`lib/core/discovery/`): 局域网设备自动发现
  - `discovery_service.dart`: 抽象接口
  - `udp_discovery.dart`: UDP 多播实现（地址 239.255.255.250:1900）
  - `discovery_integration.dart`: 与 DeviceManager 的集成层
  - `discovery_message.dart`: 消息格式（announce/heartbeat/heartbeat_ack）

- **Client 模块** (`lib/client/`): 设备管理和 WebSocket 客户端
  - `device_manager.dart`: 设备列表管理、离线检测
  - `client_service.dart`: WebSocket 客户端、心跳、重连

- **L10n 模块** (`lib/l10n/`): 国际化支持
  - `app_localizations.dart`: 中文/英文翻译
  - `locale_provider.dart`: 语言状态管理

### 页面

1. **主页 (Home)**: 设备卡片列表，支持排序（按时间/名称/状态/IP）
2. **服务端 (Server)**: 显示本机设备信息、WebSocket 服务状态、网络信息
3. **配置 (Settings)**: 服务器配置、设备发现开关、语言切换、数据清理
4. **关于 (About)**: 应用信息、技术栈（可跳转）、开发者信息（可跳转）

### 底栏导航

主页 → 服务端 → 配置 → 关于

## 代码风格

- 遵循 Dart/Flutter 规范
- 使用 Riverpod 状态管理
- 优先使用 `const` 构造函数
- UI 部分使用中文注释标注 widget 用途
- 所有用户可见文本必须通过 `AppLocalizations` 获取

## Git 规范

### Commit Message 格式

使用 Conventional Commits：

| 类型 | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | 修复 bug |
| `docs` | 文档变更 |
| `style` | 代码格式（不影响运行） |
| `refactor` | 重构 |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `chore` | 构建/工具变动 |
| `ci` | CI 配置变更 |
| `revert` | 回滚 |

### 操作规范

- **只 commit，不 push** — 用户审查后再决定是否推送
- 修改代码后运行 `flutter analyze` 验证
