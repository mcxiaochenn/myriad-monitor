import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/access_token.dart';
import '../../core/app_logger.dart';
import '../../server/server_service.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_page.dart';

// ── 日志（UI 展示用，配合 AppLogger） ──
final serverLogProvider = StateProvider<List<String>>((ref) => []);

void addServerLog(WidgetRef ref, String msg) {
  AppLogger().info(msg);
  final now = DateTime.now();
  final ts = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  ref.read(serverLogProvider.notifier).state = ['[$ts] $msg', ...ref.read(serverLogProvider)].take(200).toList();
}

// ── 服务状态 ──
class ServerStatus {
  final bool isRunning; final int connectedClients;
  ServerStatus({this.isRunning = false, this.connectedClients = 0});
  ServerStatus copyWith({bool? isRunning, int? connectedClients}) =>
      ServerStatus(isRunning: isRunning ?? this.isRunning, connectedClients: connectedClients ?? this.connectedClients);
}

final serverStatusProvider = StateNotifierProvider<ServerStatusNotifier, ServerStatus>((ref) => ServerStatusNotifier());

class ServerStatusNotifier extends StateNotifier<ServerStatus> {
  ServerService? _service;
  ServerStatusNotifier() : super(ServerStatus());
  ServerService? get service => _service;

  /// 刷新 Server 端的访问令牌（设置页面重置令牌后调用）
  Future<void> refreshAccessToken() async {
    await _service?.refreshAccessToken();
  }

  Future<void> toggleService(WidgetRef ref) async {
    if (state.isRunning) {
      AppLogger().info('正在停止 HTTP 服务...');
      await _service?.stop(); _service = null;
      state = state.copyWith(isRunning: false);
      addServerLog(ref, 'HTTP 服务已停止');
    } else {
      final cfg = ref.read(serverConfigProvider);
      AppLogger().info('正在启动 HTTP 服务 port=${cfg.port}...');
      _service = ServerService(port: cfg.port, address: cfg.address);
      final did = ref.read(deviceIdProvider).value ?? '';
      if (did.isEmpty) {
        addServerLog(ref, '服务启动失败: 设备 ID 未就绪');
        AppLogger().error('设备 ID 未就绪');
        return;
      }
      try {
        final ok = await _service!.start(deviceId: did, deviceName: cfg.deviceName);
        state = state.copyWith(isRunning: ok);
        addServerLog(ref, ok ? 'HTTP 服务已启动 → 0.0.0.0:${cfg.port}' : 'HTTP 服务启动失败');
      } catch (e, st) {
        AppLogger().error('HTTP 服务启动异常: $e\n$st');
        addServerLog(ref, '服务启动异常: $e');
      }
    }
  }

  @override void dispose() { _service?.dispose(); super.dispose(); }
}

final deviceIdProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  String? id = prefs.getString('device_id');
  if (id == null || id.isEmpty) { id = const Uuid().v4(); await prefs.setString('device_id', id); }
  return id;
});

