import 'package:flutter_test/flutter_test.dart';
import 'package:system_monitor/models/system_metrics.dart';

void main() {
  test('byte rate formats bytes per second with readable units', () {
    expect(const ByteRate(bytesPerSecond: 512).label, '512 B/s');
    expect(const ByteRate(bytesPerSecond: 1536).label, '1.5 KB/s');
    expect(const ByteRate(bytesPerSecond: 2.5 * 1024 * 1024).label, '2.5 MB/s');
  });

  test('memory snapshot formats usage label', () {
    const memory = MemorySnapshot(
      totalBytes: 16 * 1024 * 1024 * 1024,
      usedBytes: 10 * 1024 * 1024 * 1024,
    );

    expect(memory.usagePercent, 62.5);
    expect(memory.usageLabel, '62% · 10.0/16.0 GB');
  });

  test('cpu temperature snapshot formats celsius label', () {
    expect(const CpuTemperatureSnapshot(celsius: 63.4).label, '63°C');
    expect(const CpuTemperatureSnapshot(celsius: null).label, '不可用');
    expect(
      const CpuTemperatureSnapshot(celsius: null, statusLabel: '需管理员').label,
      '需管理员',
    );
  });

  test('fallback metrics keeps all tiles renderable', () {
    final metrics = SystemMetrics.fallback('采集失败');

    expect(metrics.cpu.usagePercent, 0);
    expect(metrics.cpuTemperature.label, '不可用');
    expect(metrics.memory.usageLabel, '0% · 0.0/0.0 GB');
    expect(metrics.disk.activityLabel, '0 B/s');
    expect(metrics.network.throughputLabel, '↑ 0 B/s ↓ 0 B/s');
    expect(metrics.power.statusLabel, '电源未知');
    expect(metrics.warning, '采集失败');
  });
}
