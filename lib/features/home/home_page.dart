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

/// 搜索关键词 Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 设备列表 Provider（支持搜索过滤）
final deviceListProvider = Provider<List<ManagedDevice>>((ref) {
  // 监听设备发现集成服务，确保设备列表更新时触发刷新
  ref.watch(discoveryIntegrationProvider);
  final manager = ref.watch(deviceManagerProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  final devices = manager.devices;

  // 如果搜索关键词为空，返回所有设备
  if (searchQuery.isEmpty) {
    return devices;
  }

  // 过滤设备列表
  final query = searchQuery.toLowerCase();
  return devices.where((device) {
    return device.name.toLowerCase().contains(query) ||
        device.ipAddress.contains(query);
  }).toList();
});

/// 设备列表主页
///
/// 展示所有已发现的设备卡片列表，支持搜索和手动添加设备。
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
          // 搜索按钮
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, ref),
            tooltip: '搜索设备',
          ),
          // 添加设备按钮
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddDeviceDialog(context, ref),
            tooltip: '添加设备',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 高斯模糊背景
          _buildBlurredBackground(context),

          // 设备列表
          _buildDeviceList(context, ref, devices),
        ],
      ),
    );
  }

  /// 显示搜索对话框
  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _SearchDialog(
        onSearch: (query) {
          ref.read(searchQueryProvider.notifier).state = query;
        },
        initialQuery: ref.read(searchQueryProvider),
      ),
    );
  }

  /// 显示添加设备对话框
  void _showAddDeviceDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _AddDeviceDialog(
        onAdd: (name, ip, port) {
          final manager = ref.read(deviceManagerProvider);
          final device = ManagedDevice(
            deviceId: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            ipAddress: ip,
            port: port,
            onlineStatus: DeviceOnlineStatus.unknown,
            discoveredAt: DateTime.now(),
          );
          manager.addDevice(device);

          // 显示成功提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已添加设备: $name'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
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
  Widget _buildDeviceList(
      BuildContext context, WidgetRef ref, List<ManagedDevice> devices) {
    if (devices.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    // 统计在线设备数
    final onlineCount = devices.where((d) => d.isOnline).length;
    final searchQuery = ref.watch(searchQueryProvider);

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
                    searchQuery.isNotEmpty
                        ? '搜索结果: ${devices.length} 台设备'
                        : '共 ${devices.length} 台设备，$onlineCount 台在线',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (searchQuery.isNotEmpty) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                      child: const Text('清除搜索'),
                    ),
                  ],
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
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final searchQuery = ref.watch(searchQueryProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isNotEmpty ? Icons.search_off : Icons.devices_other,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty ? '未找到匹配的设备' : '暂未发现设备',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? '请尝试其他关键词'
                : '请确保其他设备在同一局域网内',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),
          if (searchQuery.isNotEmpty)
            FilledButton.icon(
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
              },
              icon: const Icon(Icons.clear),
              label: const Text('清除搜索'),
            )
          else
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

/// 搜索对话框
class _SearchDialog extends StatefulWidget {
  final Function(String) onSearch;
  final String initialQuery;

  const _SearchDialog({
    required this.onSearch,
    required this.initialQuery,
  });

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('搜索设备'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '输入设备名称或 IP 地址',
          prefixIcon: Icon(Icons.search),
        ),
        onSubmitted: (value) {
          widget.onSearch(value);
          Navigator.of(context).pop();
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onSearch('');
            Navigator.of(context).pop();
          },
          child: const Text('清除'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSearch(_controller.text);
            Navigator.of(context).pop();
          },
          child: const Text('搜索'),
        ),
      ],
    );
  }
}

/// 添加设备对话框
class _AddDeviceDialog extends StatefulWidget {
  final Function(String name, String ip, int port) onAdd;

  const _AddDeviceDialog({required this.onAdd});

  @override
  State<_AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<_AddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8080');

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加设备'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '设备名称',
                hintText: '例如: 我的笔记本',
                prefixIcon: Icon(Icons.devices),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入设备名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP 地址',
                hintText: '例如: 192.168.1.100',
                prefixIcon: Icon(Icons.language),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入 IP 地址';
                }
                // 简单的 IP 地址格式验证
                final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
                if (!ipRegex.hasMatch(value)) {
                  return '请输入有效的 IP 地址';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: '端口号',
                hintText: '默认 8080',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入端口号';
                }
                final port = int.tryParse(value);
                if (port == null || port < 1 || port > 65535) {
                  return '请输入有效的端口号 (1-65535)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onAdd(
                _nameController.text,
                _ipController.text,
                int.parse(_portController.text),
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}
