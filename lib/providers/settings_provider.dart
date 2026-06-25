import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _alwaysOnTopKey = 'system_monitor.always_on_top';
const _snapToTopOnLaunchKey = 'system_monitor.snap_to_top_on_launch';
const _refreshSecondsKey = 'system_monitor.refresh_seconds';

class MonitorSettings {
  final bool alwaysOnTop;
  final bool snapToTopOnLaunch;
  final Duration refreshInterval;

  const MonitorSettings({
    required this.alwaysOnTop,
    required this.snapToTopOnLaunch,
    required this.refreshInterval,
  });

  factory MonitorSettings.fromPreferences(SharedPreferences prefs) {
    return MonitorSettings(
      alwaysOnTop: prefs.getBool(_alwaysOnTopKey) ?? true,
      snapToTopOnLaunch: prefs.getBool(_snapToTopOnLaunchKey) ?? true,
      refreshInterval: Duration(seconds: prefs.getInt(_refreshSecondsKey) ?? 1),
    );
  }

  MonitorSettings copyWith({
    bool? alwaysOnTop,
    bool? snapToTopOnLaunch,
    Duration? refreshInterval,
  }) {
    return MonitorSettings(
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
      snapToTopOnLaunch: snapToTopOnLaunch ?? this.snapToTopOnLaunch,
      refreshInterval: refreshInterval ?? this.refreshInterval,
    );
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, MonitorSettings>(
      (ref) => SettingsNotifier(ref.watch(sharedPreferencesProvider)),
    );

class SettingsNotifier extends StateNotifier<MonitorSettings> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs)
    : super(MonitorSettings.fromPreferences(_prefs));

  Future<void> setAlwaysOnTop(bool value) async {
    await _prefs.setBool(_alwaysOnTopKey, value);
    state = state.copyWith(alwaysOnTop: value);
  }

  Future<void> setSnapToTopOnLaunch(bool value) async {
    await _prefs.setBool(_snapToTopOnLaunchKey, value);
    state = state.copyWith(snapToTopOnLaunch: value);
  }

  Future<void> setRefreshInterval(Duration value) async {
    await _prefs.setInt(_refreshSecondsKey, value.inSeconds);
    state = state.copyWith(refreshInterval: value);
  }
}
