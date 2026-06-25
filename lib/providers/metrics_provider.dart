import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/system_metrics.dart';
import '../services/system_metrics_service.dart';
import 'settings_provider.dart';

final systemMetricsServiceProvider = Provider<SystemMetricsService>((ref) {
  return const SystemMetricsService();
});

final metricsProvider =
    StateNotifierProvider<MetricsNotifier, AsyncValue<SystemMetrics>>((ref) {
      return MetricsNotifier(
        service: ref.watch(systemMetricsServiceProvider),
        refreshInterval: ref.watch(settingsProvider).refreshInterval,
      );
    });

class MetricsNotifier extends StateNotifier<AsyncValue<SystemMetrics>> {
  final SystemMetricsService _service;
  final Duration _refreshInterval;
  Timer? _timer;

  MetricsNotifier({
    required SystemMetricsService service,
    required Duration refreshInterval,
  }) : _service = service,
       _refreshInterval = refreshInterval,
       super(AsyncValue.data(SystemMetrics.fallback('正在采集'))) {
    refresh();
    _timer = Timer.periodic(_refreshInterval, (_) => refresh());
  }

  Future<void> refresh() async {
    try {
      state = AsyncValue.data(await _service.collect());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
