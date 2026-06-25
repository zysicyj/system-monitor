import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../providers/settings_provider.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('设置', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('总在最前'),
            value: settings.alwaysOnTop,
            onChanged: notifier.setAlwaysOnTop,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('启动后贴顶部'),
            value: settings.snapToTopOnLaunch,
            onChanged: notifier.setSnapToTopOnLaunch,
          ),
          const SizedBox(height: 8),
          Text('刷新频率', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final seconds in const [1, 2, 5])
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: () =>
                      notifier.setRefreshInterval(Duration(seconds: seconds)),
                  child: Text('${seconds}s'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
