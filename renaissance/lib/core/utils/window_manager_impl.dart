import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'platform_utils.dart';

Future<void> initializeWindowManager() async {
  if (!PlatformUtils.isDesktop) return;

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1400, 900),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
