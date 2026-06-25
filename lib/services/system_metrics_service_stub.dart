import '../models/system_metrics.dart';

class SystemMetricsService {
  const SystemMetricsService();

  static CpuTemperatureSnapshot parseCpuTemperatureOutput(String output) {
    return const CpuTemperatureSnapshot(celsius: null, statusLabel: '平台不支持');
  }

  Future<SystemMetrics> collect() async {
    return SystemMetrics.fallback('当前平台暂不支持系统资源采集');
  }
}
