import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_package/shared_package.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/settings_provider.dart';
import 'screens/top_monitor_bar_screen.dart';
import 'services/window_service.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      BrandRegistry.instance.register(
        brandName: 'system-monitor',
        seedColor: const Color(0xFF22C55E),
      );

      await AppLogger.initialize(launchContext: 'system_monitor');
      AppLogger.installConsoleCapture();

      await WindowService.instance.initialize();
      final prefs = await SharedPreferences.getInstance();
      runApp(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const SystemMonitorApp(),
        ),
      );
    },
    (error, stackTrace) {
      AppLogger.error('未捕获的异步错误', error: error, stackTrace: stackTrace);
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        AppLogger.captureConsolePrint(line);
      },
    ),
  );
}

class SystemMonitorApp extends ConsumerWidget {
  const SystemMonitorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShadApp.custom(
      theme: ShadThemeData(colorScheme: const ShadGreenColorScheme.light()),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadGreenColorScheme.dark(),
      ),
      themeMode: ThemeMode.system,
      appBuilder: (context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'System Monitor',
        theme: Theme.of(context),
        darkTheme: Theme.of(context),
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          GlobalShadLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        builder: (context, child) => ShadAppBuilder(child: child!),
        home: const TopMonitorBarScreen(),
      ),
    );
  }
}
