import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_package/shared_package.dart';
import 'package:window_manager/window_manager.dart';

import '../models/system_metrics.dart';
import '../providers/metrics_provider.dart';
import '../providers/settings_provider.dart';
import '../services/window_service.dart';
import '../widgets/metric_tile.dart';
import 'settings_screen.dart';

class TopMonitorBarScreen extends ConsumerWidget {
  const TopMonitorBarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.alwaysOnTop != next.alwaysOnTop) {
        WindowService.instance.setAlwaysOnTop(next.alwaysOnTop);
      }
    });

    final metrics = ref.watch(metricsProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        bottom: false,
        child: DragToMoveArea(child: _MonitorContent(metrics: metrics)),
      ),
    );
  }
}

class _MonitorContent extends ConsumerWidget {
  final AsyncValue<SystemMetrics> metrics;

  const _MonitorContent({required this.metrics});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = metrics.valueOrNull ?? SystemMetrics.fallback('正在采集');
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Material(
      color: AppColors.background(context).withValues(alpha: 0.98),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.background(context).withValues(alpha: 0.98),
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider(context).withValues(alpha: 0.72),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface(context).withValues(alpha: 0.82),
                  borderRadius: AppSpacing.radiusAllMd,
                  border: Border.all(
                    color: AppColors.border(context).withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricSlot(
                        key: const ValueKey('metric-cpu'),
                        child: MetricTile(
                          title: 'CPU',
                          value: value.cpu.usageLabel,
                          accentColor: AppColors.accentBlue,
                        ),
                      ),
                    ),
                    const _MetricSeparator(),
                    Expanded(
                      child: _MetricSlot(
                        key: const ValueKey('metric-temperature'),
                        child: MetricTile(
                          title: '温度',
                          value: value.cpuTemperature.label,
                          accentColor: AppColors.accentRed,
                        ),
                      ),
                    ),
                    const _MetricSeparator(),
                    Expanded(
                      child: _MetricSlot(
                        key: const ValueKey('metric-memory'),
                        child: MetricTile(
                          title: '内存',
                          value: value.memory.usageLabel,
                          accentColor: AppColors.accentTeal,
                        ),
                      ),
                    ),
                    const _MetricSeparator(),
                    Expanded(
                      child: _MetricSlot(
                        key: const ValueKey('metric-disk'),
                        child: MetricTile(
                          title: '磁盘',
                          value: value.disk.activityLabel,
                          accentColor: AppColors.accentAmber,
                        ),
                      ),
                    ),
                    const _MetricSeparator(),
                    Expanded(
                      child: _MetricSlot(
                        key: const ValueKey('metric-network'),
                        child: MetricTile(
                          title: '网络',
                          value: value.network.throughputLabel,
                          accentColor: AppColors.accentGreen,
                        ),
                      ),
                    ),
                    const _MetricSeparator(),
                    Expanded(
                      child: _MetricSlot(
                        key: const ValueKey('metric-power'),
                        child: MetricTile(
                          title: '电源',
                          value: value.power.statusLabel,
                          accentColor: AppColors.accentCyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (value.warning != null)
              Tooltip(
                message: value.warning!,
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.radiusAllSm,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                    size: 17,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            _ToolbarIconButton(
              tooltip: settings.alwaysOnTop ? '取消置顶' : '置顶窗口',
              icon: settings.alwaysOnTop
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              selected: settings.alwaysOnTop,
              onPressed: () =>
                  settingsNotifier.setAlwaysOnTop(!settings.alwaysOnTop),
            ),
            const SizedBox(width: AppSpacing.xs),
            _ToolbarIconButton(
              tooltip: '设置',
              icon: Icons.settings_rounded,
              onPressed: () => _showSettings(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSettings(BuildContext context) async {
    await showShadDialog<void>(
      context: context,
      builder: (context) => ShadDialog(
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
        child: const SettingsSheet(),
      ),
    );
  }
}

class _MetricSlot extends StatelessWidget {
  final Widget child;

  const _MetricSlot({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: child);
  }
}

class _MetricSeparator extends StatelessWidget {
  const _MetricSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      color: AppColors.divider(context).withValues(alpha: 0.6),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;

  const _ToolbarIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 44,
        height: 34,
        child: ShadButton.ghost(
          size: ShadButtonSize.sm,
          onPressed: onPressed,
          child: Icon(
            icon,
            size: 17,
            color: selected
                ? AppColors.accentGreen
                : AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }
}
