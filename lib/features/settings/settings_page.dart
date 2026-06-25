import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/locale_provider.dart';

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
/// - 语言切换
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(serverConfigProvider);
    final l10n = AppLocalizations.of(context);
    final languageMode = ref.watch(languageModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navSettings),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 语言配置区域
          _buildSectionHeader(context, l10n.language),
          _buildLanguageSelector(context, ref, l10n, languageMode),

          const Divider(),

          // 服务器配置区域
          _buildSectionHeader(context, l10n.serverConfig),
          SwitchListTile(
            title: Text(l10n.autoStartServer),
            subtitle: Text(l10n.autoStartServerDesc),
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
            title: Text(l10n.serverPort),
            subtitle: Text('${config.port}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editPort(context, ref, config, l10n),
          ),
          ListTile(
            title: Text(l10n.listenAddress),
            subtitle: Text(config.address),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editAddress(context, ref, config, l10n),
          ),
          ListTile(
            title: Text(l10n.pushInterval),
            subtitle: Text(l10n.seconds(config.pushInterval)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editPushInterval(context, ref, config, l10n),
          ),

          const Divider(),

          // 设备发现配置区域
          _buildSectionHeader(context, l10n.deviceDiscovery),
          SwitchListTile(
            title: Text(l10n.enableDiscovery),
            subtitle: Text(l10n.enableDiscoveryDesc),
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
            title: Text(l10n.deviceNameLabel),
            subtitle: Text(config.deviceName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editDeviceName(context, ref, config, l10n),
          ),

          const Divider(),

          // 数据存储配置区域
          _buildSectionHeader(context, l10n.dataStorage),
          ListTile(
            title: Text(l10n.clearDeviceData),
            subtitle: Text(l10n.clearDeviceDataDesc),
            trailing: const Icon(Icons.delete_outline),
            onTap: () => _confirmClearData(context, l10n),
          ),
          ListTile(
            title: Text(l10n.clearHistoryData),
            subtitle: Text(l10n.clearHistoryDataDesc),
            trailing: const Icon(Icons.delete_outline),
            onTap: () => _confirmClearHistory(context, l10n),
          ),
        ],
      ),
    );
  }

  /// 构建语言选择器
  Widget _buildLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    LanguageMode currentMode,
  ) {
    return Column(
      children: [
        RadioListTile<LanguageMode>(
          title: Text(l10n.systemDefault),
          value: LanguageMode.system,
          groupValue: currentMode,
          onChanged: (value) {
            if (value != null) {
              ref.read(languageModeProvider.notifier).setLanguageMode(value);
              ref.read(localeProvider.notifier).setLocale(null);
            }
          },
        ),
        RadioListTile<LanguageMode>(
          title: Text(l10n.chinese),
          subtitle: const Text('中文'),
          value: LanguageMode.chinese,
          groupValue: currentMode,
          onChanged: (value) {
            if (value != null) {
              ref.read(languageModeProvider.notifier).setLanguageMode(value);
              ref.read(localeProvider.notifier).setLocale(const Locale('zh', 'CN'));
            }
          },
        ),
        RadioListTile<LanguageMode>(
          title: Text(l10n.english),
          subtitle: const Text('English'),
          value: LanguageMode.english,
          groupValue: currentMode,
          onChanged: (value) {
            if (value != null) {
              ref.read(languageModeProvider.notifier).setLanguageMode(value);
              ref.read(localeProvider.notifier).setLocale(const Locale('en', 'US'));
            }
          },
        ),
      ],
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
  void _editPort(BuildContext context, WidgetRef ref, ServerConfig config,
      AppLocalizations l10n) {
    final controller = TextEditingController(text: '${config.port}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editPortTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: l10n.editPortHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
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
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  /// 编辑监听地址
  void _editAddress(BuildContext context, WidgetRef ref, ServerConfig config,
      AppLocalizations l10n) {
    final controller = TextEditingController(text: config.address);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editAddressTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.editAddressHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
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
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  /// 编辑推送间隔
  void _editPushInterval(BuildContext context, WidgetRef ref,
      ServerConfig config, AppLocalizations l10n) {
    final controller = TextEditingController(text: '${config.pushInterval}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editIntervalTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: l10n.editIntervalHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
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
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  /// 编辑设备名称
  void _editDeviceName(BuildContext context, WidgetRef ref,
      ServerConfig config, AppLocalizations l10n) {
    final controller = TextEditingController(text: config.deviceName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editDeviceNameTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.editDeviceNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
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
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  /// 确认清除设备数据
  void _confirmClearData(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearDeviceData),
        content: Text(l10n.confirmClearData),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              // TODO: 实现清除设备数据
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.deviceDataCleared),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  /// 确认清除历史数据
  void _confirmClearHistory(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearHistoryData),
        content: Text(l10n.confirmClearHistory),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              // TODO: 实现清除历史数据
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.historyDataCleared),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
