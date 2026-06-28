import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/access_token.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_page.dart';

/// 服务运行状态 Provider
final serverStatusProvider =
    StateNotifierProvider<ServerStatusNotifier, ServerStatus>((ref) {
  return ServerStatusNotifier();
});

/// 服务状态
class ServerStatus {
  final bool isRunning;
  final int connectedClients;

  ServerStatus({
    this.isRunning = false,
    this.connectedClients = 0,
  });

  ServerStatus copyWith({
    bool? isRunning,
    int? connectedClients,
  }) {
    return ServerStatus(
      isRunning: isRunning ?? this.isRunning,
      connectedClients: connectedClients ?? this.connectedClients,
    );
  }
}

/// 服务状态管理
class ServerStatusNotifier extends StateNotifier<ServerStatus> {
  ServerStatusNotifier() : super(ServerStatus());

  void toggleService() {
    state = state.copyWith(isRunning: !state.isRunning);
    // TODO: 实际启动/停止 HTTP 服务
  }

  void updateClientCount(int count) {
    state = state.copyWith(connectedClients: count);
  }
}

/// 设备 ID Provider
final deviceIdProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  String? deviceId = prefs.getString('device_id');

  if (deviceId == null || deviceId.isEmpty) {
    deviceId = const Uuid().v4();
    await prefs.setString('device_id', deviceId);
  }

  return deviceId;
});

/// 服务端页面
///
/// 显示当前设备信息和 HTTP 服务运行状态
class ServerPage extends ConsumerWidget {
  const ServerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(serverConfigProvider);
    final serverStatus = ref.watch(serverStatusProvider);
    final deviceIdAsync = ref.watch(deviceIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navServer),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 设备信息卡片
          _buildDeviceInfoCard(context, l10n, config, deviceIdAsync),

          const SizedBox(height: 16),

          // 服务状态卡片
          _buildServiceStatusCard(context, ref, l10n, config, serverStatus),

          const SizedBox(height: 16),

          // 网络信息卡片
          _buildNetworkInfoCard(context, l10n),

          const SizedBox(height: 16),

          // 连接的客户端卡片
          _buildConnectedClientsCard(context, l10n, serverStatus),
        ],
      ),
    );
  }

  /// 构建设备信息卡片
  Widget _buildDeviceInfoCard(
    BuildContext context,
    AppLocalizations l10n,
    ServerConfig config,
    AsyncValue<String> deviceIdAsync,
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
            _buildInfoRow(
              l10n.deviceId,
              deviceIdAsync.when(
                data: (id) => id.substring(0, 8), // 只显示前 8 位
                loading: () => '...',
                error: (_, __) => 'error',
              ),
            ),
            _buildInfoRow(l10n.os, _getOsName(l10n)),
            _buildInfoRow(l10n.hostname, _getHostname()),
          ],
        ),
      ),
    );
  }

  /// 构建服务状态卡片
  Widget _buildServiceStatusCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ServerConfig config,
    ServerStatus status,
  ) {
    final deviceIdAsync = ref.watch(deviceIdProvider);
    final tokenAsync = ref.watch(accessTokenProvider);

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
              l10n.httpService,
              status.isRunning,
              status.isRunning ? l10n.running : l10n.stopped,
            ),
            _buildInfoRow(l10n.serverPort, '${config.port}'),
            _buildInfoRow(l10n.listenAddress, config.address),
            _buildInfoRow(l10n.pushInterval, l10n.seconds(config.pushInterval)),
            const Divider(),
            // HTTP API 访问地址
            deviceIdAsync.when(
              data: (deviceId) => tokenAsync.when(
                data: (token) {
                  final url = 'http://{ip}:${config.port}/$deviceId/$token';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(l10n.accessUrl, url),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              l10n.accessTokenLabel,
                              token.length > 16
                                  ? '${token.substring(0, 8)}...${token.substring(token.length - 8)}'
                                  : token,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: l10n.copyToken,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: token));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.tokenCopied),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => _buildInfoRow(l10n.accessTokenLabel, '...'),
                error: (_, __) => _buildInfoRow(l10n.accessTokenLabel, 'Error'),
              ),
              loading: () => _buildInfoRow(l10n.accessUrl, '...'),
              error: (_, __) => _buildInfoRow(l10n.accessUrl, 'Error'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ref.read(serverStatusProvider.notifier).toggleService();
                },
                icon: Icon(status.isRunning ? Icons.stop : Icons.play_arrow),
                label: Text(
                    status.isRunning ? l10n.stopService : l10n.startService),
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
    BuildContext context,
    AppLocalizations l10n,
    ServerStatus status,
  ) {
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
            _buildInfoRow(l10n.clientCount, '${status.connectedClients}'),
            if (status.connectedClients == 0)
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

  /// 获取操作系统名称
  String _getOsName(AppLocalizations l10n) {
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