class ServerPage extends ConsumerWidget {
  const ServerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cfg = ref.watch(serverConfigProvider);
    final s = ref.watch(serverStatusProvider);
    final did = ref.watch(deviceIdProvider);
    final logs = ref.watch(serverLogProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.navServer), centerTitle: true),
      body: ListView(children: [
        _infoCard(theme, l, cfg, did), const SizedBox(height: 16),
        _svcCard(context, ref, theme, l, cfg, s, did), const SizedBox(height: 16),
        _bindCard(context, ref, theme, cfg, s, did), const SizedBox(height: 16),
        _logCard(theme, logs, ref), const SizedBox(height: 16),
        _netCard(context, theme, l),
      ]),
    );
  }

  Widget _infoCard(ThemeData t, AppLocalizations l, ServerConfig c, AsyncValue<String> d) => Card(margin: const EdgeInsets.all(16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(Icons.phone_android, color: t.colorScheme.primary), const SizedBox(width: 8), Text(l.deviceInfo, style: t.textTheme.titleMedium)]), const Divider(),
    _row(l.deviceNameLabel, c.deviceName), _row(l.deviceId, d.when(data: (v) => v.substring(0, 8), loading: () => '...', error: (_, __) => 'error')),
    _row(l.os, _os), _row(l.hostname, _host),
  ])));

  Widget _svcCard(BuildContext ctx, WidgetRef ref, ThemeData t, AppLocalizations l, ServerConfig c, ServerStatus s, AsyncValue<String> d) {
    final tok = ref.watch(accessTokenProvider);
    return Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.cloud, color: t.colorScheme.primary), const SizedBox(width: 8), Text(l.serviceStatus, style: t.textTheme.titleMedium)]), const Divider(),
      _statusRow(l.httpService, s.isRunning, s.isRunning ? l.running : l.stopped), _row(l.serverPort, '${c.port}'), _row(l.listenAddress, c.address), _row(l.pushInterval, l.seconds(c.pushInterval)), const Divider(),
      d.when(
        data: (did) => tok.when(
          data: (tk) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _row(l.accessUrl, 'http://{ip}:${c.port}/$did/$tk'), const SizedBox(height: 8),
            Row(children: [Expanded(child: _row(l.accessTokenLabel, tk.length > 16 ? '${tk.substring(0, 8)}...${tk.substring(tk.length - 8)}' : tk)), IconButton(icon: const Icon(Icons.copy, size: 18), tooltip: l.copyToken, onPressed: () { Clipboard.setData(ClipboardData(text: tk)); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(l.tokenCopied), behavior: SnackBarBehavior.floating)); })]),
          ]),
          loading: () => _row(l.accessTokenLabel, '...'),
          error: (_, __) => _row(l.accessTokenLabel, 'Error'),
        ),
        loading: () => _row(l.accessUrl, '...'),
        error: (_, __) => _row(l.accessUrl, 'Error'),
      ),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: () => ref.read(serverStatusProvider.notifier).toggleService(ref),
        icon: Icon(s.isRunning ? Icons.stop : Icons.play_arrow), label: Text(s.isRunning ? l.stopService : l.startService))),
    ])));
  }

  Widget _bindCard(BuildContext ctx, WidgetRef ref, ThemeData t, ServerConfig c, ServerStatus s, AsyncValue<String> d) {
    final tok = ref.watch(accessTokenProvider);
    return Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.qr_code, color: t.colorScheme.primary), const SizedBox(width: 8), Text('绑定设备', style: t.textTheme.titleMedium)]), const Divider(),
      Text('生成二维码供其他设备扫描绑定', style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)), const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: !s.isRunning ? null : () {
          d.whenData((did) => tok.whenData((tk) => _showQr(ctx, c, did, tk)));
        },
        icon: const Icon(Icons.qr_code), label: Text(s.isRunning ? '显示绑定二维码' : '请先启动服务'),
      )),
    ])));
  }

  void _showQr(BuildContext ctx, ServerConfig c, String did, String tk) async {
    final ips = await _getIps();
    final ip = ips.isNotEmpty ? ips.first : '127.0.0.1';
    final url = 'http://$ip:${c.port}/$did/$tk';
    showDialog(context: ctx, builder: (c) => AlertDialog(
      title: const Text('绑定二维码'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        QrImageView(data: url, version: QrVersions.auto, size: 250, backgroundColor: Colors.white),
        const SizedBox(height: 12),
        Text(ip, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(ctx).colorScheme.primary)),
        const SizedBox(height: 4),
        Text(url, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
      ]),
      actions: [
        TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: url)); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('链接已复制'), behavior: SnackBarBehavior.floating)); }, child: const Text('复制链接')),
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('关闭')),
      ],
    ));
  }

  Widget _logCard(ThemeData t, List<String> logs, WidgetRef ref) => Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(Icons.article, color: t.colorScheme.primary), const SizedBox(width: 8), const Text('服务端日志', style: TextStyle(fontWeight: FontWeight.bold)), const Spacer(), if (logs.isNotEmpty) TextButton(onPressed: () => ref.read(serverLogProvider.notifier).state = [], child: const Text('清除'))]),
    const Divider(),
    if (logs.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('暂无日志', style: TextStyle(color: Colors.grey))))
    else SizedBox(height: 200, child: ListView.builder(itemCount: logs.length, itemBuilder: (_, i) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(logs[i], style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))))),
  ])));

  Widget _netCard(BuildContext ctx, ThemeData t, AppLocalizations l) => Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(Icons.wifi, color: t.colorScheme.primary), const SizedBox(width: 8), Text(l.networkInfo, style: t.textTheme.titleMedium)]), const Divider(),
    FutureBuilder<List<String>>(future: _getIps(), builder: (_, snap) => snap.hasData ? Column(children: snap.data!.map((ip) => _row(l.ipAddress, ip)).toList()) : _row(l.ipAddress, l.detecting)),
  ])));

  Widget _row(String a, String b) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: const TextStyle(color: Colors.grey)), Flexible(child: Text(b, textAlign: TextAlign.end))]));
  Widget _statusRow(String a, bool ok, String x) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: const TextStyle(color: Colors.grey)), Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: ok ? Colors.green : Colors.red)), const SizedBox(width: 8), Text(x)])]));

  String get _os { if (Platform.isWindows) return 'Windows'; if (Platform.isMacOS) return 'macOS'; if (Platform.isLinux) return 'Linux'; if (Platform.isAndroid) return 'Android'; if (Platform.isIOS) return 'iOS'; return 'Unknown'; }
  String get _host { try { return Platform.localHostname; } catch (_) { return 'Unknown'; } }

  Future<List<String>> _getIps() async {
    try { final ips = (await NetworkInterface.list(type: InternetAddressType.IPv4, includeLinkLocal: false)).expand((i) => i.addresses).where((a) => !a.isLoopback).map((a) => a.address).toList(); return ips.isEmpty ? ['127.0.0.1'] : ips; } catch (_) { return ['127.0.0.1']; }
  }
}
