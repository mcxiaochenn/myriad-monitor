import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../client/device_manager.dart';
import '../../l10n/app_localizations.dart';

/// 扫一扫添加设备页面
///
/// 支持二维码扫描或手动粘贴连接信息。解析 URL 后验证连通性，
/// 能连上则显示设备信息，确认后导入并持久化到主页。
class ScanPage extends StatefulWidget {
  final Function(ManagedDevice) onDeviceFound;
  const ScanPage({super.key, required this.onDeviceFound});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _pasteCtrl = TextEditingController();
  bool _checking = false;
  String? _result;
  Map<String, dynamic>? _deviceData;

  @override
  void dispose() { _pasteCtrl.dispose(); super.dispose(); }

  Future<void> _parseAndVerify(String input) async {
    setState(() { _checking = true; _result = null; _deviceData = null; });

    try {
      final uri = Uri.tryParse(input.trim());
      if (uri == null || !uri.hasScheme) {
        setState(() { _result = AppLocalizations.of(context).invalidLinkFormat; _checking = false; });
        return;
      }

      final segs = uri.pathSegments;
      if (segs.length < 2) {
        setState(() { _result = AppLocalizations.of(context).linkFormatIncorrect; _checking = false; });
        return;
      }

      final deviceId = segs[segs.length - 2];
      final token = segs.last;
      final ip = uri.host;
      final port = uri.port;

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      // 1. 健康检查
      final healthReq = await client.getUrl(Uri.parse('http://$ip:$port/health'));
      final healthResp = await healthReq.close().timeout(const Duration(seconds: 5));

      if (healthResp.statusCode != 200) {
        setState(() { _result = '设备无响应（${healthResp.statusCode}）'; _checking = false; });
        client.close();
        return;
      }

      // 2. 获取设备信息
      final infoReq = await client.getUrl(Uri.parse('http://$ip:$port/$deviceId/$token'));
      final infoResp = await infoReq.close().timeout(const Duration(seconds: 5));

      if (infoResp.statusCode == 200) {
        final body = await infoResp.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        setState(() {
          _result = '✅ ${AppLocalizations.of(context).deviceConnected}';
          _deviceData = data;
          _checking = false;
        });
      } else if (infoResp.statusCode == 403) {
        setState(() { _result = '⚠️ ${AppLocalizations.of(context).tokenInvalid}'; _checking = false; });
      } else {
        setState(() { _result = '设备异常（${infoResp.statusCode}）'; _checking = false; });
      }
      client.close();
    } catch (e) {
      setState(() { _result = '连接失败: $e'; _checking = false; });
    }
  }

  void _import() {
    if (_deviceData == null) return;
    final data = _deviceData!;
    final uri = Uri.tryParse(_pasteCtrl.text.trim());
    final segs = uri!.pathSegments;
    final device = ManagedDevice(
      deviceId: segs[segs.length - 2],
      name: (data['deviceName'] as String?) ?? 'Unknown',
      ipAddress: uri.host,
      port: uri.port,
      accessToken: segs.last,
      onlineStatus: DeviceOnlineStatus.online,
      discoveredAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
    );
    widget.onDeviceFound(device);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _deviceData;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).scanTitle), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context).scanHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 32),
            TextField(
              controller: _pasteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).scanPasteHint,
                hintText: 'http://192.168.1.100:19191/device-id/token',
                prefixIcon: const Icon(Icons.paste),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _checking ? null : () => _parseAndVerify(_pasteCtrl.text),
                icon: _checking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.wifi_find),
                label: Text(_checking ? AppLocalizations.of(context).verifying : AppLocalizations.of(context).checkConnection),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: Text(_result!, textAlign: TextAlign.center)),
            ],
            // 设备信息预览 + 导入按钮
            if (data != null) ...[
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(AppLocalizations.of(context).deviceInfoPreview, style: theme.textTheme.titleMedium),
                  const Divider(),
                  _row(AppLocalizations.of(context).deviceNameLabel, (data['deviceName'] as String?) ?? '--'),
                  _row('设备 ID', ((data['deviceId'] as String?) ?? '--').length > 16 ? ((data['deviceId'] as String?) ?? '--').substring(0, 8) : ((data['deviceId'] as String?) ?? '--')),
                  _row('CPU 使用率', '${((data['cpuUsage'] as num?) ?? 0).toStringAsFixed(1)}%'),
                  _row('内存', '${_fmtBytes((data['memoryUsed'] as int?) ?? 0)} / ${_fmtBytes((data['memoryTotal'] as int?) ?? 0)}'),
                ])),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _import, icon: const Icon(Icons.download), label: Text(AppLocalizations.of(context).importDevice))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ]),
  );

  String _fmtBytes(int? bytes) {
    if (bytes == null) return '--';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
