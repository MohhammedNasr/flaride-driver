import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flaride_driver/core/config/api_config.dart';
import 'package:flaride_driver/core/models/trip.dart';

class DispatchService {
  final String _baseUrl = ApiConfig.apiBaseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Map<String, String> _authHeaders(String token) => {
    ...ApiConfig.defaultHeaders,
    'Authorization': 'Bearer $token',
  };

  // ── Get Current Offer ──────────────────────────────────────────────

  Future<OfferResponse> getCurrentOffer() async {
    try {
      final token = await _getToken();
      if (token == null) return OfferResponse(hasOffer: false);

      final response = await http.get(
        Uri.parse('$_baseUrl/driver/rides/offer'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OfferResponse(
          hasOffer: data['has_offer'] ?? false,
          offer: data['has_offer'] == true && data['offer'] != null
              ? RideOffer.fromJson(data['offer'])
              : null,
        );
      }
      return OfferResponse(hasOffer: false);
    } catch (e) {
      debugPrint('Get offer exception: $e');
      return OfferResponse(hasOffer: false);
    }
  }

  // ── Accept / Reject Offer ──────────────────────────────────────────

  Future<OfferActionResult> respondToOffer({
    required String offerId,
    required String action, // 'accept' | 'reject'
    String? rejectionReason,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return OfferActionResult(success: false, errorMessage: 'Not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/driver/rides/offer'),
        headers: _authHeaders(token),
        body: json.encode({
          'offer_id': offerId,
          'response': action,
          if (rejectionReason != null) 'rejection_reason': rejectionReason,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return OfferActionResult(
          success: true,
          tripId: data['trip_id'],
          driverId: data['driver_id'],
          status: data['status'],
        );
      }

      return OfferActionResult(success: false, errorMessage: data['error'] ?? 'Action failed');
    } catch (e) {
      debugPrint('Offer response exception: $e');
      return OfferActionResult(success: false, errorMessage: 'Network error');
    }
  }

  // ── Get Current Trip ───────────────────────────────────────────────

  Future<CurrentTripResponse> getCurrentTrip() async {
    try {
      final token = await _getToken();
      if (token == null) return CurrentTripResponse(hasActiveTrip: false);

      final response = await http.get(
        Uri.parse('$_baseUrl/driver/rides/current'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CurrentTripResponse(
          hasActiveTrip: data['has_active_trip'] ?? false,
          trip: data['has_active_trip'] == true && data['trip'] != null
              ? DriverTrip.fromJson(data['trip'])
              : null,
          hasPreAssigned: data['has_pre_assigned'] ?? false,
          preAssignedTripId: data['pre_assigned_trip_id'],
        );
      }
      return CurrentTripResponse(hasActiveTrip: false);
    } catch (e) {
      debugPrint('Get current trip exception: $e');
      return CurrentTripResponse(hasActiveTrip: false);
    }
  }

  // ── Trip Actions ───────────────────────────────────────────────────

  Future<ActionResult> markArrived(String tripId) async {
    try {
      final token = await _getToken();
      if (token == null) return ActionResult(success: false, errorMessage: 'Not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/rides/$tripId/arrived'),
        headers: _authHeaders(token),
      );

      final data = json.decode(response.body);
      return ActionResult(
        success: response.statusCode == 200,
        status: data['status'],
        errorMessage: response.statusCode != 200 ? (data['error'] ?? 'Failed') : null,
      );
    } catch (e) {
      debugPrint('Mark arrived exception: $e');
      return ActionResult(success: false, errorMessage: 'Network error');
    }
  }

  Future<ActionResult> startRide(String tripId) async {
    try {
      final token = await _getToken();
      if (token == null) return ActionResult(success: false, errorMessage: 'Not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/rides/$tripId/start'),
        headers: _authHeaders(token),
      );

      final data = json.decode(response.body);
      return ActionResult(
        success: response.statusCode == 200,
        status: data['status'],
        errorMessage: response.statusCode != 200 ? (data['error'] ?? 'Failed') : null,
      );
    } catch (e) {
      debugPrint('Start ride exception: $e');
      return ActionResult(success: false, errorMessage: 'Network error');
    }
  }

  Future<TripCompleteResult> completeRide(String tripId, {double? actualDistanceKm, double? actualDurationMin}) async {
    try {
      final token = await _getToken();
      if (token == null) return TripCompleteResult(success: false, errorMessage: 'Not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/rides/$tripId/complete'),
        headers: _authHeaders(token),
        body: json.encode({
          if (actualDistanceKm != null) 'actual_distance_km': actualDistanceKm,
          if (actualDurationMin != null) 'actual_duration_min': actualDurationMin,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return TripCompleteResult(
          success: true,
          actualFare: data['actual_fare'] ?? 0,
          driverEarnings: data['driver_earnings'] ?? 0,
          bonusTotal: data['bonus_total'] ?? 0,
          bonuses: (data['bonuses'] as List?)?.map((b) => BonusItem.fromJson(b)).toList() ?? [],
          currency: data['currency'] ?? 'XOF',
        );
      }

      return TripCompleteResult(success: false, errorMessage: data['error'] ?? 'Failed');
    } catch (e) {
      debugPrint('Complete ride exception: $e');
      return TripCompleteResult(success: false, errorMessage: 'Network error');
    }
  }

  // ── Cancel ─────────────────────────────────────────────────────────

  Future<ActionResult> cancelRide(String tripId, {String? reason}) async {
    try {
      final token = await _getToken();
      if (token == null) return ActionResult(success: false, errorMessage: 'Not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/driver/rides/cancel'),
        headers: _authHeaders(token),
        body: json.encode({
          'trip_id': tripId,
          if (reason != null) 'reason': reason,
        }),
      );

      final data = json.decode(response.body);
      return ActionResult(
        success: response.statusCode == 200,
        status: data['reassign_status'],
        errorMessage: response.statusCode != 200 ? (data['error'] ?? 'Failed') : null,
      );
    } catch (e) {
      debugPrint('Cancel ride exception: $e');
      return ActionResult(success: false, errorMessage: 'Network error');
    }
  }

  // ── No-Show ────────────────────────────────────────────────────────

  Future<ActionResult> reportNoShow({
    required String tripId,
    required DateTime waitStartedAt,
    required int callsMade,
    required int smsSent,
    required int waitDurationSec,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return ActionResult(success: false, errorMessage: 'Not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/driver/rides/no-show'),
        headers: _authHeaders(token),
        body: json.encode({
          'trip_id': tripId,
          'wait_started_at': waitStartedAt.toIso8601String(),
          'calls_made': callsMade,
          'sms_sent': smsSent,
          'wait_duration_sec': waitDurationSec,
        }),
      );

      final data = json.decode(response.body);
      return ActionResult(
        success: response.statusCode == 200,
        errorMessage: response.statusCode != 200 ? (data['error'] ?? 'Failed') : null,
      );
    } catch (e) {
      debugPrint('No-show exception: $e');
      return ActionResult(success: false, errorMessage: 'Network error');
    }
  }

