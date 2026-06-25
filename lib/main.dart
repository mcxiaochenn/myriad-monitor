import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/home/home_page.dart';
import 'features/settings/settings_page.dart';
import 'features/about/about_page.dart';

/// 应用程序入口
Future<void> main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Hive 本地存储
  await Hive.initFlutter();

  // 使用 ProviderScope 包裹应用以支持 Riverpod
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// 当前页面索引 Provider
final currentPageIndexProvider = StateProvider<int>((ref) => 0);

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
      home: const MainPage(),
    );
  }
}

/// 主页面
///
/// 包含底栏导航，支持在主页、配置、关于之间切换
class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentPageIndexProvider);

    // 页面列表
    final pages = [
      const HomePage(),
      const SettingsPage(),
      const AboutPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(currentPageIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '主页',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '配置',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: '关于',
          ),
        ],
      ),
    );
  }
}
