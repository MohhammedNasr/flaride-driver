import 'package:flutter/foundation.dart';
import 'package:flaride_driver/core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStateManager {
  static const String _onboardingKeyPrefix = 'has_completed_onboarding_';
  static const String _passwordChangeKeyPrefix = 'must_change_password_';
  static const String _driverStatusKeyPrefix = 'is_driver_';

  final AuthService _authService;

  AuthStateManager(this._authService);

  Future<bool> hasValidToken() async {
    final token = await _authService.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearUserState(String? userId) async {
    if (userId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_passwordChangeKeyPrefix$userId');
    // Don't clear onboarding status - it should persist across sessions
    // await prefs.remove('$_onboardingKeyPrefix$userId');
    await prefs.remove('$_driverStatusKeyPrefix$userId');
  }

  Future<bool> getOnboardingStatus(String? userId) async {
    if (userId == null) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_onboardingKeyPrefix$userId') ?? false;
  }

  Future<void> setOnboardingStatus(String? userId, bool completed) async {
    if (userId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_onboardingKeyPrefix$userId', completed);
    debugPrint('Auth: Saved has_completed_onboarding = $completed for user $userId');
  }

  Future<bool> getMustChangePasswordStatus(String? userId) async {
    if (userId == null) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_passwordChangeKeyPrefix$userId') ?? false;
  }

  Future<void> setMustChangePasswordStatus(String? userId, bool mustChange) async {
    if (userId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_passwordChangeKeyPrefix$userId', mustChange);
    debugPrint('Auth: Saved must_change_password = $mustChange for user $userId');
  }

  Future<bool> getDriverStatus(String? userId) async {
    if (userId == null) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_driverStatusKeyPrefix$userId') ?? false;
  }

  Future<void> setDriverStatus(String? userId, bool isDriver) async {
    if (userId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_driverStatusKeyPrefix$userId', isDriver);
    debugPrint('Auth: Saved is_driver = $isDriver for user $userId');
  }
}
