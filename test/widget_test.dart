import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:system_monitor/models/system_metrics.dart';
import 'package:system_monitor/providers/metrics_provider.dart';
import 'package:system_monitor/providers/settings_provider.dart';
import 'package:system_monitor/screens/top_monitor_bar_screen.dart';
import 'package:system_monitor/services/system_metrics_service.dart';

class FakeSystemMetricsService implements SystemMetricsService {
  @override
  Future<SystemMetrics> collect() async {
    return SystemMetrics(
      cpu: const CpuSnapshot(usagePercent: 32),
      cpuTemperature: const CpuTemperatureSnapshot(celsius: 63.4),
      memory: const MemorySnapshot(
        totalBytes: 16 * 1024 * 1024 * 1024,
        usedBytes: 8 * 1024 * 1024 * 1024,
      ),
      disk: const DiskSnapshot(
        readRate: ByteRate(bytesPerSecond: 1024 * 1024),
        writeRate: ByteRate(bytesPerSecond: 2 * 1024 * 1024),
      ),
      network: const NetworkSnapshot(
        uploadRate: ByteRate(bytesPerSecond: 1024),
        downloadRate: ByteRate(bytesPerSecond: 2048),
      ),
      power: const PowerSnapshot(
        batteryPercent: 86,
        isCharging: true,
        isPluggedIn: true,
      ),
      collectedAt: DateTime(2026, 6, 22),
    );
  }
}

void main() {
  testWidgets(
    'top monitor bar renders six resource tiles and settings action',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            systemMetricsServiceProvider.overrideWithValue(
              FakeSystemMetricsService(),
            ),
          ],
          child: ShadApp.custom(
            theme: ShadThemeData(
              colorScheme: const ShadGreenColorScheme.light(),
            ),
            appBuilder: (context) =>
                const MaterialApp(home: TopMonitorBarScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CPU'), findsOneWidget);
      expect(find.text('温度'), findsOneWidget);
      expect(find.text('内存'), findsOneWidget);
      expect(find.text('磁盘'), findsOneWidget);
      expect(find.text('网络'), findsOneWidget);
      expect(find.text('电源'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    },
  );

  testWidgets('top monitor bar tiles share the available width evenly', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          systemMetricsServiceProvider.overrideWithValue(
            FakeSystemMetricsService(),
          ),
        ],
        child: ShadApp.custom(
          theme: ShadThemeData(colorScheme: const ShadGreenColorScheme.light()),
          appBuilder: (context) =>
              const MaterialApp(home: TopMonitorBarScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cpuWidth = tester
        .getSize(find.byKey(const ValueKey('metric-cpu')))
        .width;
    final memoryWidth = tester
        .getSize(find.byKey(const ValueKey('metric-memory')))
        .width;
    final temperatureWidth = tester
        .getSize(find.byKey(const ValueKey('metric-temperature')))
        .width;
    final diskWidth = tester
        .getSize(find.byKey(const ValueKey('metric-disk')))
        .width;
    final networkWidth = tester
        .getSize(find.byKey(const ValueKey('metric-network')))
        .width;
    final powerWidth = tester
        .getSize(find.byKey(const ValueKey('metric-power')))
        .width;

    expect(memoryWidth, cpuWidth);
    expect(temperatureWidth, cpuWidth);
    expect(diskWidth, cpuWidth);
    expect(networkWidth, cpuWidth);
    expect(powerWidth, cpuWidth);
  });
}
