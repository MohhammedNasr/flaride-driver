import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flaride_driver/core/config/api_config.dart';

class StopRequestsService {
  static final StopRequestsService _instance = StopRequestsService._internal();
  factory StopRequestsService() => _instance;
  StopRequestsService._internal();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Get current stop requests status
  Future<StopRequestsStatus> getStatus() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/driver/stop-requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StopRequestsStatus.fromJson(data);
      } else {
        throw Exception('Failed to get status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting stop requests status: $e');
    }
  }

  /// Toggle stop new requests
  Future<StopRequestsStatus> toggleStopRequests({
    required bool stopNewRequests,
    int? autoResumeMinutes,
    String? reason,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final body = {
        'stop_new_requests': stopNewRequests,
      };

      if (autoResumeMinutes != null && autoResumeMinutes > 0) {
        body['auto_resume_minutes'] = autoResumeMinutes;
      }

      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/driver/stop-requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StopRequestsStatus(
          stopNewRequests: data['stop_new_requests'] ?? false,
          stopRequestsAt: data['stop_requests_at'] != null
              ? DateTime.tryParse(data['stop_requests_at'])
              : null,
          autoResumeRequestsAt: data['auto_resume_requests_at'] != null
              ? DateTime.tryParse(data['auto_resume_requests_at'])
              : null,
          message: data['message'],
        );
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to toggle stop requests');
      }
    } catch (e) {
      throw Exception('Error toggling stop requests: $e');
    }
  }

  /// Stop new requests
  Future<StopRequestsStatus> stopRequests({
    int? autoResumeMinutes,
    String? reason,
  }) async {
    return toggleStopRequests(
      stopNewRequests: true,
      autoResumeMinutes: autoResumeMinutes,
      reason: reason,
    );
  }

  /// Resume accepting requests
  Future<StopRequestsStatus> resumeRequests() async {
    return toggleStopRequests(stopNewRequests: false);
  }
}

class StopRequestsStatus {
  final bool stopNewRequests;
  final DateTime? stopRequestsAt;
  final DateTime? autoResumeRequestsAt;
  final String? stopRequestsReason;
  final bool isOnline;
  final bool isAvailable;
  final bool hasActiveOrder;
  final String? message;

  StopRequestsStatus({
    required this.stopNewRequests,
    this.stopRequestsAt,
    this.autoResumeRequestsAt,
    this.stopRequestsReason,
    this.isOnline = true,
    this.isAvailable = true,
    this.hasActiveOrder = false,
    this.message,
  });

  factory StopRequestsStatus.fromJson(Map<String, dynamic> json) {
    return StopRequestsStatus(
      stopNewRequests: json['stop_new_requests'] ?? false,
      stopRequestsAt: json['stop_requests_at'] != null
          ? DateTime.tryParse(json['stop_requests_at'])
          : null,
      autoResumeRequestsAt: json['auto_resume_requests_at'] != null
          ? DateTime.tryParse(json['auto_resume_requests_at'])
          : null,
      stopRequestsReason: json['stop_requests_reason'],
      isOnline: json['is_online'] ?? true,
      isAvailable: json['is_available'] ?? true,
      hasActiveOrder: json['has_active_order'] ?? false,
      message: json['message'],
    );
  }

  /// Time remaining until auto-resume (in seconds)
  int? get autoResumeSecondsRemaining {
    if (autoResumeRequestsAt == null) return null;
    final diff = autoResumeRequestsAt!.difference(DateTime.now());
    return diff.inSeconds > 0 ? diff.inSeconds : 0;
  }

  /// Formatted time remaining
  String? get autoResumeTimeRemaining {
    final seconds = autoResumeSecondsRemaining;
    if (seconds == null || seconds <= 0) return null;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes min ${secs}s';
    }
    return '${secs}s';
  }
}
