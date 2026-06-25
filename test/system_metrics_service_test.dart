import 'package:flutter_test/flutter_test.dart';
import 'package:system_monitor/services/system_metrics_service.dart';

void main() {
  test('cpu temperature parser prefers CPU package sensor', () {
    final snapshot = SystemMetricsService.parseCpuTemperatureOutput('''
Cpu|AMD Ryzen 7|CPU Core #1|61.2
Cpu|AMD Ryzen 7|CPU Package|68.8
GpuNvidia|RTX|GPU Core|54
''');

    expect(snapshot.celsius, 68.8);
    expect(snapshot.label, '69°C');
  });

  test('cpu temperature parser averages CPU core sensors as fallback', () {
    final snapshot = SystemMetricsService.parseCpuTemperatureOutput('''
Cpu|Intel Core|CPU Core #1|60
Cpu|Intel Core|CPU Core #2|64
Cpu|Intel Core|CPU Core #3|62
''');

    expect(snapshot.celsius, 62);
    expect(snapshot.label, '62°C');
  });

  test('cpu temperature parser keeps actionable error status', () {
    final snapshot = SystemMetricsService.parseCpuTemperatureOutput(
      'ERROR|ADMIN_REQUIRED',
    );

    expect(snapshot.celsius, isNull);
    expect(snapshot.label, '需管理员');
  });
}
