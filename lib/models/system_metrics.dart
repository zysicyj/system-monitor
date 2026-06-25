class ByteRate {
  final double bytesPerSecond;

  const ByteRate({required this.bytesPerSecond});

  String get label => _formatBytes(bytesPerSecond, suffix: '/s');
}

class CpuSnapshot {
  final double usagePercent;

  const CpuSnapshot({required this.usagePercent});

  String get usageLabel => '${usagePercent.round()}%';
}

class CpuTemperatureSnapshot {
  final double? celsius;
  final String? statusLabel;

  const CpuTemperatureSnapshot({required this.celsius, this.statusLabel});

  String get label {
    final value = celsius;
    if (value == null || value.isNaN || value.isInfinite) {
      return statusLabel ?? '不可用';
    }
    return '${value.round()}°C';
  }
}

class MemorySnapshot {
  final int totalBytes;
  final int usedBytes;

  const MemorySnapshot({required this.totalBytes, required this.usedBytes});

  double get usagePercent => totalBytes == 0 ? 0 : usedBytes / totalBytes * 100;

  String get usageLabel =>
      '${usagePercent.floor()}% · ${_formatGb(usedBytes)}/${_formatGb(totalBytes)} GB';
}

class DiskSnapshot {
  final ByteRate readRate;
  final ByteRate writeRate;

  const DiskSnapshot({required this.readRate, required this.writeRate});

  String get activityLabel => ByteRate(
    bytesPerSecond: readRate.bytesPerSecond + writeRate.bytesPerSecond,
  ).label;
}

class NetworkSnapshot {
  final ByteRate uploadRate;
  final ByteRate downloadRate;

  const NetworkSnapshot({required this.uploadRate, required this.downloadRate});

  String get throughputLabel => '↑ ${uploadRate.label} ↓ ${downloadRate.label}';
}

class PowerSnapshot {
  final int? batteryPercent;
  final bool isCharging;
  final bool isPluggedIn;

  const PowerSnapshot({
    required this.batteryPercent,
    required this.isCharging,
    required this.isPluggedIn,
  });

  String get statusLabel {
    final percent = batteryPercent;
    if (percent == null) return '电源未知';
    if (isCharging) return '$percent% · 充电中';
    if (isPluggedIn) return '$percent% · 已接通电源';
    return '$percent% · 电池供电';
  }
}

class SystemMetrics {
  final CpuSnapshot cpu;
  final CpuTemperatureSnapshot cpuTemperature;
  final MemorySnapshot memory;
  final DiskSnapshot disk;
  final NetworkSnapshot network;
  final PowerSnapshot power;
  final DateTime collectedAt;
  final String? warning;

  const SystemMetrics({
    required this.cpu,
    required this.cpuTemperature,
    required this.memory,
    required this.disk,
    required this.network,
    required this.power,
    required this.collectedAt,
    this.warning,
  });

  factory SystemMetrics.fallback(String warning) {
    return SystemMetrics(
      cpu: const CpuSnapshot(usagePercent: 0),
      cpuTemperature: const CpuTemperatureSnapshot(celsius: null),
      memory: const MemorySnapshot(totalBytes: 0, usedBytes: 0),
      disk: const DiskSnapshot(
        readRate: ByteRate(bytesPerSecond: 0),
        writeRate: ByteRate(bytesPerSecond: 0),
      ),
      network: const NetworkSnapshot(
        uploadRate: ByteRate(bytesPerSecond: 0),
        downloadRate: ByteRate(bytesPerSecond: 0),
      ),
      power: const PowerSnapshot(
        batteryPercent: null,
        isCharging: false,
        isPluggedIn: false,
      ),
      collectedAt: DateTime.now(),
      warning: warning,
    );
  }
}

String _formatBytes(double bytes, {String suffix = ''}) {
  if (bytes < 1024) return '${bytes.round()} B$suffix';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB$suffix';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB$suffix';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(1)} GB$suffix';
}

String _formatGb(int bytes) {
  return (bytes / 1024 / 1024 / 1024).toStringAsFixed(1);
}
