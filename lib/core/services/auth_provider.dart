import 'package:flutter/foundation.dart';
import 'package:flaride_driver/core/services/auth_service.dart';
import 'package:flaride_driver/core/services/auth_state_manager.dart';
import 'package:flaride_driver/core/services/driver_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final AuthStateManager _stateManager;
  final DriverService _driverService = DriverService();
  
  Map<String, dynamic>? _user; // Full user payload from /auth/me
  bool _isLoading = false;
  String? _error;
  bool _hasCompletedOnboarding = false;
  bool _isDriver = false; // Whether user is a driver
  bool _mustChangePassword = false; // Whether driver needs to set new password

  AuthProvider(this._authService)
      : _stateManager = AuthStateManager(_authService) {
    _init();
  }

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSignedIn => _user != null;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isDriver => _isDriver;
  bool get mustChangePassword => _mustChangePassword;
  String? get userRole => _user?['role'] as String?;

  Future<void> _init() async {
    await _loadSession();
  }

  Future<void> _loadSession({bool waitForDriverCheck = false}) async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final me = await _authService.getCurrentUser();
        _user = me['user'];
        final userId = _user?['id'] as String?;
        
        // Load cached states immediately for fast navigation
        await _loadOnboardingStatus();
        await _loadMustChangePasswordStatus();
        _isDriver = await _stateManager.getDriverStatus(userId);
        
        // If waitForDriverCheck is true (during login), check driver status synchronously
        if (waitForDriverCheck) {
          await _checkDriverStatus();
        } else {
          // Notify listeners early so navigation can proceed
          notifyListeners();
          // Update driver status in background (non-blocking)
          _checkDriverStatusInBackground();
        }
      } else {
        _user = null;
        _isDriver = false;
        _hasCompletedOnboarding = false;
        _mustChangePassword = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Session load error: $e');
      _user = null;
      _isDriver = false;
      _hasCompletedOnboarding = false;
      _mustChangePassword = false;
      notifyListeners();
    }
  }

  Future<void> _checkDriverStatus() async {
    try {
      final response = await _driverService.getMyProfile().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Driver status check timed out, using cached value');
          return DriverProfileResponse(
            success: false,
            isDriver: _isDriver,
            message: 'Timeout',
          );
        },
      );
      
      // Only update if we got a successful response
      if (response.success) {
        _isDriver = response.isDriver;
        final userId = _user?['id'] as String?;
        await _stateManager.setDriverStatus(userId, _isDriver);
        debugPrint('Auth: User is driver = $_isDriver');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Check driver status error: $e');
      // Keep cached value, don't override
    }
  }
  
  void _checkDriverStatusInBackground() {
    // Run in background without blocking
    _checkDriverStatus().catchError((e) {
      debugPrint('Background driver status check failed: $e');
    });
  }

  Future<void> _loadOnboardingStatus() async {
    final userId = _user?['id'] as String?;
    _hasCompletedOnboarding = await _stateManager.getOnboardingStatus(userId);
    debugPrint('Auth: Loaded has_completed_onboarding = $_hasCompletedOnboarding for user $userId');
  }

  Future<void> _loadMustChangePasswordStatus() async {
    final userId = _user?['id'] as String?;
    _mustChangePassword = await _stateManager.getMustChangePasswordStatus(userId);
    debugPrint('Auth: Loaded must_change_password = $_mustChangePassword for user $userId');
  }

  Future<void> login({required String identifier, required String password}) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _authService.login(identifier: identifier, password: password);
      // Check if this is a driver with temp password
      _mustChangePassword = response['must_change_password'] == true;
      debugPrint('Auth: must_change_password = $_mustChangePassword');
      // Wait for driver status check during login to ensure correct navigation
      await _loadSession(waitForDriverCheck: true);
      // Persist the mustChangePassword flag and driver status
      final userId = _user?['id'] as String?;
      await _stateManager.setMustChangePasswordStatus(userId, _mustChangePassword);
      await _stateManager.setDriverStatus(userId, _isDriver);
      // Notify listeners after all state is loaded
      notifyListeners();
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerCustomer({
    required String name,
    required String password,
    String? email,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.registerCustomer(name: name, password: password, email: email, phone: phone);
      // Load session after successful registration to set user data
      await _loadSession();
    } catch (e) {
      _setError('Sign up failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    try {
      // Clear persisted flags before signing out
      final userId = _user?['id'] as String?;
      await _stateManager.clearUserState(userId);
      await _authService.signOut();
      _user = null;
      _isDriver = false;
      _mustChangePassword = false;
      _hasCompletedOnboarding = false;
      notifyListeners();
    } catch (e) {
      _setError('Sign out failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Alias for signOut - used for consistency
  Future<void> logout() async => signOut();

  Future<bool> changePassword({
    required String newPassword,
    required String confirmPassword,
    String? currentPassword,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.changePassword(
        newPassword: newPassword,
        confirmPassword: confirmPassword,
        currentPassword: currentPassword,
      );
      // Password changed successfully, clear the flag
      _mustChangePassword = false;
      final userId = _user?['id'] as String?;
      await _stateManager.setMustChangePasswordStatus(userId, false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Password change failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> forgotPassword({String? email, String? phoneNumber}) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.forgotPassword(email: email, phoneNumber: phoneNumber);
    } catch (e) {
      _setError('Password reset request failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markOnboardingCompleted() async {
    final userId = _user?['id'] as String?;
    await _stateManager.setOnboardingStatus(userId, true);
    _hasCompletedOnboarding = true;
    debugPrint('Auth: Marked onboarding as completed for user $userId');
    notifyListeners();
  }

  Future<void> markUserAsNew() async {
    final userId = _user?['id'] as String?;
    await _stateManager.setOnboardingStatus(userId, false);
    _hasCompletedOnboarding = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
