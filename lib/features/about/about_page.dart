import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../l10n/app_localizations.dart';
import '../developer/developer_page.dart';

/// 关于页面
///
/// 展示应用信息、版本、开发者信息和开源许可。
/// 连击应用图标 15 次进入开发者选项。
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  int _logoTapCount = 0;
  Timer? _resetTimer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navAbout),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 应用 Logo 和名称
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                // 应用图标（主题自适应 + 连击 15 次进入开发者选项）
                GestureDetector(
                  onTap: () {
                    _logoTapCount++;
                    _resetTimer?.cancel();
                    if (_logoTapCount >= 15) {
                      _logoTapCount = 0;
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DeveloperPage()),
                      );
                    }
                    // 5 秒无连击则重置
                    _resetTimer = Timer(const Duration(seconds: 5), () {
                      if (mounted) _logoTapCount = 0;
                    });
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'assets/applogo_night.png'
                          : 'assets/applogo_light.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 应用名称
                Text(
                  l10n.appName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // 版本号
                Text(
                  'v${AppConfigConstants.appVersion} (build ${AppConfigConstants.appBuildNumber})',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                // 应用描述
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    l10n.appMeaning,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // 关于本软件（二级菜单）
          _buildSectionHeader(context, l10n.aboutSoftware),
          ListTile(
            leading: Icon(Icons.code, color: colorScheme.primary),
            title: Text(l10n.techStack),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTechStackDialog(context, l10n),
          ),
          ListTile(
            leading: Icon(Icons.description, color: colorScheme.primary),
            title: Text(l10n.openSourceLicense),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appName,
              applicationVersion: 'v${AppConfigConstants.appVersion}',
            ),
          ),

          const Divider(),

          // 功能特性
          _buildSectionHeader(context, l10n.features),
          _buildFeatureItem(
            context,
            Icons.link,
            l10n.decentralized,
            l10n.decentralizedDesc,
          ),
          _buildFeatureItem(
            context,
            Icons.swap_horiz,
            l10n.clientServer,
            l10n.clientServerDesc,
          ),
          _buildFeatureItem(
            context,
            Icons.devices,
            l10n.crossPlatform,
            l10n.crossPlatformDesc,
          ),
          _buildFeatureItem(
            context,
            Icons.show_chart,
            l10n.realtimeMonitor,
            l10n.realtimeMonitorDesc,
          ),

          const Divider(),

          // 开发者信息
          _buildSectionHeader(context, l10n.developer),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text('辰渊尘'),
            subtitle: const Text('mcxiaochenn'),
            onTap: () => _launchUrl('https://github.com/mcxiaochenn'),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.code,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text('GitHub'),
            subtitle: const Text('github.com/mcxiaochenn/myriad-monitor'),
            onTap: () =>
                _launchUrl('https://github.com/mcxiaochenn/myriad-monitor'),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.language,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(l10n.blog),
            subtitle: const Text('blog.mcxiaochen.top'),
            onTap: () => _launchUrl('https://blog.mcxiaochen.top'),
          ),

          const SizedBox(height: 40),
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

  /// 构建功能特性项
  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  /// 显示技术栈对话框
  void _showTechStackDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.techStack),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTechItem(
                context,
                'Flutter',
                l10n.crossPlatformFramework,
                'https://flutter.dev',
              ),
              _buildTechItem(
                context,
                'Riverpod',
                l10n.stateManagement,
                'https://riverpod.dev',
              ),
              _buildTechItem(
                context,
                'HTTP (shelf)',
                l10n.deviceCommunication,
                'https://pub.dev/packages/shelf',
              ),
              _buildTechItem(
                context,
                'fl_chart',
                l10n.chartRendering,
                'https://pub.dev/packages/fl_chart',
              ),
              _buildTechItem(
                context,
                'Hive',
                l10n.localStorage,
                'https://pub.dev/packages/hive',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  /// 构建技术栈项
  Widget _buildTechItem(
    BuildContext context,
    String name,
    String description,
    String url,
  ) {
    return ListTile(
      title: Text(name),
      subtitle: Text(description),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: () => _launchUrl(url),
    );
  }

  /// 打开 URL
  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (_) {}
  }
}