  // ── GPS Tracking ───────────────────────────────────────────────────

  Future<void> sendLocation({
    String? tripId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      await http.post(
        Uri.parse('$_baseUrl/driver/rides/tracking'),
        headers: _authHeaders(token),
        body: json.encode({
          if (tripId != null) 'trip_id': tripId,
          'latitude': latitude,
          'longitude': longitude,
          if (speed != null) 'speed': speed,
          if (heading != null) 'heading': heading,
          if (accuracy != null) 'accuracy': accuracy,
        }),
      );
    } catch (e) {
      // Silent fail — GPS updates are best-effort
    }
  }

  // ── Traffic Reports ────────────────────────────────────────────────

  Future<bool> submitTrafficReport({
    required String cityId,
    required String reportType,
    required double latitude,
    required double longitude,
    String? severity,
    double? heading,
    String? description,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/traffic/reports'),
        headers: _authHeaders(token),
        body: json.encode({
          'city_id': cityId,
          'report_type': reportType,
          'latitude': latitude,
          'longitude': longitude,
          if (severity != null) 'severity': severity,
          if (heading != null) 'heading': heading,
          if (description != null) 'description': description,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Traffic report exception: $e');
      return false;
    }
  }

  // ── Review (driver reviews passenger) ──────────────────────────────

  Future<bool> submitReview({
    required String tripId,
    required int stars,
    List<String>? tagIds,
    String? comment,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/rides/$tripId/review'),
        headers: _authHeaders(token),
        body: json.encode({
          'stars': stars,
          if (tagIds != null && tagIds.isNotEmpty) 'tag_ids': tagIds,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          'is_anonymous': true,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Submit review exception: $e');
      return false;
    }
  }
}

// ── Response Classes ─────────────────────────────────────────────────

class OfferResponse {
  final bool hasOffer;
  final RideOffer? offer;

  OfferResponse({required this.hasOffer, this.offer});
}

class OfferActionResult {
  final bool success;
  final String? tripId;
  final String? driverId;
  final String? status;
  final String? errorMessage;

  OfferActionResult({
    required this.success,
    this.tripId,
    this.driverId,
    this.status,
    this.errorMessage,
  });
}

class CurrentTripResponse {
  final bool hasActiveTrip;
  final DriverTrip? trip;
  final bool hasPreAssigned;
  final String? preAssignedTripId;

  CurrentTripResponse({
    required this.hasActiveTrip,
    this.trip,
    this.hasPreAssigned = false,
    this.preAssignedTripId,
  });
}

class ActionResult {
  final bool success;
  final String? status;
  final String? errorMessage;

  ActionResult({required this.success, this.status, this.errorMessage});
}
