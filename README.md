# Myriad — 万镜

> 取"万物皆可观、镜照万千端"之意。每台设备是一面镜子，互相映照，无需中心。

**去中心化的跨平台系统监控面板，设备间 IP 直连，一端采集一端渲染。**

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

## 核心特性

| 特性 | 说明 |
|---|---|
| **去中心化** | 无中心服务器，设备间通过 IP 直连通信 |
| **客户端服务端同体** | 每个实例既是 Server（采集数据）又是 Client（展示数据） |
| **跨平台** | Windows / macOS / Linux / Android / iOS，Flutter 一套代码 |
| **实时监控** | CPU、内存、磁盘、网络等常见指标，实时图表渲染 |
| **设备自动发现** | UDP 多播协议，局域网设备自动发现 |
| **国际化** | 支持中文和英文，跟随系统语言 |
| **主题切换** | 支持浅色/深色/自动（跟随系统），偏好持久化 |
| **视觉体验** | 高斯模糊背景、连续曲率圆角、流畅动画 |

## 技术架构

```
┌─────────────────────────────────────────────────────────┐
│                      Myriad App                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Server 模块  │  │  Discovery   │  │   Client 模块 │  │
│  │ · 系统信息采集 │  │ · UDP 多播    │  │ · 设备列表    │  │
│  │ · HTTP API    │  │ · 设备发现    │  │ · 实时图表    │  │
│  │ · JSON 响应   │  │ · 心跳检测    │  │ · 数据可视化  │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         └─────────────────┴─────────────────┘           │
│                    本地/网络通信                          │
└─────────────────────────────────────────────────────────┘

设备 A (Myriad) ◄──── IP 直连 ────► 设备 B (Myriad)
   Server+Client                      Server+Client
```

## 技术选型

| 层 | 方案 |
|---|---|
| **UI 框架** | Flutter 3.x |
| **状态管理** | Riverpod |
| **系统信息采集** | `system_info2` / `dart:ffi` 调用原生 API |
| **设备间通信** | HTTP API (`shelf`)，SHA256 令牌鉴权，客户端轮询拉取 |
| **设备发现** | UDP 多播 (`dart:io` RawDatagramSocket) |
| **图表渲染** | `fl_chart` |
| **高斯模糊** | `BackdropFilter` + `ImageFilter.blur` |
| **本地存储** | `hive` / `shared_preferences` |
| **国际化** | 自定义 `AppLocalizations` |

## 快速开始

**环境要求**
- Flutter 3.x / Dart 3.x
- 桌面端: Windows 10+ / macOS 10.15+ / Linux (X11/Wayland)
- 移动端: Android 6.0+ / iOS 12.0+

**安装与运行**

```bash
git clone https://github.com/mcxiaochenn/myriad-monitor.git
cd myriad-monitor
flutter pub get

# 桌面端
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d linux      # Linux

# 移动端
flutter run -d android    # Android
flutter run -d ios        # iOS
```

**构建发布版**

```bash
# 桌面端
flutter build windows     # Windows (便携版)
flutter build macos       # macOS (DMG)
flutter build linux       # Linux (tar.gz)

# 移动端
flutter build apk         # Android APK
flutter build ios         # iOS
```

## 下载

前往 [Releases](https://github.com/mcxiaochenn/myriad-monitor/releases) 页面下载最新版本。

所有发布文件遵循统一命名：`myriad-monitor-v{版本名}_{版本码}-{平台}.{格式}`，如 `myriad-monitor-v1.0.0_1-windows-portable.zip`。版本名从 `pubspec.yaml` 读取，版本码根据 git 提交历史自动计算。

| 平台 | 格式 | 说明 |
|------|------|------|
| Windows | `.exe` 安装包 | 标准安装 |
| Windows | `.zip` 便携版 | 解压即用 |
| macOS | `.dmg` | DMG 安装包 |
| Linux | `.tar.gz` | tar.gz 包 |
| Android | `.apk` | 正式版 / 测试版 |

## 项目结构

```
lib/
├── app/                    # 应用配置
│   └── app.dart           # 主题配置
├── core/                   # 核心模块
│   ├── constants.dart     # 常量定义
│   ├── discovery/         # 设备发现
│   │   ├── udp_discovery.dart
│   │   ├── discovery_service.dart
│   │   └── discovery_integration.dart
│   ├── models/            # 数据模型
│   │   ├── device_info.dart
│   │   └── system_metrics.dart
│   └── storage/           # 本地存储
│       ├── device_storage.dart
│       └── settings_storage.dart
├── client/                 # 客户端模块
│   ├── client_service.dart
│   └── device_manager.dart
├── server/                 # 服务端模块
│   ├── server_service.dart
│   ├── system_info_collector.dart
│   └── windows_collector.dart
├── features/               # 功能页面
│   ├── home/              # 主页
│   ├── detail/            # 设备详情
│   ├── server/            # 服务端状态
│   ├── settings/          # 设置
│   └── about/             # 关于
└── l10n/                   # 国际化
    ├── app_localizations.dart
    └── locale_provider.dart
```

## Roadmap

- [x] 基础框架搭建
- [x] 系统信息采集模块（Windows 平台）
- [x] HTTP 通信层（SHA256 令牌鉴权）
- [x] 设备列表页 UI
- [x] 设备详情页 UI
- [x] 实时图表渲染
- [x] 设备自动发现（UDP 多播）
- [x] 高斯模糊视觉效果
- [x] 国际化支持（中文/英文）
- [x] 服务端配置页面
- [x] 关于页面
- [x] 设备数据持久化
- [x] 深浅色主题切换（自动/浅色/深色）
- [x] SHA256 访问令牌管理
- [ ] 系统信息采集（macOS/Linux/Android/iOS 平台）
- [ ] 设备详情页数据对接
- [ ] 历史数据存储和图表

## 贡献

欢迎提交 Issue 和 Pull Request。

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/xxx`)
3. 提交更改 (`git commit -m 'feat: Add xxx'`)
4. 推送分支 (`git push origin feature/xxx`)
5. 打开 Pull Request

请遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范提交代码。

## 许可证

MIT License - 详见 [LICENSE](LICENSE)

## Star History

<a href="https://star-history.com/#mcxiaochenn/myriad-monitor&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=mcxiaochenn/myriad-monitor&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=mcxiaochenn/myriad-monitor&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=mcxiaochenn/myriad-monitor&type=Date" />
 </picture>
</a>
