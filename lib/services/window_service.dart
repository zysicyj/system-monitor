import 'package:flutter/material.dart';
import 'package:shared_package/shared_package.dart';
import 'package:window_manager/window_manager.dart';

class WindowService {
  static final WindowService instance = WindowService._();
  WindowService._();

  Future<void> initialize() async {
    if (!DesktopWindow.isDesktop) return;

    await DesktopWindow.initialize(
      const AppWindowConfig(
        title: 'System Monitor',
        minimumSize: Size(800, 52),
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        center: false,
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: false,
      ),
    );

    await windowManager.setSize(const Size(1280, 52));
    await windowManager.setMinimumSize(const Size(800, 52));
    await windowManager.setAlignment(Alignment.topCenter);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSkipTaskbar(false);
  }

  Future<void> setAlwaysOnTop(bool value) async {
    if (!DesktopWindow.isDesktop) return;
    await windowManager.setAlwaysOnTop(value);
  }
}
