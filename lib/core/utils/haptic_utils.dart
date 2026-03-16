import 'package:flutter/services.dart';

class HapticUtils {
  /// Light haptic feedback for selections and toggles
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback for button presses
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback for important actions
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Selection click feedback
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate for errors or warnings
  static void vibrate() {
    HapticFeedback.vibrate();
  }

  /// Success feedback - light double tap
  static Future<void> success() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
  }

  /// Error feedback - heavy vibration
  static void error() {
    HapticFeedback.heavyImpact();
  }

  /// New order notification feedback
  static Future<void> newOrder() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.lightImpact();
  }

  /// Order accepted feedback
  static Future<void> orderAccepted() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
  }
}
