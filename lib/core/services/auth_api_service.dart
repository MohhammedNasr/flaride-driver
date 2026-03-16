import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flaride_driver/core/config/api_config.dart';

class AuthApiService {
  final http.Client _client;
  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  Uri get _authBase => Uri.parse(ApiConfig.authEndpoint);
  Uri get _customers => Uri.parse('${ApiConfig.apiBaseUrl}/customers');

  Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String password,
    String? email,
    String? phone,
  }) async {
    final resp = await _client.post(
      _customers,
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({
        'name': name,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      }),
    );
    final body = _decode(resp);
    _ensureOk(resp, body);
    return body;
  }

  Future<Map<String, dynamic>> checkAvailability({
    String? email,
    String? username,
    String? phoneNumber,
  }) async {
    final resp = await _client.post(
      _authBase.replace(path: '${_authBase.path}/check-availability'),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({
        if (email != null && email.isNotEmpty) 'email': email,
        if (username != null && username.isNotEmpty) 'username': username,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
      }),
    );
    final body = _decode(resp);
    _ensureOk(resp, body);
    return body;
  }

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final resp = await _client.post(
      _authBase.replace(path: '${_authBase.path}/login'),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({
        'identifier': identifier,
        'password': password,
      }),
    );
    final body = _decode(resp);
    _ensureOk(resp, body);
    return body;
  }

  Future<Map<String, dynamic>> forgotPassword({
    String? email,
    String? phoneNumber,
  }) async {
    final resp = await _client.post(
      _authBase.replace(path: '${_authBase.path}/forgot-password'),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({
        if (email != null && email.isNotEmpty) 'email': email,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
      }),
    );
    final body = _decode(resp);
    _ensureOk(resp, body);
    return body;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
  }) async {
    final resp = await _client.post(
      _authBase.replace(path: '${_authBase.path}/reset-password'),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({ 'token': token, 'password': password }),
    );
    final body = _decode(resp);
    _ensureOk(resp, body);
    return body;
  }

  Future<Map<String, dynamic>> getCurrentUser({
    required String jwt,
  }) async {
    final resp = await _client.get(
      _authBase.replace(path: '${_authBase.path}/me'),
      headers: ApiConfig.getAuthHeaders(jwt),
    );
    final body = _decode(resp);
    _ensureOk(resp, body);
    return body;
  }

  Future<Map<String, dynamic>> changePassword({
    required String jwt,
    required String newPassword,
    required String confirmPassword,
    String? currentPassword,
  }) async {
    final resp = await _client.post(
      _authBase.replace(path: '${_authBase.path}/change-password'),
      headers: ApiConfig.getAuthHeaders(jwt),
      body: jsonEncode({
        'new_password': newPassword,
        'confirm_password': confirmPassword,
        if (currentPassword != null) 'current_password': currentPassword,
      }),
    );
    final body = _decode(resp);
    _ensureOk(resp, body);
    return body;
  }

  Map<String, dynamic> _decode(http.Response resp) {
    try {
      return json.decode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return {'raw': resp.body};
    }
  }

  void _ensureOk(http.Response resp, Map<String, dynamic> body) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      final msg = body['error'] ?? body['message'] ?? 'Request failed';
      throw AuthApiException('${resp.statusCode}: $msg');
    }
  }
}

class AuthApiException implements Exception {
  final String message;
  AuthApiException(this.message);
  @override
  String toString() => 'AuthApiException: $message';
}
