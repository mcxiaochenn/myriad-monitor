import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/access_token.dart';
import '../../core/storage/device_storage.dart';
import '../../core/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/locale_provider.dart';

/// 服务器配置 Provider（异步加载）
final serverConfigProvider =
    StateNotifierProvider<ServerConfigNotifier, ServerConfig>((ref) {
  return ServerConfigNotifier();
});

/// 服务器配置状态管理
class ServerConfigNotifier extends StateNotifier<ServerConfig> {
  ServerConfigNotifier() : super(ServerConfig()) {
    _loadConfig();
  }

  /// 从本地存储加载配置
  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载设备名称，如果没有则生成一个新的
    String? deviceName = prefs.getString('device_name');
    if (deviceName == null || deviceName.isEmpty) {
      deviceName = _generateDeviceName();
      await prefs.setString('device_name', deviceName);
    }

    state = ServerConfig(
      autoStart: prefs.getBool('auto_start') ?? true,
      port: prefs.getInt('server_port') ?? 19190,
      address: prefs.getString('listen_address') ?? '0.0.0.0',
      pushInterval: prefs.getInt('push_interval') ?? 1,
      enableDiscovery: prefs.getBool('enable_discovery') ?? true,
      deviceName: deviceName,
    );
  }

  /// 保存配置到本地存储
  Future<void> saveConfig(ServerConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_start', config.autoStart);
    await prefs.setInt('server_port', config.port);
    await prefs.setString('listen_address', config.address);
    await prefs.setInt('push_interval', config.pushInterval);
    await prefs.setBool('enable_discovery', config.enableDiscovery);
    await prefs.setString('device_name', config.deviceName);
    state = config;
  }

  /// 更新配置
  void updateConfig({
    bool? autoStart,
    int? port,
    String? address,
    int? pushInterval,
    bool? enableDiscovery,
    String? deviceName,
  }) {
    final newConfig = ServerConfig(
      autoStart: autoStart ?? state.autoStart,
      port: port ?? state.port,
      address: address ?? state.address,
      pushInterval: pushInterval ?? state.pushInterval,
      enableDiscovery: enableDiscovery ?? state.enableDiscovery,
      deviceName: deviceName ?? state.deviceName,
    );
    saveConfig(newConfig);
  }

  /// 随机生成设备名称（跟随系统语言）
  static String _generateDeviceName() {
    final random = DateTime.now().millisecondsSinceEpoch;

    // 中文名称
    final zhAdjectives = [
      '快乐的', '勇敢的', '聪明的', '优雅的', '神秘的',
      '闪耀的', '温柔的', '强大的', '敏捷的', '安静的',
    ];
    final zhNouns = [
      '熊猫', '海豚', '凤凰', '麒麟', '白虎',
      '青龙', '朱雀', '玄武', '玉兔', '金龙',
    ];

    // 英文名称
    final enAdjectives = [
      'Happy', 'Brave', 'Smart', 'Elegant', 'Mystic',
      'Shining', 'Gentle', 'Powerful', 'Swift', 'Calm',
    ];
    final enNouns = [
      'Panda', 'Dolphin', 'Phoenix', 'Unicorn', 'Tiger',
      'Dragon', 'Falcon', 'Turtle', 'Rabbit', 'Lion',
    ];

    // 根据系统语言选择
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final isZh = locale.languageCode == 'zh';

    final adjectives = isZh ? zhAdjectives : enAdjectives;
    final nouns = isZh ? zhNouns : enNouns;

    final adj = adjectives[random % adjectives.length];
    final noun = nouns[(random ~/ 10) % nouns.length];

    return '$adj$noun';
  }
}

/// 服务器配置模型
class ServerConfig {
  /// 是否自动启动服务器
  final bool autoStart;

  /// 服务器端口
  final int port;

  /// 监听地址
  final String address;

  /// 数据推送间隔（秒）
  final int pushInterval;

  /// 是否启用设备发现
  final bool enableDiscovery;

  /// 设备名称
  final String deviceName;

  ServerConfig({
    this.autoStart = true,
    this.port = 19190,
    this.address = '0.0.0.0',
    this.pushInterval = 1,
    this.enableDiscovery = true,
    this.deviceName = 'Myriad Monitor',
  });
}

