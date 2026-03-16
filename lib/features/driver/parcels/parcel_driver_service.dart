import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flaride_driver/core/config/api_config.dart';
import 'package:flaride_driver/features/driver/parcels/parcel_order_model.dart';

class ParcelDriverService {
  final String _base = ApiConfig.apiBaseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      ...ApiConfig.defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _authHeadersOnly() async {
    final token = await _getToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch available parcel orders for the driver
  Future<AvailableParcelOrdersResponse> getAvailableOrders({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final params = <String, String>{};
      if (latitude != null) params['lat'] = latitude.toString();
      if (longitude != null) params['lng'] = longitude.toString();

      final uri = Uri.parse('$_base/driver/parcels/available')
          .replace(queryParameters: params.isNotEmpty ? params : null);

      final res = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final orders = (data['orders'] as List?)
                  ?.map((o) => AvailableParcelOrder.fromJson(o))
                  .toList() ??
              [];
          return AvailableParcelOrdersResponse(
            success: true,
            orders: orders,
            hasActiveParcelOrder: data['hasActiveParcelOrder'] ?? false,
            activeParcelOrderId: data['activeParcelOrderId'],
          );
        }
      }

      final errorData = jsonDecode(res.body);
      return AvailableParcelOrdersResponse(
        success: false,
        message: errorData['error'] ?? 'Failed to fetch parcel orders',
      );
    } catch (e) {
      debugPrint('ParcelDriverService.getAvailableOrders error: $e');
      return AvailableParcelOrdersResponse(
          success: false, message: 'Network error: $e');
    }
  }

  /// Accept a parcel order
  Future<AcceptParcelResponse> acceptOrder(String orderId) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/driver/parcels/$orderId/accept'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['order'] != null) {
          return AcceptParcelResponse(
            success: true,
            message: data['message'],
            order: ActiveParcelOrder.fromJson(data['order']),
          );
        }
      }

      final errorData = jsonDecode(res.body);
      return AcceptParcelResponse(
        success: false,
        message: errorData['error'] ?? 'Failed to accept order',
      );
    } catch (e) {
      debugPrint('ParcelDriverService.acceptOrder error: $e');
      return AcceptParcelResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Update parcel order status
  Future<UpdateParcelStatusResponse> updateStatus(
    String orderId,
    String newStatus, {
    double? driverLat,
    double? driverLng,
    int? etaMinutes,
    String? pickupProofPhoto,
    String? dropoffProofPhoto,
    String? pickupProofMimeType,
    int? pickupProofSizeBytes,
    String? pickupProofTakenAt,
    double? pickupProofTakenLat,
    double? pickupProofTakenLng,
    String? dropoffProofMimeType,
    int? dropoffProofSizeBytes,
    String? dropoffProofTakenAt,
    double? dropoffProofTakenLat,
    double? dropoffProofTakenLng,
    bool? dropoffOtpVerified,
  }) async {
    try {
      final body = <String, dynamic>{'status': newStatus};
      if (driverLat != null) body['driver_lat'] = driverLat;
      if (driverLng != null) body['driver_lng'] = driverLng;
      if (etaMinutes != null) body['eta_minutes'] = etaMinutes;
      if (pickupProofPhoto != null)
        body['pickup_proof_photo'] = pickupProofPhoto;
      if (dropoffProofPhoto != null)
        body['dropoff_proof_photo'] = dropoffProofPhoto;
      if (pickupProofMimeType != null)
        body['pickup_proof_mime_type'] = pickupProofMimeType;
      if (pickupProofSizeBytes != null)
        body['pickup_proof_size_bytes'] = pickupProofSizeBytes;
      if (pickupProofTakenAt != null)
        body['pickup_proof_taken_at'] = pickupProofTakenAt;
      if (pickupProofTakenLat != null)
        body['pickup_proof_taken_lat'] = pickupProofTakenLat;
      if (pickupProofTakenLng != null)
        body['pickup_proof_taken_lng'] = pickupProofTakenLng;
      if (dropoffProofMimeType != null)
        body['dropoff_proof_mime_type'] = dropoffProofMimeType;
      if (dropoffProofSizeBytes != null)
        body['dropoff_proof_size_bytes'] = dropoffProofSizeBytes;
      if (dropoffProofTakenAt != null)
        body['dropoff_proof_taken_at'] = dropoffProofTakenAt;
      if (dropoffProofTakenLat != null)
        body['dropoff_proof_taken_lat'] = dropoffProofTakenLat;
      if (dropoffProofTakenLng != null)
        body['dropoff_proof_taken_lng'] = dropoffProofTakenLng;
      if (dropoffOtpVerified != null)
        body['dropoff_otp_verified'] = dropoffOtpVerified;

      final res = await http
          .patch(
            Uri.parse('$_base/driver/parcels/$orderId/status'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['order'] != null) {
          return UpdateParcelStatusResponse(
            success: true,
            message: data['message'],
            order: ActiveParcelOrder.fromJson(data['order']),
          );
        }
      }

      final errorData = jsonDecode(res.body);
      return UpdateParcelStatusResponse(
        success: false,
        message: errorData['error'] ?? 'Failed to update status',
        code: errorData['code'],
        requirements: ParcelSecurityRequirements.fromJson(
            errorData['requirements'] as Map<String, dynamic>?),
      );
    } catch (e) {
      debugPrint('ParcelDriverService.updateStatus error: $e');
      return UpdateParcelStatusResponse(
          success: false, message: 'Network error: $e');
    }
  }

  Future<ParcelProofUploadResponse> uploadProofPhoto({
    required String orderId,
    required String proofType,
    required File file,
  }) async {
    try {
      final uri = Uri.parse('$_base/parcels/upload');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(await _authHeadersOnly());
      request.fields['bucket'] = 'parcel-proofs';
      request.fields['order_id'] = orderId;
      request.fields['proof_type'] = proofType;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed =
          await request.send().timeout(const Duration(seconds: 15));
      final res = await http.Response.fromStream(streamed);

      if (res.body.isEmpty) {
        return ParcelProofUploadResponse(
          success: false,
          message: 'Upload failed: empty response',
        );
      }

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        return ParcelProofUploadResponse(
          success: true,
          url: data['url']?.toString(),
          path: data['path']?.toString(),
          bucket: data['bucket']?.toString(),
          mimeType: _guessMimeType(file.path),
          sizeBytes: await file.length(),
        );
      }

      return ParcelProofUploadResponse(
        success: false,
        message: data['error']?.toString() ?? 'Failed to upload proof photo',
      );
    } catch (e) {
      debugPrint('ParcelDriverService.uploadProofPhoto error: $e');
      return ParcelProofUploadResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  String _guessMimeType(String filePath) {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  /// Cancel a parcel delivery
  Future<CancelParcelResponse> cancelDelivery(String orderId,
      {String? reason}) async {
    try {
      final body = <String, dynamic>{};
      if (reason != null) body['reason'] = reason;

      final res = await http
          .post(
            Uri.parse('$_base/driver/parcels/$orderId/cancel'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return CancelParcelResponse(success: true, message: data['message']);
      }

      final errorData = jsonDecode(res.body);
      return CancelParcelResponse(
        success: false,
        message: errorData['error'] ?? 'Failed to cancel delivery',
      );
    } catch (e) {
      debugPrint('ParcelDriverService.cancelDelivery error: $e');
      return CancelParcelResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Get single parcel order details (uses customer-facing API which allows driver access)
  Future<ActiveParcelOrder?> getOrderDetails(String orderId) async {
    try {
      final res = await http
          .get(
            Uri.parse('$_base/parcels/orders/$orderId'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['order'] != null) {
          return ActiveParcelOrder.fromJson(data['order']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('ParcelDriverService.getOrderDetails error: $e');
      return null;
    }
  }
}

// Response classes
class AvailableParcelOrdersResponse {
  final bool success;
  final List<AvailableParcelOrder> orders;
  final bool hasActiveParcelOrder;
  final String? activeParcelOrderId;
  final String? message;

  AvailableParcelOrdersResponse({
    required this.success,
    this.orders = const [],
    this.hasActiveParcelOrder = false,
    this.activeParcelOrderId,
    this.message,
  });
}

class AcceptParcelResponse {
  final bool success;
  final String? message;
  final ActiveParcelOrder? order;

  AcceptParcelResponse({required this.success, this.message, this.order});
}

class UpdateParcelStatusResponse {
  final bool success;
  final String? message;
  final ActiveParcelOrder? order;
  final String? code;
  final ParcelSecurityRequirements? requirements;

  UpdateParcelStatusResponse({
    required this.success,
    this.message,
    this.order,
    this.code,
    this.requirements,
  });
}

class CancelParcelResponse {
  final bool success;
  final String? message;

  CancelParcelResponse({required this.success, this.message});
}

class ParcelProofUploadResponse {
  final bool success;
  final String? url;
  final String? path;
  final String? bucket;
  final String? mimeType;
  final int? sizeBytes;
  final String? message;

  ParcelProofUploadResponse({
    required this.success,
    this.url,
    this.path,
    this.bucket,
    this.mimeType,
    this.sizeBytes,
    this.message,
  });
}
