# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 铁律（绝对不能违反）

1. **必须使用中文** — 所有交流、回复、解释一律使用中文，代码注释优先中文
2. **默认只 commit，绝对不要 push** — 完成修改后执行 `git commit` 即可，只有用户明确说「推送」或「push」时才执行 `git push`
3. **不确定就问，不要猜** — 任何不确定的事情都要先问用户，不要自作主张
4. **遵循 Conventional Commits** — commit message 格式：`feat: 新增 xxx`、`fix: 修复 xxx`、`docs: 更新 xxx`

## 项目概述

**Myriad (万镜)** — 去中心化的跨平台系统监控面板。设备间通过 IP 直连，每个实例既是 Server（采集数据）又是 Client（展示数据），无需中心服务器。

## 常用命令

Flutter 路径：`D:\flutter\bin`

```bash
flutter pub get                     # 安装依赖
flutter run -d windows              # Windows 运行
flutter build windows               # Windows 构建
flutter analyze                     # 代码分析（修改代码后必须运行）
dart format .                       # 格式化代码
flutter test                        # 运行所有测试
flutter test test/path/to/test.dart # 运行单个测试
```

## 架构要点

### 三层核心模块

```
Server (lib/server/)  ←→  Discovery (lib/core/discovery/)  ←→  Client (lib/client/)
采集系统指标               UDP 多播发现设备                    管理设备列表
WebSocket 推送数据         心跳维持在线状态                    WebSocket 接收数据
```

**数据流**：Server 采集 → WebSocket 推送 → Client 接收 → DeviceManager 更新 → UI 刷新

### 模块间关键依赖

- `DiscoveryIntegration` 是 Discovery 和 DeviceManager 的桥梁，监听设备发现/离线事件并转发
- `ServerService` 使用 `SystemInfoCollector` 采集数据，通过 `shelf` WebSocket 广播
- `ClientService` 连接远程 WebSocket，接收 `SystemInfoData` 并通过 Stream 推送
- `DeviceManager` 管理所有设备状态，提供离线检测（30秒超时）

### 两套数据模型（注意区分）

1. **Server 侧** (`lib/server/system_info_collector.dart`)：`SystemInfo` / `DiskInfo` / `NetworkTraffic` — 用于采集和 WebSocket 推送
2. **Core 模型** (`lib/core/models/system_metrics.dart`)：`SystemMetrics` / `CpuMetrics` / `MemoryMetrics` 等 — 用于 UI 展示和详细指标

两套模型的 JSON 字段命名风格不同（Server 用 camelCase，Core 用 snake_case）。

### 状态管理 (Riverpod)

- 所有 Provider 定义在各自页面文件中（非集中管理）
- `serverConfigProvider` — 服务器配置（端口、地址、推送间隔等）
- `serverStatusProvider` — 服务运行状态
- `deviceIdProvider` — 设备唯一 ID（UUID v4，首次生成后持久化）
- `localeProvider` — 语言设置
- `currentPageIndexProvider` — 底栏导航当前页

### 国际化

- 自定义 `AppLocalizations`（非 Flutter 官方 intl），通过 `locale.languageCode` switch 实现中/英文
- 所有用户可见文本必须通过 `AppLocalizations.of(context)` 获取
- 添加新翻译：在 `lib/l10n/app_localizations.dart` 中添加 getter

### 设备发现协议

UDP 多播地址 `239.255.255.250:1900`，三种消息类型：
- `announce` — 设备上线公告
- `heartbeat` — 心跳检测
- `heartbeat_ack` — 心跳确认

## 代码风格

- 优先使用 `const` 构造函数
- UI 注释用中文标注 widget 用途
- 常量类使用私有构造函数 `ClassName._()` 防止实例化
- 模型类实现 `fromJson` / `toJson` / `copyWith` 三件套
- 资源释放统一使用 `dispose()` 方法，关闭 Stream 和 Timer

## CI/CD

GitHub Actions 工作流（`.github/workflows/`）：
- `build.yml` — Push/PR 到 main 时自动构建全平台（Windows/Android/macOS/Linux/iOS）
- `release.yml` — 发布工作流
- `cleanup.yml` — 清理工作流

CI 中使用 `flutter create --project-name myriad_monitor --platforms <平台> .` 生成平台目录。

## Git 规范

使用 Conventional Commits：`feat` / `fix` / `docs` / `style` / `refactor` / `perf` / `test` / `chore` / `ci` / `revert`

**只 commit，不 push** — 用户审查后再决定是否推送。修改代码后运行 `flutter analyze` 验证。