/// 配置页面
///
/// 提供服务器相关配置选项
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(serverConfigProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navSettings),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 服务器配置区域
          _buildSectionHeader(context, l10n.serverConfig),
          SwitchListTile(
            title: Text(l10n.autoStartServer),
            subtitle: Text(l10n.autoStartServerDesc),
            value: config.autoStart,
            onChanged: (value) {
              ref.read(serverConfigProvider.notifier).updateConfig(
                    autoStart: value,
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
              ref.read(serverConfigProvider.notifier).updateConfig(
                    enableDiscovery: value,
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

          // 语言设置（二级菜单）
          _buildSectionHeader(context, l10n.language),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(_getLanguageName(ref, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context, ref, l10n),
          ),

          const Divider(),

          // 外观主题配置区域
          _buildSectionHeader(context, l10n.appearance),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.theme),
            subtitle: Text(_getThemeName(ref, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, ref, l10n),
          ),

          const Divider(),

          // 安全设置区域
          _buildSectionHeader(context, l10n.accessTokenLabel),
          ListTile(
            leading: const Icon(Icons.key),
            title: Text(l10n.resetAccessToken),
            subtitle: Text(l10n.resetAccessTokenDesc),
            trailing: const Icon(Icons.refresh),
            onTap: () => _confirmResetToken(context, ref, l10n),
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

  /// 获取当前语言名称
  String _getLanguageName(WidgetRef ref, AppLocalizations l10n) {
    final mode = ref.watch(languageModeProvider);
    switch (mode) {
      case LanguageMode.system:
        return l10n.systemDefault;
      case LanguageMode.chinese:
        return l10n.chinese;
      case LanguageMode.english:
        return l10n.english;
    }
  }

  /// 获取当前主题模式名称
  String _getThemeName(WidgetRef ref, AppLocalizations l10n) {
    final mode = ref.watch(themeModeProvider);
    switch (mode) {
      case ThemeModeOption.system:
        return l10n.systemDefault;
      case ThemeModeOption.light:
        return l10n.lightTheme;
      case ThemeModeOption.dark:
        return l10n.darkTheme;
    }
  }

  /// 显示主题选择对话框
  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final currentMode = ref.read(themeModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.theme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeModeOption>(
              title: Text(l10n.systemDefault),
              subtitle: Icon(Icons.brightness_auto, size: 20),
              value: ThemeModeOption.system,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeModeOption>(
              title: Text(l10n.lightTheme),
              subtitle: const Icon(Icons.light_mode, size: 20),
              value: ThemeModeOption.light,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeModeOption>(
              title: Text(l10n.darkTheme),
              subtitle: const Icon(Icons.dark_mode, size: 20),
              value: ThemeModeOption.dark,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示语言选择对话框
  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final currentMode = ref.read(languageModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<LanguageMode>(
              title: Text(l10n.systemDefault),
              value: LanguageMode.system,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(languageModeProvider.notifier).setLanguageMode(value);
                  ref.read(localeProvider.notifier).setLocale(null);
                  Navigator.pop(context);
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
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('zh', 'CN'));
                  Navigator.pop(context);
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
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('en', 'US'));
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
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
                ref.read(serverConfigProvider.notifier).updateConfig(
                      port: port,
                    );
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
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
              ref.read(serverConfigProvider.notifier).updateConfig(
                    address: controller.text,
                  );
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
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
                ref.read(serverConfigProvider.notifier).updateConfig(
                      pushInterval: interval,
                    );
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
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
              ref.read(serverConfigProvider.notifier).updateConfig(
                    deviceName: controller.text,
                  );
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
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
            onPressed: () async {
              Navigator.pop(context);
              await DeviceStorage().clearDevices();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.deviceDataCleared),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
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
            onPressed: () async {
              Navigator.pop(context);
              // TODO: 接入历史数据存储后清除历史数据
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.historyDataCleared),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
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

  /// 确认重置访问令牌
  void _confirmResetToken(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetAccessToken),
        content: Text(l10n.resetAccessTokenDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await resetAccessToken();
              // 刷新 Provider 以获取新令牌
              ref.invalidate(accessTokenProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.tokenResetSuccess),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
