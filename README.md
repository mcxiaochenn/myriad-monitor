# Myriad — 万镜

> 万镜：取"万物皆可观、镜照万千端"之意。每台设备是一面镜子，互相映照，无需中心。

**去中心化的跨平台系统监控面板，设备间 IP 直连，一端采集一端渲染。**

<p align="left">
  <img src="https://img.shields.io/github/license/mcxiaochenn/myriad-monitor" alt="License">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue" alt="Flutter">
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey" alt="Platform">
</p>

## 核心特性

| 特性 | 说明 |
|---|---|
| **去中心化** | 无中心服务器，设备间通过 IP 直连通信 |
| **客户端服务端同体** | 每个实例既是 Server（采集数据）又是 Client（展示数据） |
| **跨平台** | Windows / macOS / Linux 桌面端，Flutter 一套代码 |
| **实时监控** | CPU、内存、GPU、磁盘、网络等常见指标，实时图表渲染 |
| **视觉体验** | 高斯模糊背景、连续曲率圆角、流畅动画 |

## 技术架构

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

设备 A (Myriad) ◄──── IP 直连 ────► 设备 B (Myriad)
   Server+Client                      Server+Client
```

每台运行 Myriad 的设备都是一个独立节点，既能采集本机数据供其他设备查看，也能连接到其他设备实时查看其状态。

## 页面规划

**设备列表页 (Home)**
- 已发现的设备卡片列表
- 每张卡片: 设备名 / OS / 状态指示灯
- 高斯模糊背景 + 连续曲率圆角卡片
- 点击进入设备详情

**设备详情页 (Detail)**
- 顶部: 设备基本信息 (主机名/OS/运行时长)
- CPU: 使用率实时曲线 + 核心负载柱状图
- 内存: 已用/总量 + 实时曲线
- GPU: 型号/温度/显存/利用率
- 磁盘: 各分区容量 + 读写速率
- 网络: 上下行速率实时曲线

## 技术选型

| 层 | 方案 |
|---|---|
| **UI 框架** | Flutter 3.x (Desktop) |
| **状态管理** | Riverpod |
| **系统信息采集** | `system_info2` / `dart:ffi` 调用原生 API |
| **设备间通信** | WebSocket (`shelf` + `web_socket_channel`) |
| **图表渲染** | `fl_chart` |
| **高斯模糊** | `BackdropFilter` + `ImageFilter.blur` |
| **本地存储** | `hive` / `shared_preferences` |

## 快速开始

**环境要求**
- Flutter 3.x
- Dart 3.x
- Windows 10+ / macOS 10.15+ / Linux (X11/Wayland)

**安装与运行**

```bash
git clone https://github.com/mcxiaochenn/myriad-monitor.git
cd myriad-monitor
flutter pub get
flutter run -d windows  # 或 macos / linux
```

**构建发布版**

```bash
flutter build windows  # 或 macos / linux
```

## Roadmap

- [ ] 基础框架搭建
- [ ] 系统信息采集模块
- [ ] WebSocket 通信层
- [ ] 设备列表页 UI
- [ ] 设备详情页 UI
- [ ] 实时图表渲染
- [ ] 设备自动发现
- [ ] 高斯模糊视觉效果

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
