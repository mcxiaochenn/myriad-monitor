import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../client/device_manager.dart';
import '../../core/discovery/udp_discovery.dart';
import '../../core/discovery/discovery_integration.dart';
import 'device_card.dart';

/// 设备管理器 Provider
final deviceManagerProvider = Provider<DeviceManager>((ref) {
  final manager = DeviceManager();
  // 启动离线检测
  manager.startOfflineDetection();
  // 释放时停止检测
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// 设备发现集成服务 Provider
final discoveryIntegrationProvider = Provider<DiscoveryIntegration>((ref) {
  final deviceManager = ref.read(deviceManagerProvider);
  final discoveryService = UdpDiscoveryService(
    deviceName: 'Myriad Monitor',
    servicePort: 8080,
  );

  final integration = DiscoveryIntegration(
    discoveryService: discoveryService,
    deviceManager: deviceManager,
  );

  // 启动集成服务
  integration.start();

  // 释放时停止服务
  ref.onDispose(() => integration.dispose());
  return integration;
});

/// 设备列表 Provider
final deviceListProvider = Provider<List<ManagedDevice>>((ref) {
  // 监听设备发现集成服务，确保设备列表更新时触发刷新
  ref.watch(discoveryIntegrationProvider);
  final manager = ref.watch(deviceManagerProvider);
  return manager.devices;
});

/// 设备列表主页
///
/// 展示所有已发现的设备卡片列表，支持下拉刷新搜索新设备。
/// 每张卡片显示设备名称、IP 地址和状态指示灯。
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
          // 高斯模糊背景
          _buildBlurredBackground(context),

          // 设备列表
          _buildDeviceList(context, devices),
        ],
      ),
    );
  }

  /// 构建高斯模糊背景
  Widget _buildBlurredBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withValues(alpha: 0.1),
                colorScheme.surface,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建设备列表主体
  Widget _buildDeviceList(BuildContext context, List<ManagedDevice> devices) {
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
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
  void _navigateToDetail(BuildContext context, ManagedDevice device) {
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
