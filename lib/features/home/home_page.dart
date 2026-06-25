import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/device_info.dart';
import 'device_card.dart';

/// 模拟设备数据 Provider（后续替换为真实数据源）
///
/// 返回一份示例设备列表，用于开发和调试阶段。
final deviceListProvider = Provider<List<DeviceInfo>>((ref) {
  return [
    const DeviceInfo(
      id: '1',
      name: '我的笔记本',
      ipAddress: '192.168.1.100',
      osType: DeviceOsType.windows,
      osVersion: '11',
      status: DeviceStatus.online,
    ),
    const DeviceInfo(
      id: '2',
      name: 'Mac Studio',
      ipAddress: '192.168.1.101',
      osType: DeviceOsType.macos,
      osVersion: '14',
      status: DeviceStatus.online,
    ),
    const DeviceInfo(
      id: '3',
      name: 'Ubuntu 服务器',
      ipAddress: '192.168.1.200',
      osType: DeviceOsType.linux,
      osVersion: '22.04',
      status: DeviceStatus.offline,
    ),
    const DeviceInfo(
      id: '4',
      name: '开发用树莓派',
      ipAddress: '192.168.1.50',
      osType: DeviceOsType.linux,
      osVersion: 'Debian 12',
      status: DeviceStatus.online,
    ),
  ];
});

/// 设备列表主页
///
/// 展示所有已发现的设备卡片列表，支持下拉刷新搜索新设备。
/// 每张卡片显示设备名称、操作系统和状态指示灯。
/// 点击卡片可导航至设备详情页。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceListProvider);

    return Scaffold(
      // 透明 AppBar，配合高斯模糊背景
      appBar: AppBar(
        title: const Text('万镜 · 设备列表'),
        centerTitle: true,
        actions: [
          // 搜索按钮（预留）
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现设备搜索功能
            },
            tooltip: '搜索设备',
          ),
          // 添加设备按钮（预留）
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // TODO: 实现手动添加设备功能
            },
            tooltip: '添加设备',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 高斯模糊背景层（预留位置）
          // 后续可替换为实时壁纸、渐变动画或设备截图拼贴
          _buildBlurredBackground(context),

          // 设备列表
          _buildDeviceList(context, devices),
        ],
      ),
    );
  }

  /// 构建高斯模糊背景
  ///
  /// 当前使用简单渐变占位，后续可接入设备截图或动态背景。
  Widget _buildBlurredBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerLow,
          ],
        ),
      ),
      // 预留 BackdropFilter 高斯模糊位置
      // child: BackdropFilter(
      //   filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      //   child: Container(color: Colors.transparent),
      // ),
    );
  }

  /// 构建设备列表主体
  Widget _buildDeviceList(BuildContext context, List<DeviceInfo> devices) {
    if (devices.isEmpty) {
      return _buildEmptyState(context);
    }

    // 统计在线设备数
    final onlineCount = devices.where((d) => d.isOnline).length;

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: 触发设备重新发现
        await Future<void>.delayed(const Duration(seconds: 1));
      },
      child: CustomScrollView(
        slivers: [
          // 顶部统计信息
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.device_hub,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '共 ${devices.length} 台设备，$onlineCount 台在线',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),

          // 设备卡片列表
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final device = devices[index];
                return DeviceCard(
                  device: device,
                  onTap: () => _navigateToDetail(context, device),
                );
              },
              childCount: devices.length,
            ),
          ),

          // 底部留白
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  /// 空状态视图 —— 暂未发现任何设备
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '暂未发现设备',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '请确保其他设备在同一局域网内',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // TODO: 触发手动设备发现
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重新搜索'),
          ),
        ],
      ),
    );
  }

  /// 导航到设备详情页
  ///
  /// 当前使用 SnackBar 作为占位提示，待详情页实现后替换为 Navigator.push。
  void _navigateToDetail(BuildContext context, DeviceInfo device) {
    // TODO: 替换为真实的详情页路由
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('即将打开 ${device.name} 的监控面板'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
