import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flaride_driver/core/config/api_config.dart';

class DeliveryDeadlineService {
  static final DeliveryDeadlineService _instance = DeliveryDeadlineService._internal();
  factory DeliveryDeadlineService() => _instance;
  DeliveryDeadlineService._internal();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Get deadline status for an order
  Future<DeadlineStatus> getDeadlineStatus(
    String orderId, {
    double? driverLat,
    double? driverLng,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final queryParams = <String, String>{};
      if (driverLat != null) queryParams['driver_lat'] = driverLat.toString();
      if (driverLng != null) queryParams['driver_lng'] = driverLng.toString();

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/orders/$orderId/deadline')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeadlineStatus.fromJson(data);
      } else {
        throw Exception('Failed to get deadline status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting deadline status: $e');
    }
  }

  /// Acknowledge the deadline
  Future<bool> acknowledgeDeadline(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/orders/$orderId/deadline'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'action': 'acknowledge'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Notify customer about delay
  Future<bool> notifyDelay(String orderId, {String? reason}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/orders/$orderId/deadline'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'notify_delay',
          'reason': reason,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class DeadlineStatus {
  final String orderId;
  final String status;
  final DeadlineInfo deadline;
  final EtaInfo eta;
  final AlertInfo alerts;
  final TimestampInfo timestamps;

  DeadlineStatus({
    required this.orderId,
    required this.status,
    required this.deadline,
    required this.eta,
    required this.alerts,
    required this.timestamps,
  });

  factory DeadlineStatus.fromJson(Map<String, dynamic> json) {
    return DeadlineStatus(
      orderId: json['order_id'] ?? '',
      status: json['status'] ?? '',
      deadline: DeadlineInfo.fromJson(json['deadline'] ?? {}),
      eta: EtaInfo.fromJson(json['eta'] ?? {}),
      alerts: AlertInfo.fromJson(json['alerts'] ?? {}),
      timestamps: TimestampInfo.fromJson(json['timestamps'] ?? {}),
    );
  }
}

class DeadlineInfo {
  final DateTime? timestamp;
  final int minutesRemaining;
  final int secondsRemaining;
  final bool isLate;
  final bool isAtRisk;
  final bool isApproaching;
  final int delayMinutes;

  DeadlineInfo({
    this.timestamp,
    required this.minutesRemaining,
    required this.secondsRemaining,
    required this.isLate,
    required this.isAtRisk,
    required this.isApproaching,
    required this.delayMinutes,
  });

  factory DeadlineInfo.fromJson(Map<String, dynamic> json) {
    return DeadlineInfo(
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null,
      minutesRemaining: json['minutes_remaining'] ?? 0,
      secondsRemaining: json['seconds_remaining'] ?? 0,
      isLate: json['is_late'] ?? false,
      isAtRisk: json['is_at_risk'] ?? false,
      isApproaching: json['is_approaching'] ?? false,
      delayMinutes: json['delay_minutes'] ?? 0,
    );
  }
}

class EtaInfo {
  final DateTime? timestamp;
  final int prepMinutes;
  final int travelMinutes;
  final int totalMinutes;
  final bool foodReady;

  EtaInfo({
    this.timestamp,
    required this.prepMinutes,
    required this.travelMinutes,
    required this.totalMinutes,
    required this.foodReady,
  });

  factory EtaInfo.fromJson(Map<String, dynamic> json) {
    return EtaInfo(
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null,
      prepMinutes: json['prep_minutes'] ?? 0,
      travelMinutes: json['travel_minutes'] ?? 0,
      totalMinutes: json['total_minutes'] ?? 0,
      foodReady: json['food_ready'] ?? false,
    );
  }
}

class AlertInfo {
  final bool showWarning;
  final bool showCritical;
  final String? warningMessage;

  AlertInfo({
    required this.showWarning,
    required this.showCritical,
    this.warningMessage,
  });

  factory AlertInfo.fromJson(Map<String, dynamic> json) {
    return AlertInfo(
      showWarning: json['show_warning'] ?? false,
      showCritical: json['show_critical'] ?? false,
      warningMessage: json['warning_message'],
    );
  }
}

class TimestampInfo {
  final DateTime? createdAt;
  final DateTime? driverAssignedAt;
  final DateTime? driverPickedUpAt;
  final DateTime? readyForPickupAt;

  TimestampInfo({
    this.createdAt,
    this.driverAssignedAt,
    this.driverPickedUpAt,
    this.readyForPickupAt,
  });

  factory TimestampInfo.fromJson(Map<String, dynamic> json) {
    return TimestampInfo(
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      driverAssignedAt: json['driver_assigned_at'] != null ? DateTime.tryParse(json['driver_assigned_at']) : null,
      driverPickedUpAt: json['driver_picked_up_at'] != null ? DateTime.tryParse(json['driver_picked_up_at']) : null,
      readyForPickupAt: json['ready_for_pickup_at'] != null ? DateTime.tryParse(json['ready_for_pickup_at']) : null,
    );
  }
}
