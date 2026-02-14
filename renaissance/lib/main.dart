import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_session/audio_session.dart';
import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/utils/platform_utils.dart';
import 'core/utils/window_manager_stub.dart'
    if (dart.library.io) 'core/utils/window_manager_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.init();

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  if (PlatformUtils.supportsWindowManager) {
    await initializeWindowManager();
  }

  runApp(
    const ProviderScope(
      child: RenaissanceApp(),
    ),
  );
}
