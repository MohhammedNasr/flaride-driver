import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flaride_driver/core/config/api_config.dart';

class CustomerWaitService {
  static Future<WaitStatus> getWaitStatus(String orderId, String authToken) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/driver/orders/$orderId/wait'),
        headers: ApiConfig.getAuthHeaders(authToken),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WaitStatus.fromJson(data['wait_status']);
      } else {
        throw Exception('Failed to get wait status');
      }
    } catch (e) {
      throw Exception('Error getting wait status: $e');
    }
  }

  static Future<WaitActionResult> performWaitAction({
    required String orderId,
    required String authToken,
    required String action,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/driver/orders/$orderId/wait'),
        headers: ApiConfig.getAuthHeaders(authToken),
        body: json.encode({
          'action': action,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (notes != null) 'notes': notes,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return WaitActionResult(
          success: true,
          message: data['message'] ?? 'Action completed',
          waitMinutes: data['order']?['wait_minutes'] ?? 0,
          waitFee: data['order']?['wait_fee'] ?? 0,
          waitFeeDisplay: data['order']?['wait_fee_display'] ?? '0 CFA',
          status: data['order']?['customer_absence_status'],
        );
      } else {
        return WaitActionResult(
          success: false,
          message: data['error'] ?? 'Action failed',
        );
      }
    } catch (e) {
      return WaitActionResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  static Future<WaitActionResult> markArrived(String orderId, String authToken, {double? lat, double? lng}) async {
    return performWaitAction(
      orderId: orderId,
      authToken: authToken,
      action: 'arrived',
      latitude: lat,
      longitude: lng,
    );
  }

  static Future<WaitActionResult> logContactAttempt(String orderId, String authToken, {String? notes}) async {
    return performWaitAction(
      orderId: orderId,
      authToken: authToken,
      action: 'contact_attempt',
      notes: notes,
    );
  }

  static Future<WaitActionResult> markCustomerNotFound(String orderId, String authToken, {double? lat, double? lng}) async {
    return performWaitAction(
      orderId: orderId,
      authToken: authToken,
      action: 'not_found',
      latitude: lat,
      longitude: lng,
    );
  }

  static Future<WaitActionResult> markCustomerResolved(String orderId, String authToken) async {
    return performWaitAction(
      orderId: orderId,
      authToken: authToken,
      action: 'resolved',
    );
  }
}

class WaitStatus {
  final String orderId;
  final String orderNumber;
  final String status;
  final bool isWaiting;
  final DateTime? waitTimerStartedAt;
  final int waitMinutes;
  final int freeWaitMinutes;
  final int billableMinutes;
  final int waitFee;
  final String waitFeeDisplay;
  final int feePerMinute;
  final String feePerMinuteDisplay;
  final int maxWaitMinutes;
  final bool canMarkNotFound;
  final String? customerAbsenceStatus;
  final int contactAttempts;
  final int maxContactAttempts;

  WaitStatus({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.isWaiting,
    this.waitTimerStartedAt,
    required this.waitMinutes,
    required this.freeWaitMinutes,
    required this.billableMinutes,
    required this.waitFee,
    required this.waitFeeDisplay,
    required this.feePerMinute,
    required this.feePerMinuteDisplay,
    required this.maxWaitMinutes,
    required this.canMarkNotFound,
    this.customerAbsenceStatus,
    required this.contactAttempts,
    required this.maxContactAttempts,
  });

  factory WaitStatus.fromJson(Map<String, dynamic> json) {
    return WaitStatus(
      orderId: json['order_id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? '',
      isWaiting: json['is_waiting'] ?? false,
      waitTimerStartedAt: json['wait_timer_started_at'] != null 
          ? DateTime.parse(json['wait_timer_started_at']) 
          : null,
      waitMinutes: json['wait_minutes'] ?? 0,
      freeWaitMinutes: json['free_wait_minutes'] ?? 7,
      billableMinutes: json['billable_minutes'] ?? 0,
      waitFee: json['wait_fee'] ?? 0,
      waitFeeDisplay: json['wait_fee_display'] ?? '0 CFA',
      feePerMinute: json['fee_per_minute'] ?? 10000,
      feePerMinuteDisplay: json['fee_per_minute_display'] ?? '100 CFA/min',
      maxWaitMinutes: json['max_wait_minutes'] ?? 10,
      canMarkNotFound: json['can_mark_not_found'] ?? false,
      customerAbsenceStatus: json['customer_absence_status'],
      contactAttempts: json['contact_attempts'] ?? 0,
      maxContactAttempts: json['max_contact_attempts'] ?? 3,
    );
  }

  int get remainingFreeMinutes => freeWaitMinutes - waitMinutes > 0 
      ? freeWaitMinutes - waitMinutes 
      : 0;

  int get minutesUntilNotFound => maxWaitMinutes - waitMinutes > 0 
      ? maxWaitMinutes - waitMinutes 
      : 0;

  bool get isInFreePeriod => waitMinutes < freeWaitMinutes;
  bool get isCharging => waitMinutes >= freeWaitMinutes && waitMinutes < maxWaitMinutes;
}

class WaitActionResult {
  final bool success;
  final String message;
  final int waitMinutes;
  final int waitFee;
  final String waitFeeDisplay;
  final String? status;

  WaitActionResult({
    required this.success,
    required this.message,
    this.waitMinutes = 0,
    this.waitFee = 0,
    this.waitFeeDisplay = '0 CFA',
    this.status,
  });
}
