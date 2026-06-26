# Myriad — 万镜

> 取"万物皆可观、镜照万千端"之意。每台设备是一面镜子，互相映照，无需中心。

**去中心化的跨平台系统监控面板，设备间 IP 直连，一端采集一端渲染。**

<p align="left">
  <img src="https://img.shields.io/github/license/mcxiaochenn/myriad-monitor" alt="License">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue" alt="Flutter">
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
| **视觉体验** | 高斯模糊背景、连续曲率圆角、流畅动画 |

## 技术架构

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

设备 A (Myriad) ◄──── IP 直连 ────► 设备 B (Myriad)
   Server+Client                      Server+Client
```

## 页面说明

**主页 (Home)**
- 已发现的设备卡片列表
- 支持排序：按添加时间、名称、在线状态、IP 地址
- 高斯模糊背景 + 连续曲率圆角卡片
- 点击进入设备详情

**服务端 (Server)**
- 显示本机设备信息（设备名称、操作系统、主机名）
- WebSocket 服务运行状态
- 网络信息（本机 IP 地址）
- 已连接客户端数量

**配置 (Settings)**
- 服务器端口、地址、推送间隔配置
- 设备发现开关
- 语言切换（跟随系统 / 中文 / 英文）
- 数据清理

**关于 (About)**
- 应用信息和版本
- 功能特性介绍
- 技术栈（可跳转）
- 开发者信息（可跳转）

## 技术选型

| 层 | 方案 |
|---|---|
| **UI 框架** | Flutter 3.x |
| **状态管理** | Riverpod |
| **系统信息采集** | `system_info2` / `dart:ffi` 调用原生 API |
| **设备间通信** | WebSocket (`shelf` + `web_socket_channel`) |
| **设备发现** | UDP 多播 (`dart:io` RawDatagramSocket) |
| **图表渲染** | `fl_chart` |
| **高斯模糊** | `BackdropFilter` + `ImageFilter.blur` |
| **本地存储** | `hive` / `shared_preferences` |
| **国际化** | 自定义 `AppLocalizations` |

## 快速开始

**环境要求**
- Flutter 3.x
- Dart 3.x
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
flutter build windows
flutter build macos
flutter build linux

# 移动端
flutter build apk         # Android APK
flutter build ios         # iOS
```

## Roadmap

- [x] 基础框架搭建
- [x] 系统信息采集模块（Windows 平台）
- [x] WebSocket 通信层
- [x] 设备列表页 UI
- [x] 设备详情页 UI
- [x] 实时图表渲染
- [x] 设备自动发现（UDP 多播）
- [x] 高斯模糊视觉效果
- [x] 国际化支持（中文/英文）
- [x] 服务端配置页面
- [x] 关于页面
- [ ] 系统信息采集（macOS/Linux/Android/iOS 平台）
- [ ] 设备详情页数据对接
- [ ] 历史数据存储和图表

## 贡献

欢迎提交 Issue 和 Pull Request。

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/xxx`)
3. 提交更改 (`git commit -m 'Add xxx'`)
4. 推送分支 (`git push origin feature/xxx`)
5. 打开 Pull Request

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
