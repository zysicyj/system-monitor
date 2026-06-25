import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/system_metrics.dart';

class SystemMetricsService {
  const SystemMetricsService();

  static CpuTemperatureSnapshot parseCpuTemperatureOutput(String output) {
    final packageValues = <double>[];
    final coreValues = <double>[];
    final cpuValues = <double>[];

    for (final rawLine in output.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('ERROR|')) {
        final message = line.substring('ERROR|'.length).trim();
        return CpuTemperatureSnapshot(
          celsius: null,
          statusLabel: _temperatureStatusFromError(message),
        );
      }

      final parts = line.split('|');
      if (parts.length < 4) continue;
      final hardwareType = parts[0].trim().toLowerCase();
      final sensorName = parts[2].trim().toLowerCase();
      if (!hardwareType.contains('cpu')) continue;

      final value = double.tryParse(parts[3].trim().replaceAll(',', '.'));
      if (value == null || value <= 0 || value >= 125) continue;

      cpuValues.add(value);
      if (sensorName.contains('package') ||
          sensorName.contains('tctl') ||
          sensorName.contains('tdie')) {
        packageValues.add(value);
      } else if (sensorName.contains('core')) {
        coreValues.add(value);
      }
    }

    if (packageValues.isNotEmpty) {
      return CpuTemperatureSnapshot(celsius: _average(packageValues));
    }
    if (coreValues.isNotEmpty) {
      return CpuTemperatureSnapshot(celsius: _average(coreValues));
    }
    if (cpuValues.isNotEmpty) {
      return CpuTemperatureSnapshot(celsius: _average(cpuValues));
    }

