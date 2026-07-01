# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 铁律（绝对不能违反）

1. **必须使用中文** — 所有交流、回复、解释一律使用中文，代码注释优先中文
2. **默认只 commit，绝对不要 push** — 只有用户明确说「推送」或「push」时才执行 `git push`
3. **不要主动触发 CI/Release** — 只有用户明确说「触发Release」等词时才执行 `gh workflow run`
4. **不确定就问，不要猜** — 任何不确定的事情都要先问用户，不要自作主张
5. **遵循 Conventional Commits** — 格式：`feat:` / `fix:` / `docs:` / `refactor:` / `chore:` / `ci:` 等

## 项目概述

**Myriad (万镜)** — 去中心化的跨平台系统监控面板。设备间通过 IP 直连，每个实例既是 Server（采集数据）又是 Client（展示数据），无需中心服务器。

## 常用命令

Flutter 路径：`D:\flutter\bin`

```bash
flutter pub get                     # 安装依赖
flutter run -d windows              # Windows 运行
flutter build windows               # Windows 构建
dart analyze lib/                   # 代码分析（修改代码后必须运行，用 dart 而非 flutter 避免 LSP 崩溃）
flutter test                        # 运行所有测试
```

## 架构要点

### 三层核心模块

```
Server (lib/server/)  ←→  Discovery (lib/core/discovery/)  ←→  Client (lib/client/)
采集系统指标               UDP 多播发现设备                    管理设备列表
HTTP API 返回 JSON         心跳维持在线状态                    HTTP 轮询拉取数据
```

**数据流**：Server 采集 → HTTP GET `/{deviceId}/{accessToken}` → Client 轮询 → DeviceManager 更新 → UI 刷新

### 模块间关键依赖

- `ServerService` 使用 `shelf` 启动 HTTP 服务器，路由 `GET /{deviceId}/{token}` 返回系统信息 JSON。token 校验失败返回 403
- **SHA256 访问令牌**：`lib/core/access_token.dart` — 32 字节安全随机数 + SHA256 生成 64 位 HEX，持久化到 SharedPreferences。`accessTokenProvider`（Riverpod）全局访问，`resetAccessToken()` 重置
- `ClientService` 通过 `dart:io` HttpClient 周期 GET（默认 1 秒）拉取远端 JSON，解析为 `SystemInfoData` 后通过 Stream 推送
- `DiscoveryIntegration` 是 Discovery 和 DeviceManager 的桥梁。发现设备时从 UDP 消息中提取设备信息（IP/端口/名称），`accessToken` 通过 QR 码/手动输入等带外方式获取，不在多播中传输
- `DeviceManager` 管理所有设备状态，30 秒超时离线检测。设备通过 `httpUrl`（格式 `http://ip:port/deviceId/token`）访问

### 数据模型

1. **Server 侧** (`lib/server/system_info_collector.dart`)：`SystemInfo` / `DiskInfo` / `NetworkTraffic` — camelCase，采集 + HTTP 响应用
2. **Client 侧** (`lib/client/client_service.dart`)：`SystemInfoData` / `DiskInfoData` — 从 HTTP 响应 JSON 解析，字段与 Server 侧对齐，额外包含 `deviceId`/`deviceName`；`fromJson` 兼容嵌套 `networkTraffic` 和扁平格式

两套模型 JSON 命名统一为 camelCase。

### 状态管理 (Riverpod)

Provider 定义在各自模块文件中（非集中管理）：

| Provider | 位置 | 用途 |
|----------|------|------|
| `serverConfigProvider` | `settings_page.dart` | 服务器配置（端口/地址/推送间隔等），SharedPreferences 持久化 |
| `serverStatusProvider` | `server_page.dart` | 服务运行状态，管理 ServerService 启停 |
| `deviceIdProvider` | `server_page.dart` | 设备 UUID v4，首次生成后持久化 |
| `localeProvider` + `languageModeProvider` | `locale_provider.dart` | 语言设置（system/zh/en），SharedPreferences 持久化 |
| `themeModeProvider` | `theme_provider.dart` | 主题模式（system/light/dark），SharedPreferences 持久化 |
| `accessTokenProvider` | `access_token.dart` | SHA256 访问令牌，首次自动生成 |
| `currentPageIndexProvider` | `main.dart` | 底栏导航当前页 |

### 国际化

- 自定义 `AppLocalizations`（非 Flutter 官方 intl），`locale.languageCode` switch 实现中/英
- 所有用户可见文本必须通过 `AppLocalizations.of(context)` 获取
- 新增翻译：在 `lib/l10n/app_localizations.dart` 中按 `// ==== 区域名 ====` 分块添加 getter

### 设备发现协议

UDP 多播 `224.0.0.0:53317`（LocalSend 兼容），三种消息类型：
- `announce` — 上线公告（启动阶段 5 次 × 3 秒间隔）
- `heartbeat` — 心跳（30 秒间隔，90 秒超时离线）
- `heartbeat_ack` — 心跳确认

发现消息 JSON（snake_case）：`type`, `device_id`, `device_name`, `ip`, `port`, `os`, `timestamp`

注意：`access_token` 不通过多播传输，由 QR 码/手动输入等带外方式交换。

### Android 应用名国际化

- `android/app/src/main/AndroidManifest.xml` — `android:label="@string/app_name"`
- `res/values/strings.xml` → "Myriad Monitor"（非中文默认）
- `res/values-zh/strings.xml` → "万镜"（中文系统）
- CI 中 `flutter create` 不会覆盖已存在的这些文件

## 代码风格

- 优先 `const` 构造函数
- 常量类用 `ClassName._()` 私有构造防止实例化
- 模型类实现 `fromJson` / `toJson`
- 资源释放统一 `dispose()`，关闭 Stream 和 Timer

## 版本管理

- 版本名：`pubspec.yaml` 的 `version` 字段（`x.y.z+N`，`+N` 为占位符）
- 版本码：CI 中 `10001 + git rev-list --count HEAD`（幂等，不写文件）
- 编译注入：`--dart-define=APP_VERSION=... --dart-define=APP_BUILD_NUMBER=...`
- App 内读取：`String.fromEnvironment('APP_VERSION', defaultValue: 'dev')`（`lib/core/constants.dart`）
- 文件命名：`myriad-monitor-v{版本名}_{版本码}-{平台}.{格式}`

## CI/CD

GitHub Actions（`.github/workflows/`）：

```
build-platform.yml   ← 可复用构建，接收 platform 参数，自动选 runner
build.yml            ← version → 5 个 build → 5 个 package → bundle-waa
release.yml          ← resolve → 5 个 build → 5 个 package → create-release
cleanup.yml          ← 旧 artifacts 清理
```

构建脚本（`.github/scripts/`）：
- `build.sh` — 统一构建，`bash .github/scripts/build.sh <platform>`
- `package.sh` — 统一打包，`bash .github/scripts/package.sh <platform>`

改构建逻辑只改 `build.sh`，改打包逻辑只改 `package.sh`，YAML 只做调度。

CI 构建用 `flutter create --project-name myriad_monitor --platforms <平台> .` 生成平台目录。

## Git 规范

- **只 commit，不 push** — 用户审查后再决定
- 修改代码后必须运行 `dart analyze lib/` 验证（用 `dart` 而非 `flutter analyze` 避免 LSP 解析崩溃）
