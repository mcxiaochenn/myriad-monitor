import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../client/device_manager.dart';
import '../settings/settings_page.dart';

/// 服务端页面
///
/// 显示当前设备信息和 WebSocket 服务运行状态
class ServerPage extends ConsumerWidget {
  const ServerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(serverConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navServer),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 设备信息卡片
          _buildDeviceInfoCard(context, l10n, config),

          const SizedBox(height: 16),

          // 服务状态卡片
          _buildServiceStatusCard(context, l10n, config),

          const SizedBox(height: 16),

          // 网络信息卡片
          _buildNetworkInfoCard(context, l10n),

          const SizedBox(height: 16),

          // 连接的客户端卡片
          _buildConnectedClientsCard(context, l10n),
        ],
      ),
    );
  }

  /// 构建设备信息卡片
  Widget _buildDeviceInfoCard(
    BuildContext context,
    AppLocalizations l10n,
    ServerConfig config,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone_android,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.deviceInfo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(l10n.deviceNameLabel, config.deviceName),
            _buildInfoRow(l10n.deviceId, _getDeviceId()),
            _buildInfoRow(l10n.os, _getOsName()),
            _buildInfoRow(l10n.hostname, _getHostname()),
          ],
        ),
      ),
    );
  }

  /// 构建服务状态卡片
  Widget _buildServiceStatusCard(
    BuildContext context,
    AppLocalizations l10n,
    ServerConfig config,
  ) {
    // TODO: 从实际服务获取状态
    final isRunning = config.autoStart;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.serviceStatus,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            _buildStatusRow(
              l10n.websocketService,
              isRunning,
              isRunning ? l10n.running : l10n.stopped,
            ),
            _buildInfoRow(l10n.serverPort, '${config.port}'),
            _buildInfoRow(l10n.listenAddress, config.address),
            _buildInfoRow(l10n.pushInterval, l10n.seconds(config.pushInterval)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  // TODO: 切换服务状态
                },
                icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                label: Text(isRunning ? l10n.stopService : l10n.startService),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建网络信息卡片
  Widget _buildNetworkInfoCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wifi,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.networkInfo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            FutureBuilder<List<String>>(
              future: _getLocalIps(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    children: snapshot.data!
                        .map((ip) => _buildInfoRow(l10n.ipAddress, ip))
                        .toList(),
                  );
                }
                return _buildInfoRow(l10n.ipAddress, l10n.detecting);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建连接的客户端卡片
  Widget _buildConnectedClientsCard(
      BuildContext context, AppLocalizations l10n) {
    // TODO: 从实际服务获取客户端列表
    final clientCount = 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.devices,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.connectedClients,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(l10n.clientCount, '$clientCount'),
            if (clientCount == 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.noClients,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建状态行
  Widget _buildStatusRow(String label, bool isActive, String statusText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Text(statusText),
            ],
          ),
        ],
      ),
    );
  }

  /// 获取设备 ID
  String _getDeviceId() {
    // TODO: 从实际服务获取设备 ID
    return 'auto-generated';
  }

  /// 获取操作系统名称
  String _getOsName() {
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }

  /// 获取主机名
  String _getHostname() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'Unknown';
    }
  }

  /// 获取本机 IP 地址
  Future<List<String>> _getLocalIps() async {
    final ips = <String>[];
    try {
      for (final interface in await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      )) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            ips.add(addr.address);
          }
        }
      }
    } catch (_) {}
    if (ips.isEmpty) {
      ips.add('127.0.0.1');
    }
    return ips;
  }
}
