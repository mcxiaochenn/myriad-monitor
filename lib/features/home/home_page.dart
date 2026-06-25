import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../client/device_manager.dart';
import '../../core/discovery/udp_discovery.dart';
import '../../core/discovery/discovery_integration.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_page.dart';
import 'device_card.dart';

/// 设备管理器 Provider
final deviceManagerProvider = Provider<DeviceManager>((ref) {
  final manager = DeviceManager();
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
  ref.onDispose(() => integration.dispose());
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

  DeviceListNotifier(this._manager) : super(_manager.devices) {
    _manager.devicesChangedStream.listen((devices) {
      state = List.unmodifiable(devices);
    });
    _manager.deviceStatusStream.listen((_) {
      state = List.unmodifiable(_manager.devices);
    });
  }

  void addDevice(ManagedDevice device) {
    _manager.addDevice(device);
    state = List.unmodifiable(_manager.devices);
  }

  void removeDevice(String deviceId) {
    _manager.removeDevice(deviceId);
    state = List.unmodifiable(_manager.devices);
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
          // 添加设备按钮
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddDeviceDialog(context, ref, l10n),
            tooltip: l10n.addDevice,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.openingDevice(device.name)),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
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
