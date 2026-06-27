import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../client/device_manager.dart';
import '../../core/discovery/discovery_message.dart';
import '../../core/discovery/udp_discovery.dart';
import '../../core/discovery/discovery_integration.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_page.dart';
import '../detail/detail_page.dart';
import 'device_card.dart';

/// 设备管理器 Provider
final deviceManagerProvider = Provider<DeviceManager>((ref) {
  final manager = DeviceManager();
  manager.loadDevices();
  manager.startOfflineDetection();
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// 设备发现集成服务 Provider
final discoveryIntegrationProvider = Provider<DiscoveryIntegration>((ref) {
  final deviceManager = ref.read(deviceManagerProvider);
  final config = ref.read(serverConfigProvider);

  final discoveryService = UdpDiscoveryService(
    deviceName: config.deviceName,
    servicePort: config.port,
  );

  final integration = DiscoveryIntegration(
    discoveryService: discoveryService,
    deviceManager: deviceManager,
  );

  integration.start();
  ref.onDispose(() {
    discoveryService.dispose();
    integration.dispose();
  });
  return integration;
});

/// 排序方式枚举
enum SortType {
  /// 按添加时间排序
  time,

  /// 按名称排序
  name,

  /// 按在线状态排序
  status,

  /// 按 IP 地址排序
  ip,
}

/// 排序方向
enum SortDirection {
  /// 升序
  ascending,

  /// 降序
  descending,
}

/// 排序状态 Provider
final sortStateProvider = StateProvider<SortState>((ref) {
  return SortState();
});

/// 排序状态
class SortState {
  final SortType type;
  final SortDirection direction;

  SortState({
    this.type = SortType.time,
    this.direction = SortDirection.descending,
  });

  SortState copyWith({
    SortType? type,
    SortDirection? direction,
  }) {
    return SortState(
      type: type ?? this.type,
      direction: direction ?? this.direction,
    );
  }
}

/// 设备列表 Provider（响应式 + 排序）
final deviceListProvider =
    StateNotifierProvider<DeviceListNotifier, List<ManagedDevice>>((ref) {
  final manager = ref.watch(deviceManagerProvider);
  return DeviceListNotifier(manager);
});

/// 设备列表状态管理
class DeviceListNotifier extends StateNotifier<List<ManagedDevice>> {
  final DeviceManager _manager;
  final List<StreamSubscription> _subscriptions = [];

  DeviceListNotifier(this._manager) : super(_manager.devices) {
    _subscriptions.add(
      _manager.devicesChangedStream.listen((devices) {
        state = List.unmodifiable(devices);
      }),
    );
    _subscriptions.add(
      _manager.deviceStatusStream.listen((_) {
        state = List.unmodifiable(_manager.devices);
      }),
    );
  }

  void addDevice(ManagedDevice device) {
    _manager.addDevice(device);
    state = List.unmodifiable(_manager.devices);
  }

  void removeDevice(String deviceId) {
    _manager.removeDevice(deviceId);
    state = List.unmodifiable(_manager.devices);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

/// 设备列表主页
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceListProvider);
    final sortState = ref.watch(sortStateProvider);
    final l10n = AppLocalizations.of(context);

    // 排序设备列表
    final sortedDevices = _sortDevices(devices, sortState);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deviceList),
        centerTitle: true,
        actions: [
          // 排序按钮
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortDialog(context, ref, l10n),
            tooltip: l10n.sortDevices,
          ),
          // 添加/发现设备菜单
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.addDevice,
            onSelected: (value) {
              switch (value) {
                case 'add':
                  _showAddDeviceDialog(context, ref, l10n);
                  break;
                case 'discover':
                  _showDiscoveredDevicesDialog(context, ref, l10n);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'add',
                child: ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(l10n.addDevice),
                  subtitle: Text(l10n.addDeviceDesc),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'discover',
                child: ListTile(
                  leading: const Icon(Icons.search),
                  title: Text(l10n.discoverDevice),
                  subtitle: Text(l10n.discoverDeviceDesc),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBlurredBackground(context),
          _buildDeviceList(context, ref, sortedDevices, l10n),
        ],
      ),
    );
  }

  /// 排序设备列表
  List<ManagedDevice> _sortDevices(List<ManagedDevice> devices, SortState sortState) {
    final sorted = List<ManagedDevice>.from(devices);

    switch (sortState.type) {
      case SortType.time:
        sorted.sort((a, b) {
          final aTime = a.discoveredAt;
          final bTime = b.discoveredAt;
          return sortState.direction == SortDirection.ascending
              ? aTime.compareTo(bTime)
              : bTime.compareTo(aTime);
        });
      case SortType.name:
        sorted.sort((a, b) {
          return sortState.direction == SortDirection.ascending
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name);
        });
      case SortType.status:
        sorted.sort((a, b) {
          final aOnline = a.isOnline ? 0 : 1;
          final bOnline = b.isOnline ? 0 : 1;
          return sortState.direction == SortDirection.ascending
              ? aOnline.compareTo(bOnline)
              : bOnline.compareTo(aOnline);
        });
      case SortType.ip:
        sorted.sort((a, b) {
          return sortState.direction == SortDirection.ascending
              ? a.ipAddress.compareTo(b.ipAddress)
              : b.ipAddress.compareTo(a.ipAddress);
        });
    }

    return sorted;
  }

  /// 显示排序对话框
  void _showSortDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final sortState = ref.read(sortStateProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sortDevices),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 排序方式
            Text(
              l10n.sortBy,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            RadioListTile<SortType>(
              title: Text(l10n.sortByTime),
              value: SortType.time,
              groupValue: sortState.type,
              onChanged: (value) {
                if (value != null) {
                  ref.read(sortStateProvider.notifier).state =
                      sortState.copyWith(type: value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<SortType>(
              title: Text(l10n.sortByName),
              value: SortType.name,
              groupValue: sortState.type,
              onChanged: (value) {
                if (value != null) {
                  ref.read(sortStateProvider.notifier).state =
                      sortState.copyWith(type: value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<SortType>(
              title: Text(l10n.sortByStatus),
              value: SortType.status,
              groupValue: sortState.type,
              onChanged: (value) {
                if (value != null) {
                  ref.read(sortStateProvider.notifier).state =
                      sortState.copyWith(type: value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<SortType>(
              title: Text(l10n.sortByIp),
              value: SortType.ip,
              groupValue: sortState.type,
              onChanged: (value) {
                if (value != null) {
                  ref.read(sortStateProvider.notifier).state =
                      sortState.copyWith(type: value);
                  Navigator.pop(context);
                }
              },
            ),

            const Divider(),

            // 排序方向
            Text(
              l10n.sortDirection,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            RadioListTile<SortDirection>(
              title: Text(l10n.ascending),
              value: SortDirection.ascending,
              groupValue: sortState.direction,
              onChanged: (value) {
                if (value != null) {
                  ref.read(sortStateProvider.notifier).state =
                      sortState.copyWith(direction: value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<SortDirection>(
              title: Text(l10n.descending),
              value: SortDirection.descending,
              groupValue: sortState.direction,
              onChanged: (value) {
                if (value != null) {
                  ref.read(sortStateProvider.notifier).state =
                      sortState.copyWith(direction: value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示添加设备对话框
  void _showAddDeviceDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => _AddDeviceDialog(
        onAdd: (name, ip, port) {
          final device = ManagedDevice(
            deviceId: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            ipAddress: ip,
            port: port,
            onlineStatus: DeviceOnlineStatus.unknown,
            discoveredAt: DateTime.now(),
          );
          ref.read(deviceListProvider.notifier).addDevice(device);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.deviceAdded(name)),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        l10n: l10n,
      ),
    );
  }

  /// 显示已发现设备对话框
  void _showDiscoveredDevicesDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    // 获取已发现但未添加的设备
    final discoveryIntegration = ref.read(discoveryIntegrationProvider);
    final existingDevices = ref.read(deviceListProvider);

    showDialog(
      context: context,
      builder: (context) => _DiscoveredDevicesDialog(
        discoveryIntegration: discoveryIntegration,
        existingDevices: existingDevices,
        onAdd: (device) {
          ref.read(deviceListProvider.notifier).addDevice(device);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.deviceAdded(device.name)),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        l10n: l10n,
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
  Widget _buildDeviceList(BuildContext context, WidgetRef ref,
      List<ManagedDevice> devices, AppLocalizations l10n) {
    if (devices.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    final onlineCount = devices.where((d) => d.isOnline).length;
    final sortState = ref.watch(sortStateProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(const Duration(seconds: 1));
      },
      child: CustomScrollView(
        slivers: [
          // 顶部统计信息和当前排序
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.device_hub,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.deviceCount(devices.length, onlineCount),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 当前排序方式
                  Text(
                    '${l10n.currentSort}: ${_getSortTypeName(sortState.type, l10n)} ${sortState.direction == SortDirection.ascending ? '↑' : '↓'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
                  onTap: () => _navigateToDetail(context, device, l10n),
                );
              },
              childCount: devices.length,
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  /// 获取排序方式名称
  String _getSortTypeName(SortType type, AppLocalizations l10n) {
    switch (type) {
      case SortType.time:
        return l10n.sortByTime;
      case SortType.name:
        return l10n.sortByName;
      case SortType.status:
        return l10n.sortByStatus;
      case SortType.ip:
        return l10n.sortByIp;
    }
  }

  /// 空状态视图
  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
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
            l10n.noDeviceFound,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.ensureSameNetwork,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  /// 导航到设备详情页
  void _navigateToDetail(
      BuildContext context, ManagedDevice device, AppLocalizations l10n) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeviceDetailPage(
          deviceName: device.name,
          deviceIp: device.ipAddress,
        ),
      ),
    );
  }
}

/// 添加设备对话框
class _AddDeviceDialog extends StatefulWidget {
  final Function(String name, String ip, int port) onAdd;
  final AppLocalizations l10n;

  const _AddDeviceDialog({required this.onAdd, required this.l10n});

  @override
  State<_AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<_AddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '19190');

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
      title: Text(widget.l10n.addDevice),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: widget.l10n.deviceName,
                hintText: widget.l10n.deviceNameHint,
                prefixIcon: const Icon(Icons.devices),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return widget.l10n.enterDeviceName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: widget.l10n.ipAddress,
                hintText: widget.l10n.ipAddressHint,
                prefixIcon: const Icon(Icons.language),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return widget.l10n.enterIpAddress;
                }
                final ipRegex =
                    RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
                if (!ipRegex.hasMatch(value)) {
                  return widget.l10n.invalidIpAddress;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portController,
              decoration: InputDecoration(
                labelText: widget.l10n.port,
                hintText: widget.l10n.portHint,
                prefixIcon: const Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return widget.l10n.enterPort;
                }
                final port = int.tryParse(value);
                if (port == null || port < 1 || port > 65535) {
                  return widget.l10n.invalidPort;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onAdd(
                _nameController.text,
                _ipController.text,
                int.parse(_portController.text),
              );
              Navigator.pop(context);
            }
          },
          child: Text(widget.l10n.add),
        ),
      ],
    );
  }
}

/// 已发现设备对话框
class _DiscoveredDevicesDialog extends StatefulWidget {
  final DiscoveryIntegration discoveryIntegration;
  final List<ManagedDevice> existingDevices;
  final Function(ManagedDevice) onAdd;
  final AppLocalizations l10n;

  const _DiscoveredDevicesDialog({
    required this.discoveryIntegration,
    required this.existingDevices,
    required this.onAdd,
    required this.l10n,
  });

  @override
  State<_DiscoveredDevicesDialog> createState() =>
      _DiscoveredDevicesDialogState();
}

class _DiscoveredDevicesDialogState extends State<_DiscoveredDevicesDialog> {
  final List<DiscoveryMessage> _discoveredDevices = [];
  bool _isScanning = false;
  StreamSubscription? _discoverySubscription;

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
    });

    // 取消之前的订阅，避免重复监听
    _discoverySubscription?.cancel();

    // 监听设备发现事件
    _discoverySubscription =
        widget.discoveryIntegration.onDeviceDiscovered.listen((message) {
      if (mounted) {
        setState(() {
          // 避免重复添加
          if (!_discoveredDevices
              .any((d) => d.deviceId == message.deviceId)) {
            _discoveredDevices.add(message);
          }
        });
      }
    });

    // 10 秒后停止扫描
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  bool _isDeviceAdded(String deviceId) {
    return widget.existingDevices.any((d) => d.deviceId == deviceId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text(widget.l10n.discoverDevice),
          if (_isScanning) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _discoveredDevices.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isScanning
                          ? widget.l10n.scanning
                          : widget.l10n.noDevicesFound,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    if (!_isScanning) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _startScanning,
                        child: Text(widget.l10n.scanAgain),
                      ),
                    ],
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _discoveredDevices.length,
                itemBuilder: (context, index) {
                  final device = _discoveredDevices[index];
                  final isAdded = _isDeviceAdded(device.deviceId);

                  return ListTile(
                    leading: Icon(
                      Icons.devices,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(device.deviceName),
                    subtitle: Text('${device.ip}:${device.port}'),
                    trailing: isAdded
                        ? Chip(
                            label: Text(widget.l10n.added),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          )
                        : FilledButton(
                            onPressed: () {
                              final newDevice = ManagedDevice(
                                deviceId: device.deviceId,
                                name: device.deviceName,
                                ipAddress: device.ip,
                                port: device.port,
                                onlineStatus: DeviceOnlineStatus.online,
                                discoveredAt: DateTime.now(),
                                lastSeenAt: DateTime.now(),
                              );
                              widget.onAdd(newDevice);
                              Navigator.pop(context);
                            },
                            child: Text(widget.l10n.add),
                          ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.l10n.close),
        ),
      ],
    );
  }
}
