import 'package:shared_preferences/shared_preferences.dart';
import 'package:flaride_driver/core/services/auth_api_service.dart';
import 'package:flaride_driver/core/services/secure_storage_service.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  final AuthApiService _api;
  final SecureStorageService _secureStorage;
  
  AuthService() : _api = AuthApiService(), _secureStorage = SecureStorageService();

  // Token management - uses both SharedPreferences (for quick access) and SecureStorage (for security)
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    // Also save to secure storage
    await _secureStorage.saveToken(token);
  }

  Future<String?> getToken() async {
    // Try secure storage first, fallback to shared preferences
    final secureToken = await _secureStorage.getToken();
    if (secureToken != null) return secureToken;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await _secureStorage.deleteToken();
  }

  // Registration
  Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String password,
    String? email,
    String? phone,
  }) async {
    final res = await _api.registerCustomer(name: name, password: password, email: email, phone: phone);
    // Save token if registration successful
    final token = res['token'] as String?;
    if (token != null) await saveToken(token);
    return res;
  }

  // Login (identifier = email | username | phone)
  Future<Map<String, dynamic>> login({required String identifier, required String password}) async {
    final res = await _api.login(identifier: identifier, password: password);
    final token = res['token'] as String?;
    if (token != null) {
      await saveToken(token);
      // Save user data for quick access and secure storage
      final user = res['user'] as Map<String, dynamic>?;
      final role = user?['role'] as String?;
      final userId = user?['id'] as String?;
      
      print('AuthService: Login response user role = $role');
      
      if (role != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', role);
        await _secureStorage.saveUserRole(role);
        print('AuthService: Saved user_role: $role');
      }
      
      // Save email for biometric quick login
      await _secureStorage.saveUserEmail(identifier);
      if (userId != null) {
        await _secureStorage.saveUserId(userId);
      }
    }
    return res;
  }

  Future<void> signOut() async {
    await clearToken();
    // Also clear user role and secure storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await _secureStorage.clearAll();
  }

  // Forgot/Reset password
  Future<Map<String, dynamic>> forgotPassword({String? email, String? phoneNumber}) async {
    return _api.forgotPassword(email: email, phoneNumber: phoneNumber);
  }

  Future<Map<String, dynamic>> resetPassword({required String token, required String password}) async {
    return _api.resetPassword(token: token, password: password);
  }

  // Change password (for first login with temp password or regular password change)
  Future<Map<String, dynamic>> changePassword({
    required String newPassword,
    required String confirmPassword,
    String? currentPassword,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    return _api.changePassword(
      jwt: token,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
      currentPassword: currentPassword,
    );
  }

  // Current user full details
  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final res = await _api.getCurrentUser(jwt: token);
    return res;
  }

  // Simple availability check passthrough
  Future<Map<String, dynamic>> checkAvailability({String? email, String? username, String? phoneNumber}) async {
    return _api.checkAvailability(email: email, username: username, phoneNumber: phoneNumber);
  }
}


