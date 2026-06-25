import 'package:flutter/material.dart';

/// 关于页面
///
/// 展示应用信息、版本、开发者信息和开源许可
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
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
                  '万镜 Myriad',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // 版本号
                Text(
                  '版本 1.0.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                // 应用描述
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    '去中心化的跨平台系统监控面板\n设备间 IP 直连，一端采集一端渲染',
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
          _buildSectionHeader(context, '功能特性'),
          _buildFeatureItem(
            context,
            Icons.link,
            '去中心化',
            '无中心服务器，设备间通过 IP 直连通信',
          ),
          _buildFeatureItem(
            context,
            Icons.swap_horiz,
            '客户端服务端同体',
            '每个实例既是 Server 又是 Client',
          ),
          _buildFeatureItem(
            context,
            Icons.devices,
            '跨平台',
            '支持 Windows、macOS、Linux、Android、iOS',
          ),
          _buildFeatureItem(
            context,
            Icons.show_chart,
            '实时监控',
            'CPU、内存、GPU、磁盘、网络实时图表',
          ),

          const Divider(),

          // 技术栈
          _buildSectionHeader(context, '技术栈'),
          _buildTechItem(context, 'Flutter', '跨平台 UI 框架'),
          _buildTechItem(context, 'Riverpod', '状态管理'),
          _buildTechItem(context, 'WebSocket', '设备间通信'),
          _buildTechItem(context, 'fl_chart', '图表渲染'),
          _buildTechItem(context, 'Hive', '本地数据存储'),

          const Divider(),

          // 开发者信息
          _buildSectionHeader(context, '开发者'),
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
          _buildSectionHeader(context, '开源许可'),
          ListTile(
            title: const Text('MIT License'),
            subtitle: const Text('Copyright (c) 2026 尘渊尘'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 显示完整许可证
            },
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
