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
- **图表渲染**: `fl_chart`
- **高斯模糊**: `BackdropFilter` + `ImageFilter.blur`
- **本地存储**: `hive` / `shared_preferences`

## 常用命令

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

### 核心模块

- **Server 模块**: 采集系统指标（CPU、内存、GPU、磁盘、网络），通过 WebSocket 推送
- **Client 模块**: 展示设备列表和实时监控图表
- **每个实例都是双向的**: 可以监控其他设备，也可以被其他设备监控

### 页面

1. **设备列表页 (Home)**: 设备卡片，显示设备名、OS、状态指示灯，高斯模糊背景
2. **设备详情页 (Detail)**: CPU、内存、GPU、磁盘、网络的实时图表

## 代码风格

- 遵循 Dart/Flutter 规范
- 使用 Riverpod 状态管理
- 优先使用 `const` 构造函数
- UI 部分使用中文注释标注 widget 用途

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
