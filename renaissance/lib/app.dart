import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show MaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/player/ui/pages/splash_page.dart';

class RenaissanceApp extends ConsumerWidget {
  const RenaissanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FluentApp(
      title: '文艺复兴',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        FluentLocalizations.delegate,
      ],
      home: const SplashPage(),
    );
  }
}
