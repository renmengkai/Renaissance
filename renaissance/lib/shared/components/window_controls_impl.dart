import 'package:window_manager/window_manager.dart';

Future<void> minimizeWindow() async {
  await windowManager.minimize();
}

Future<void> maximizeWindow() async {
  await windowManager.maximize();
}

Future<void> unmaximizeWindow() async {
  await windowManager.unmaximize();
}

Future<void> closeWindow() async {
  await windowManager.close();
}

Future<bool> isWindowMaximized() async {
  return await windowManager.isMaximized();
}
