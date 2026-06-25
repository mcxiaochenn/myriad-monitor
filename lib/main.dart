import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/home/home_page.dart';

/// 应用程序入口
void main() {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 使用 ProviderScope 包裹应用以支持 Riverpod
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// 应用根组件
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Myriad Monitor',
      // 暗色主题配置
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      // 明亮主题配置
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      // 跟随系统主题
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

