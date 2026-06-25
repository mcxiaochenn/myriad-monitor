import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// 关于页面
///
/// 展示应用信息、版本、开发者信息和开源许可
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
                // 应用图标
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.device_hub,
                    size: 56,
                    color: colorScheme.onPrimaryContainer,
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
                  'v1.0.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                // 应用描述
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    l10n.appDescription,
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

          // 技术栈
          _buildSectionHeader(context, l10n.techStack),
          _buildTechItem(context, 'Flutter', l10n.crossPlatformFramework),
          _buildTechItem(context, 'Riverpod', l10n.stateManagement),
          _buildTechItem(context, 'WebSocket', l10n.deviceCommunication),
          _buildTechItem(context, 'fl_chart', l10n.chartRendering),
          _buildTechItem(context, 'Hive', l10n.localStorage),

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
            onTap: () {
              // TODO: 打开 GitHub 链接
            },
          ),

          const Divider(),

          // 开源许可
          _buildSectionHeader(context, l10n.openSourceLicense),
          const ListTile(
            title: Text('MIT License'),
            subtitle: Text('Copyright (c) 2026 辰渊尘'),
            trailing: Icon(Icons.chevron_right),
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

  /// 构建技术栈项
  Widget _buildTechItem(
    BuildContext context,
    String name,
    String description,
  ) {
    return ListTile(
      title: Text(name),
      subtitle: Text(description),
    );
  }
}