    return const CpuTemperatureSnapshot(celsius: null, statusLabel: '无传感器');
  }

  Future<SystemMetrics> collect() async {
    try {
      final results = await Future.wait([
        _collectCpu(),
        _collectCpuTemperature(),
        _collectMemory(),
        _collectDisk(),
        _collectNetwork(),
        _collectPower(),
      ]);

      return SystemMetrics(
        cpu: results[0] as CpuSnapshot,
        cpuTemperature: results[1] as CpuTemperatureSnapshot,
        memory: results[2] as MemorySnapshot,
        disk: results[3] as DiskSnapshot,
        network: results[4] as NetworkSnapshot,
        power: results[5] as PowerSnapshot,
        collectedAt: DateTime.now(),
      );
    } catch (e) {
      return SystemMetrics.fallback('采集失败: $e');
    }
  }

  Future<CpuSnapshot> _collectCpu() async {
    final output = await _runPowerShell(
      '(Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average',
    );
    return CpuSnapshot(usagePercent: double.tryParse(output.trim()) ?? 0);
  }

  Future<CpuTemperatureSnapshot> _collectCpuTemperature() async {
    final hardwareSensor = await _collectCpuTemperatureWithHardwareMonitor();
    if (hardwareSensor.celsius != null) return hardwareSensor;

    final acpiSensor = await _collectCpuTemperatureWithAcpi();
    if (acpiSensor.celsius != null) return acpiSensor;

    return hardwareSensor;
  }

  Future<CpuTemperatureSnapshot>
  _collectCpuTemperatureWithHardwareMonitor() async {
    final scriptPath = _hardwareMonitorScriptPath();
    if (!File(scriptPath).existsSync()) {
      return const CpuTemperatureSnapshot(celsius: null, statusLabel: '缺少采集器');
    }

    try {
      final output = await _runPowerShellFile(
        scriptPath,
        timeout: const Duration(seconds: 6),
      );
      return parseCpuTemperatureOutput(output);
    } on TimeoutException {
      return const CpuTemperatureSnapshot(celsius: null, statusLabel: '采集超时');
    } catch (e) {
      return CpuTemperatureSnapshot(
        celsius: null,
        statusLabel: _temperatureStatusFromError(e.toString()),
      );
    }
  }

  Future<CpuTemperatureSnapshot> _collectCpuTemperatureWithAcpi() async {
    try {
      final output = await _runPowerShell(
        r'$temps=Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue | ForEach-Object {[math]::Round(($_.CurrentTemperature / 10) - 273.15, 1)} | Where-Object {$_ -gt 0 -and $_ -lt 125}; if ($temps) { [math]::Round(($temps | Measure-Object -Average).Average, 1) } else { "" }',
      );
      return CpuTemperatureSnapshot(celsius: double.tryParse(output.trim()));
    } catch (_) {
      return const CpuTemperatureSnapshot(celsius: null);
    }
  }

  Future<MemorySnapshot> _collectMemory() async {
    final output = await _runPowerShell(
      r'$os=Get-CimInstance Win32_OperatingSystem; "{0},{1}" -f $os.TotalVisibleMemorySize,$os.FreePhysicalMemory',
    );
    final parts = output.trim().split(',');
    final totalKb = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final freeKb = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    final totalBytes = totalKb * 1024;
    final usedBytes = (totalKb - freeKb).clamp(0, totalKb) * 1024;
    return MemorySnapshot(totalBytes: totalBytes, usedBytes: usedBytes);
  }

  Future<DiskSnapshot> _collectDisk() async {
    final output = await _runPowerShell(
      r'$c=Get-Counter "\PhysicalDisk(_Total)\Disk Read Bytes/sec","\PhysicalDisk(_Total)\Disk Write Bytes/sec"; ($c.CounterSamples | ForEach-Object {[math]::Round($_.CookedValue,0)}) -join ","',
    );
    final parts = output.trim().split(',');
    return DiskSnapshot(
      readRate: ByteRate(
        bytesPerSecond: double.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0,
      ),
      writeRate: ByteRate(
        bytesPerSecond: double.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
      ),
    );
  }

  Future<NetworkSnapshot> _collectNetwork() async {
    final output = await _runPowerShell(
      r'$c=Get-Counter "\Network Interface(*)\Bytes Sent/sec","\Network Interface(*)\Bytes Received/sec"; $sent=($c.CounterSamples | Where-Object {$_.Path -like "*bytes sent/sec"} | Measure-Object CookedValue -Sum).Sum; $recv=($c.CounterSamples | Where-Object {$_.Path -like "*bytes received/sec"} | Measure-Object CookedValue -Sum).Sum; "{0},{1}" -f [math]::Round($sent,0),[math]::Round($recv,0)',
    );
    final parts = output.trim().split(',');
    return NetworkSnapshot(
      uploadRate: ByteRate(
        bytesPerSecond: double.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0,
      ),
      downloadRate: ByteRate(
        bytesPerSecond: double.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
      ),
    );
  }

  Future<PowerSnapshot> _collectPower() async {
    final output = await _runPowerShell(
      r'$b=Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1; if ($null -eq $b) { "-1,False,True" } else { "{0},{1},{2}" -f $b.EstimatedChargeRemaining,($b.BatteryStatus -eq 6),($b.BatteryStatus -in 2,6,7,8,9) }',
    );
    final parts = output.trim().split(',');
    final percent = int.tryParse(parts.isNotEmpty ? parts[0] : '');
    return PowerSnapshot(
      batteryPercent: percent == null || percent < 0 ? null : percent,
      isCharging: parts.length > 1 && parts[1].toLowerCase() == 'true',
      isPluggedIn: parts.length > 2 && parts[2].toLowerCase() == 'true',
    );
  }

  Future<String> _runPowerShell(String script) async {
    final result = await Process.run(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    ).timeout(const Duration(seconds: 4));

    if (result.exitCode != 0) {
      throw StateError((result.stderr as String).trim());
    }
    return result.stdout as String;
  }

  Future<String> _runPowerShellFile(
    String scriptPath, {
    required Duration timeout,
  }) async {
    final process = await Process.start('powershell', [
      '-NoProfile',
      '-WindowStyle',
      'Hidden',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      scriptPath,
    ]);

    final stdout = process.stdout.transform(utf8.decoder).join();
    final stderr = process.stderr.transform(utf8.decoder).join();

    int exitCode;
    try {
      exitCode = await process.exitCode.timeout(timeout);
    } on TimeoutException {
      process.kill();
      rethrow;
    }

    final output = await stdout;
    final error = await stderr;
    if (exitCode != 0) {
      throw StateError(error.trim().isEmpty ? output.trim() : error.trim());
    }
    return output;
  }

  String _hardwareMonitorScriptPath() {
    final executableDir = File(Platform.resolvedExecutable).parent.path;
    return _joinPath(
      _joinPath(executableDir, 'hardware_monitor'),
      'read_cpu_temperature.ps1',
    );
  }
}

double _average(List<double> values) =>
    values.reduce((sum, value) => sum + value) / values.length;

String _temperatureStatusFromError(String error) {
  final normalized = error.toLowerCase();
  if (normalized.contains('access') ||
      normalized.contains('denied') ||
      normalized.contains('admin') ||
      normalized.contains('privilege') ||
      normalized.contains('administrator') ||
      normalized.contains('unauthorized') ||
      normalized.contains('admin_required') ||
      error.contains('管理员') ||
      error.contains('权限') ||
      error.contains('拒绝')) {
    return '需管理员';
  }
  if (error.trim().isEmpty) return '无传感器';
  return '采集失败';
}

String _joinPath(String first, String second) {
  final separator = Platform.pathSeparator;
  if (first.endsWith(separator)) return '$first$second';
  return '$first$separator$second';
}
