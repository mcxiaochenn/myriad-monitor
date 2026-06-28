import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'core/theme_provider.dart';
import 'features/home/home_page.dart';
import 'features/server/server_page.dart';
import 'features/settings/settings_page.dart';
import 'features/about/about_page.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_provider.dart';

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
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Myriad Monitor',
      // 浅色主题
      theme: AppTheme.lightTheme,
      // 深色主题
      darkTheme: AppTheme.darkTheme,
      // 主题模式（自动/浅色/深色）
      themeMode: themeMode.flutterThemeMode,
      // 国际化配置
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainPage(),
    );
  }
}

/// 主页面
///
/// 包含底栏导航，支持在主页、服务端、配置、关于之间切换
class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentPageIndexProvider);
    final l10n = AppLocalizations.of(context);

    // 页面列表
    final pages = [
      const HomePage(),
      const ServerPage(),
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
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.cloud_outlined),
            selectedIcon: const Icon(Icons.cloud),
            label: l10n.navServer,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.info_outline),
            selectedIcon: const Icon(Icons.info),
            label: l10n.navAbout,
          ),
        ],
      ),
    );
  }
}
