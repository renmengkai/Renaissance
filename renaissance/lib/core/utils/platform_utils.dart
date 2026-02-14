import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtils {
  static bool get isWeb => kIsWeb;

  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  static bool get isLinux {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }

  static bool get supportsWindowManager {
    return isDesktop;
  }

  static bool get supportsDragToMove {
    return isDesktop;
  }

  static bool get supportsKeyboardShortcuts {
    return isDesktop;
  }

  static bool get supportsTouchGestures {
    return isMobile || isWeb;
  }

  static bool get supportsLocalFileSystem {
    if (kIsWeb) return false;
    return true;
  }

  static String get platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
