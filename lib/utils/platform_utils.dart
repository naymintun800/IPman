import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utility class for platform-specific functionality
abstract class PlatformUtils {
  /// Returns true if the current platform is a desktop platform (Windows, macOS, Linux)
  static bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Returns true if the current platform is a mobile platform (Android, iOS)
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Returns true if the current platform is a web platform
  static bool get isWeb => kIsWeb;

  /// Returns true if the current platform is Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Returns true if the current platform is macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Returns true if the current platform is Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Returns true if the current platform is Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Returns true if the current platform is iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;
}
