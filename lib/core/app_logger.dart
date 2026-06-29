import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 应用级日志系统
///
/// 桌面端日志写入可执行文件目录 ./data/log/，移动端写入文档目录。
/// 保留最新 5 份，多余自动删除。
class AppLogger {
  static final AppLogger _instance = AppLogger._();
  factory AppLogger() => _instance;
  AppLogger._();

  final List<String> _buffer = [];
  final List<void Function(String)> _listeners = [];
  String? _logDir;
  File? _currentFile;
  IOSink? _sink;
  bool _initialized = false;

  List<String> get entries => List.unmodifiable(_buffer);
  String? get logDir => _logDir;
  void addListener(void Function(String) fn) => _listeners.add(fn);
  void removeListener(void Function(String) fn) => _listeners.remove(fn);

  Future<void> init() async {
    if (_initialized) return;
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // 桌面端：可执行文件同目录 ./data/log/
        _logDir = '${File(Platform.resolvedExecutable).parent.path}/data/log';
      } else {
        // 移动端：应用文档目录
        final docs = await getApplicationDocumentsDirectory();
        _logDir = '${docs.path}/logs';
      }
      final dir = Directory(_logDir!);
      if (!await dir.exists()) await dir.create(recursive: true);
      await _rotate();

      final ts = DateTime.now();
      final name =
          'myriad_${ts.year}${_pad(ts.month)}${_pad(ts.day)}_${_pad(ts.hour)}${_pad(ts.minute)}${_pad(ts.second)}.log';
      _currentFile = File('${_logDir!}/$name');
      _sink = _currentFile!.openWrite(mode: FileMode.append);
      _initialized = true;
      info('AppLogger 已初始化, 日志目录: $_logDir');
    } catch (e) {
      debugPrint('[AppLogger] 初始化失败: $e');
    }
  }

  Future<void> _rotate() async {
    try {
      final dir = Directory(_logDir!);
      if (!await dir.exists()) return;
      final files = (await dir.list().toList())
          .whereType<File>()
          .where((f) => f.path.endsWith('.log'))
          .toList();
      files.sort((a, b) => b.path.compareTo(a.path));
      for (var i = 5; i < files.length; i++) {
        try { await files[i].delete(); } catch (_) {}
      }
    } catch (_) {}
  }

  void log(String level, String msg) {
    final ts = DateTime.now();
    final line =
        '[${ts.year}-${_pad(ts.month)}-${_pad(ts.day)} ${_pad(ts.hour)}:${_pad(ts.minute)}:${_pad(ts.second)}] [$level] $msg';
    debugPrint(line);
    _buffer.add(line);
    if (_buffer.length > 500) _buffer.removeAt(0);
    for (final l in _listeners) { l(line); }
    try { _sink?.writeln(line); } catch (_) {}
  }

  void info(String msg) => log('INFO', msg);
  void warn(String msg) => log('WARN', msg);
  void error(String msg) => log('ERROR', msg);
  void debug(String msg) => log('DEBUG', msg);

  String _pad(int n) => n.toString().padLeft(2, '0');

  Future<void> dispose() async {
    try { await _sink?.flush(); await _sink?.close(); } catch (_) {}
    _initialized = false;
  }
}
