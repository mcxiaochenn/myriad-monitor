import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 服务器配置 Provider
final serverConfigProvider = StateProvider<ServerConfig>((ref) {
  return ServerConfig();
});

/// 服务器配置模型
class ServerConfig {
  /// 是否自动启动服务器
  bool autoStart;

  /// 服务器端口
  int port;

  /// 监听地址
  String address;

  /// 数据推送间隔（秒）
  int pushInterval;

  /// 是否启用设备发现
  bool enableDiscovery;

  /// 设备名称
  String deviceName;

  ServerConfig({
    this.autoStart = true,
    this.port = 8080,
    this.address = '0.0.0.0',
    this.pushInterval = 1,
    this.enableDiscovery = true,
    this.deviceName = 'Myriad Monitor',
  });
}

/// 配置页面
///
/// 提供服务器相关配置选项，包括：
/// - 服务器端口、地址配置
/// - 数据推送间隔
/// - 设备发现开关
/// - 设备名称设置
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(serverConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('配置'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 服务器配置区域
          _buildSectionHeader(context, '服务器配置'),
          SwitchListTile(
            title: const Text('自动启动服务器'),
            subtitle: const Text('应用启动时自动开启 WebSocket 服务器'),
            value: config.autoStart,
            onChanged: (value) {
              ref.read(serverConfigProvider.notifier).state = ServerConfig(
                autoStart: value,
                port: config.port,
                address: config.address,
                pushInterval: config.pushInterval,
                enableDiscovery: config.enableDiscovery,
                deviceName: config.deviceName,
              );
            },
          ),
          ListTile(
            title: const Text('服务器端口'),
            subtitle: Text('${config.port}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editPort(context, ref, config),
          ),
          ListTile(
            title: const Text('监听地址'),
            subtitle: Text(config.address),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editAddress(context, ref, config),
          ),
          ListTile(
            title: const Text('数据推送间隔'),
            subtitle: Text('${config.pushInterval} 秒'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editPushInterval(context, ref, config),
          ),

          const Divider(),

          // 设备发现配置区域
          _buildSectionHeader(context, '设备发现'),
          SwitchListTile(
            title: const Text('启用设备发现'),
            subtitle: const Text('自动发现局域网内的其他 Myriad 设备'),
            value: config.enableDiscovery,
            onChanged: (value) {
              ref.read(serverConfigProvider.notifier).state = ServerConfig(
                autoStart: config.autoStart,
                port: config.port,
                address: config.address,
                pushInterval: config.pushInterval,
                enableDiscovery: value,
                deviceName: config.deviceName,
              );
            },
          ),
          ListTile(
            title: const Text('设备名称'),
            subtitle: Text(config.deviceName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editDeviceName(context, ref, config),
          ),

          const Divider(),

          // 数据存储配置区域
          _buildSectionHeader(context, '数据存储'),
          ListTile(
            title: const Text('清除设备数据'),
            subtitle: const Text('删除所有已保存的设备信息'),
            trailing: const Icon(Icons.delete_outline),
            onTap: () => _confirmClearData(context),
          ),
          ListTile(
            title: const Text('清除历史数据'),
            subtitle: const Text('删除所有监控历史记录'),
            trailing: const Icon(Icons.delete_outline),
            onTap: () => _confirmClearHistory(context),
          ),
        ],
      ),
    );
  }

  /// 构建区域标题
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  /// 编辑端口
  void _editPort(BuildContext context, WidgetRef ref, ServerConfig config) {
    final controller = TextEditingController(text: '${config.port}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('服务器端口'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '输入端口号 (1-65535)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final port = int.tryParse(controller.text);
              if (port != null && port >= 1 && port <= 65535) {
                ref.read(serverConfigProvider.notifier).state = ServerConfig(
                  autoStart: config.autoStart,
                  port: port,
                  address: config.address,
                  pushInterval: config.pushInterval,
                  enableDiscovery: config.enableDiscovery,
                  deviceName: config.deviceName,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 编辑监听地址
  void _editAddress(BuildContext context, WidgetRef ref, ServerConfig config) {
    final controller = TextEditingController(text: config.address);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('监听地址'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入监听地址 (例如: 0.0.0.0)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(serverConfigProvider.notifier).state = ServerConfig(
                autoStart: config.autoStart,
                port: config.port,
                address: controller.text,
                pushInterval: config.pushInterval,
                enableDiscovery: config.enableDiscovery,
                deviceName: config.deviceName,
              );
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 编辑推送间隔
  void _editPushInterval(
      BuildContext context, WidgetRef ref, ServerConfig config) {
    final controller =
        TextEditingController(text: '${config.pushInterval}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据推送间隔'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '输入间隔秒数 (1-60)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final interval = int.tryParse(controller.text);
              if (interval != null && interval >= 1 && interval <= 60) {
                ref.read(serverConfigProvider.notifier).state = ServerConfig(
                  autoStart: config.autoStart,
                  port: config.port,
                  address: config.address,
                  pushInterval: interval,
                  enableDiscovery: config.enableDiscovery,
                  deviceName: config.deviceName,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 编辑设备名称
  void _editDeviceName(
      BuildContext context, WidgetRef ref, ServerConfig config) {
    final controller = TextEditingController(text: config.deviceName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设备名称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入设备名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(serverConfigProvider.notifier).state = ServerConfig(
                autoStart: config.autoStart,
                port: config.port,
                address: config.address,
                pushInterval: config.pushInterval,
                enableDiscovery: config.enableDiscovery,
                deviceName: controller.text,
              );
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 确认清除设备数据
  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除设备数据'),
        content: const Text('确定要删除所有已保存的设备信息吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: 实现清除设备数据
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('设备数据已清除'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  /// 确认清除历史数据
  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除历史数据'),
        content: const Text('确定要删除所有监控历史记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: 实现清除历史数据
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('历史数据已清除'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}
