import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_logger.dart';
import '../../core/constants.dart';

/// 开发者选项页面 — 在关于页连击 15 下应用图标后进入
class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = AppLogger();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('开发者选项'), centerTitle: true),
      body: ListView(children: [
        _section(theme, '应用日志', Icons.article),
        SizedBox(
          height: 350,
          child: logger.entries.isEmpty
              ? const Center(child: Text('暂无日志', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: logger.entries.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                    child: Text(logger.entries[i],
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                  ),
                ),
        ),
        const Divider(indent: 16, endIndent: 16),
        _section(theme, '应用信息', Icons.info),
        _row('版本', 'v${AppConfigConstants.appVersion}'),
        _row('Build', AppConfigConstants.appBuildNumber),
        _row('Platform', _platform),
        _row('日志目录', logger.logDir ?? '未初始化'),
        const Divider(indent: 16, endIndent: 16),
        _section(theme, '操作', Icons.build),
        ListTile(
          leading: const Icon(Icons.copy_all),
          title: const Text('复制全部日志'),
          onTap: () {
            final text = logger.entries.join('\n');
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('日志已复制'), behavior: SnackBarBehavior.floating),
            );
          },
        ),
      ]),
    );
  }

  Widget _section(ThemeData t, String title, IconData ic) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          Icon(ic, size: 18, color: t.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: t.colorScheme.primary)),
        ]),
      );

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: const TextStyle(color: Colors.grey)),
          Flexible(child: Text(v, textAlign: TextAlign.end)),
        ]),
      );

  String get _platform {
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }
}
