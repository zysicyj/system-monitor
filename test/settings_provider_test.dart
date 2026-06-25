import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_monitor/providers/settings_provider.dart';

void main() {
  test('settings provider uses default monitor settings', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final settings = container.read(settingsProvider);

    expect(settings.alwaysOnTop, isTrue);
    expect(settings.snapToTopOnLaunch, isTrue);
    expect(settings.refreshInterval, const Duration(seconds: 1));
  });

  test(
    'settings provider persists always on top and refresh interval',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      await notifier.setAlwaysOnTop(false);
      await notifier.setRefreshInterval(const Duration(seconds: 5));

      expect(container.read(settingsProvider).alwaysOnTop, isFalse);
      expect(
        container.read(settingsProvider).refreshInterval,
        const Duration(seconds: 5),
      );
      expect(prefs.getBool('system_monitor.always_on_top'), isFalse);
      expect(prefs.getInt('system_monitor.refresh_seconds'), 5);
    },
  );
}
