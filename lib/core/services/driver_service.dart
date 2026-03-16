import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flaride_driver/core/models/driver.dart';
import 'package:flaride_driver/core/config/api_config.dart';

class DriverService {
  final String _baseApiUrl = ApiConfig.apiBaseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Get current driver profile
  Future<DriverProfileResponse> getMyProfile() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return DriverProfileResponse(
          success: false,
          isDriver: false,
          message: 'Not authenticated',
        );
      }

      final response = await http.get(
        Uri.parse('$_baseApiUrl/drivers/me'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Driver profile response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DriverProfileResponse(
          success: data['success'] ?? true,
          isDriver: data['is_driver'] ?? true,
          driver: data['data'] != null ? Driver.fromJson(data['data']) : null,
        );
      } else if (response.statusCode == 404) {
        // User is not a driver
        return DriverProfileResponse(
          success: true,
          isDriver: false,
          message: 'Not a driver account',
        );
      } else {
        final data = json.decode(response.body);
        return DriverProfileResponse(
          success: false,
          isDriver: false,
          message: data['error'] ?? 'Failed to fetch profile',
        );
      }
    } catch (e) {
      debugPrint('Driver profile error: $e');
      return DriverProfileResponse(
        success: false,
        isDriver: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Update driver online/offline status
  Future<DriverUpdateResponse> updateStatus({
    bool? isOnline,
    bool? isAvailable,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return DriverUpdateResponse(
            success: false, message: 'Not authenticated');
      }

      final body = <String, dynamic>{};
      if (isOnline != null) body['is_online'] = isOnline;
      if (isAvailable != null) body['is_available'] = isAvailable;
      if (latitude != null) body['current_latitude'] = latitude;
      if (longitude != null) body['current_longitude'] = longitude;

      final response = await http.put(
        Uri.parse('$_baseApiUrl/drivers/me'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      debugPrint('Update driver status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DriverUpdateResponse(
          success: true,
          isOnline: data['data']?['is_online'],
          isAvailable: data['data']?['is_available'],
        );
      } else {
        final data = json.decode(response.body);
        return DriverUpdateResponse(
          success: false,
          message: data['error'] ?? 'Failed to update status',
        );
      }
    } catch (e) {
      debugPrint('Update driver status error: $e');
      return DriverUpdateResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Update driver location
  Future<bool> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$_baseApiUrl/drivers/me'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'current_latitude': latitude,
          'current_longitude': longitude,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update location error: $e');
      return false;
    }
  }

  /// Update driver settings
  Future<DriverUpdateResponse> updateSettings({
    double? maxDeliveryDistanceKm,
    String? preferredWorkAreas,
    bool? hasInsulatedBag,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return DriverUpdateResponse(
            success: false, message: 'Not authenticated');
      }

      final body = <String, dynamic>{};
      if (maxDeliveryDistanceKm != null)
        body['max_delivery_distance_km'] = maxDeliveryDistanceKm;
      if (preferredWorkAreas != null)
        body['preferred_work_areas'] = preferredWorkAreas;
      if (hasInsulatedBag != null) body['has_insulated_bag'] = hasInsulatedBag;

      final response = await http.put(
        Uri.parse('$_baseApiUrl/drivers/me'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return DriverUpdateResponse(success: true);
      } else {
        final data = json.decode(response.body);
        return DriverUpdateResponse(
          success: false,
          message: data['error'] ?? 'Failed to update settings',
        );
      }
    } catch (e) {
      return DriverUpdateResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Update personal profile info
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? profilePhoto,
    String? driverLicenseFrontUrl,
    String? driverLicenseBackUrl,
    String? nationalIdFrontUrl,
    String? nationalIdBackUrl,
    String? vehicleRegistrationUrl,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName;
      if (phone != null) body['phone'] = phone;
      if (profilePhoto != null) body['profile_photo'] = profilePhoto;
      if (driverLicenseFrontUrl != null)
        body['driver_license_front_url'] = driverLicenseFrontUrl;
      if (driverLicenseBackUrl != null)
        body['driver_license_back_url'] = driverLicenseBackUrl;
      if (nationalIdFrontUrl != null)
        body['national_id_front_url'] = nationalIdFrontUrl;
      if (nationalIdBackUrl != null)
        body['national_id_back_url'] = nationalIdBackUrl;
      if (vehicleRegistrationUrl != null)
        body['vehicle_registration_url'] = vehicleRegistrationUrl;

      debugPrint('DriverService.updateProfile: Sending $body');
      final response = await http.put(
        Uri.parse('$_baseApiUrl/drivers/me'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      debugPrint(
          'DriverService.updateProfile: Response ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    }
  }

  /// Update vehicle info
  Future<bool> updateVehicleInfo({
    String? vehicleType,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleColor,
    String? vehicleLicensePlate,
    int? vehicleYear,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final body = <String, dynamic>{};
      if (vehicleType != null) body['vehicle_type'] = vehicleType;
      if (vehicleBrand != null) body['vehicle_brand'] = vehicleBrand;
      if (vehicleModel != null) body['vehicle_model'] = vehicleModel;
      if (vehicleColor != null) body['vehicle_color'] = vehicleColor;
      if (vehicleLicensePlate != null)
        body['vehicle_license_plate'] = vehicleLicensePlate;
      if (vehicleYear != null) body['vehicle_year'] = vehicleYear;

      final response = await http.put(
        Uri.parse('$_baseApiUrl/drivers/me'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update vehicle info error: $e');
      return false;
    }
  }

  /// Update payment settings
  Future<bool> updatePaymentSettings({
    String? preferredMethod,
    String? mobileMoneyNumber,
    String? mobileMoneyProvider,
    String? bankAccount,
    String? bankName,
    String? bankBranch,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final body = <String, dynamic>{};
      if (preferredMethod != null)
        body['preferred_payout_method'] = preferredMethod;
      if (mobileMoneyNumber != null)
        body['payout_mobile_money_number'] = mobileMoneyNumber;
      if (mobileMoneyProvider != null)
        body['payout_mobile_money_provider'] = mobileMoneyProvider;
      if (bankAccount != null) body['payout_bank_account'] = bankAccount;
      if (bankName != null) body['payout_bank_name'] = bankName;
      if (bankBranch != null) body['bank_branch'] = bankBranch;

      final response = await http.put(
        Uri.parse('$_baseApiUrl/drivers/me'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update payment settings error: $e');
      return false;
    }
  }

  /// Get single order details
  Future<OrderDetailsResponse> getOrderDetails(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return OrderDetailsResponse(
            success: false, message: 'Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$_baseApiUrl/driver/orders/$orderId'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OrderDetailsResponse(
          success: true,
          order: OrderDetails.fromJson(data['order']),
        );
      } else {
        final data = json.decode(response.body);
        return OrderDetailsResponse(
          success: false,
          message: data['error'] ?? 'Failed to fetch order details',
        );
      }
    } catch (e) {
      debugPrint('Get order details error: $e');
      return OrderDetailsResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Get driver's earnings summary and history
  Future<EarningsResponse> getEarnings(
      {String? status, String? period, int limit = 50, int offset = 0}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return EarningsResponse(success: false, message: 'Not authenticated');
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (status != null) queryParams['status'] = status;
      if (period != null) queryParams['period'] = period;

      final uri = Uri.parse('$_baseApiUrl/driver/earnings')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EarningsResponse(
          success: true,
          summary: EarningsSummary.fromJson(data['summary'] ?? {}),
          payoutInfo: PayoutInfo.fromJson(data['payout_info'] ?? {}),
          earnings: (data['earnings'] as List?)
                  ?.map((e) => Earning.fromJson(e))
                  .toList() ??
              [],
        );
      } else {
        final data = json.decode(response.body);
        return EarningsResponse(
          success: false,
          message: data['error'] ?? 'Failed to fetch earnings',
        );
      }
    } catch (e) {
      debugPrint('Get earnings error: $e');
      return EarningsResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Request a payout
  Future<PayoutRequestResponse> requestPayout({
    required String paymentMethod,
    String? paymentAccount,
    String? paymentProvider,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return PayoutRequestResponse(
            success: false, message: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_baseApiUrl/driver/payouts'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'payment_method': paymentMethod,
          if (paymentAccount != null) 'payment_account': paymentAccount,
          if (paymentProvider != null) 'payment_provider': paymentProvider,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PayoutRequestResponse(
          success: true,
          message: data['message'],
          payout: PayoutRequest.fromJson(data['payout'] ?? {}),
        );
      } else {
        final data = json.decode(response.body);
        return PayoutRequestResponse(
          success: false,
          message: data['error'] ?? 'Failed to request payout',
        );
      }
    } catch (e) {
      debugPrint('Request payout error: $e');
      return PayoutRequestResponse(
          success: false, message: 'Network error: $e');
    }
  }

  /// Get payout history
  Future<PayoutHistoryResponse> getPayoutHistory(
      {int limit = 20, int offset = 0}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return PayoutHistoryResponse(
            success: false, message: 'Not authenticated');
      }

      final uri = Uri.parse('$_baseApiUrl/driver/payouts').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PayoutHistoryResponse(
          success: true,
          payouts: (data['payouts'] as List?)
                  ?.map((p) => PayoutHistory.fromJson(p))
                  .toList() ??
              [],
        );
      } else {
        final data = json.decode(response.body);
        return PayoutHistoryResponse(
          success: false,
          message: data['error'] ?? 'Failed to fetch payouts',
        );
      }
    } catch (e) {
      debugPrint('Get payout history error: $e');
      return PayoutHistoryResponse(
          success: false, message: 'Network error: $e');
    }
  }

  /// Get driver's order history
  Future<OrderHistoryResponse> getOrderHistory(
      {String? status, int limit = 50, int offset = 0}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return OrderHistoryResponse(
            success: false, message: 'Not authenticated');
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$_baseApiUrl/driver/orders/history')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OrderHistoryResponse(
          success: true,
          activeOrder: data['active_order'] != null
              ? HistoryOrder.fromJson(data['active_order'])
              : null,
          orders: (data['orders'] as List?)
                  ?.map((o) => HistoryOrder.fromJson(o))
                  .toList() ??
              [],
          stats: OrderStats.fromJson(data['stats'] ?? {}),
        );
      } else {
        final data = json.decode(response.body);
        return OrderHistoryResponse(
          success: false,
          message: data['error'] ?? 'Failed to fetch order history',
        );
      }
    } catch (e) {
      debugPrint('Get order history error: $e');
      return OrderHistoryResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Update order status (picked_up, delivered, etc.)
  Future<UpdateStatusResponse> updateOrderStatus(
      String orderId, String status) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return UpdateStatusResponse(
            success: false, message: 'Not authenticated');
      }

      final response = await http.patch(
        Uri.parse('$_baseApiUrl/driver/orders/$orderId/status'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UpdateStatusResponse(
          success: true,
          message: data['message'] ?? 'Status updated',
          newStatus: data['status'],
        );
      } else {
        final data = json.decode(response.body);
        return UpdateStatusResponse(
          success: false,
          message: data['error'] ?? 'Failed to update status',
        );
      }
    } catch (e) {
      debugPrint('Update order status error: $e');
      return UpdateStatusResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Accept an order
  Future<AcceptOrderResponse> acceptOrder(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return AcceptOrderResponse(
            success: false, message: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_baseApiUrl/driver/orders/$orderId/accept'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AcceptOrderResponse(
          success: true,
          message: data['message'] ?? 'Order accepted',
        );
      } else {
        final data = json.decode(response.body);
        return AcceptOrderResponse(
          success: false,
          message: data['error'] ?? 'Failed to accept order',
        );
      }
    } catch (e) {
      debugPrint('Accept order error: $e');
      return AcceptOrderResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Get available orders for delivery
  Future<AvailableOrdersResponse> getAvailableOrders({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return AvailableOrdersResponse(
            success: false, message: 'Not authenticated');
      }

      final queryParams = <String, String>{};
      if (latitude != null) queryParams['lat'] = latitude.toString();
      if (longitude != null) queryParams['lng'] = longitude.toString();

      final uri = Uri.parse('$_baseApiUrl/driver/orders/available').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ordersList = data['orders'] as List?;

        final orders = ordersList?.map((o) {
              return AvailableOrder.fromJson(o);
            }).toList() ??
            [];

        // Extract activeOrderId - can be string or object with xata_id
        String? activeOrderId;
        final activeOrderData = data['activeOrderId'];
        if (activeOrderData is String) {
          activeOrderId = activeOrderData;
        } else if (activeOrderData is Map) {
          activeOrderId = activeOrderData['xata_id'] as String?;
        }

        return AvailableOrdersResponse(
          success: true,
          orders: orders,
          hasActiveOrder: data['hasActiveOrder'] ?? false,
          activeOrderId: activeOrderId,
          message: data['message'],
        );
      } else {
        final data = json.decode(response.body);
        return AvailableOrdersResponse(
          success: false,
          message: data['error'] ?? 'Failed to fetch available orders',
        );
      }
    } catch (e) {
      debugPrint('Get available orders error: $e');
      return AvailableOrdersResponse(
          success: false, message: 'Network error: $e');
    }
  }
}

class AvailableOrder {
  final String id;
  final String orderNumber;
  final String status;
  final DateTime? readyForPickupAt;
  final int itemsCount;
  final int totalAmount;
  final String totalAmountDisplay;
  final int deliveryFee;
  final String deliveryFeeDisplay;
  final String estimatedEarnings;
  final String? pickupDistanceKm;
  final String? deliveryDistanceKm;
  final AvailableOrderRestaurant? restaurant;
  final String? customerName;
  final String? deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;

  AvailableOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.readyForPickupAt,
    required this.itemsCount,
    required this.totalAmount,
    required this.totalAmountDisplay,
    required this.deliveryFee,
    required this.deliveryFeeDisplay,
    required this.estimatedEarnings,
    this.pickupDistanceKm,
    this.deliveryDistanceKm,
    this.restaurant,
    this.customerName,
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
  });

  factory AvailableOrder.fromJson(Map<String, dynamic> json) {
    return AvailableOrder(
      id: json['id'] ?? json['xata_id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? '',
      readyForPickupAt: json['ready_for_pickup_at'] != null
          ? DateTime.tryParse(json['ready_for_pickup_at'])
          : null,
      itemsCount: json['items_count'] ?? 0,
      totalAmount: json['total_amount'] ?? 0,
      totalAmountDisplay: json['total_amount_display'] ?? '0 CFA',
      deliveryFee: json['delivery_fee'] ?? 0,
      deliveryFeeDisplay: json['delivery_fee_display'] ?? '0 CFA',
      estimatedEarnings: json['estimated_earnings'] ?? '0 CFA',
      pickupDistanceKm: json['pickup_distance_km']?.toString(),
      deliveryDistanceKm: json['delivery_distance_km']?.toString(),
      restaurant: json['restaurant'] != null
          ? AvailableOrderRestaurant.fromJson(json['restaurant'])
          : null,
      customerName: json['customer']?['name'],
      deliveryAddress: json['delivery_address'],
      deliveryLatitude: (json['delivery_latitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['delivery_longitude'] as num?)?.toDouble(),
    );
  }
}

class AvailableOrderRestaurant {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? logoUrl;
  final double? latitude;
  final double? longitude;

  AvailableOrderRestaurant({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.logoUrl,
    this.latitude,
    this.longitude,
  });

  factory AvailableOrderRestaurant.fromJson(Map<String, dynamic> json) {
    return AvailableOrderRestaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
      logoUrl: json['logo_url'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }
}

class AvailableOrdersResponse {
  final bool success;
  final List<AvailableOrder> orders;
  final bool hasActiveOrder;
  final String? activeOrderId;
  final String? message;

  AvailableOrdersResponse({
    required this.success,
    this.orders = const [],
    this.hasActiveOrder = false,
    this.activeOrderId,
    this.message,
  });
}

// Detailed order model for order details screen
class OrderDetails {
  final String id;
  final String orderNumber;
  final String status;
  final String? orderType;
  final DateTime? createdAt;
  final DateTime? readyForPickupAt;
  final String? timeSinceReady;
  final int? estimatedDeliveryMinutes;

  // Amounts
  final int subtotal;
  final String subtotalDisplay;
  final int deliveryFee;
  final String deliveryFeeDisplay;
  final int serviceFee;
  final String serviceFeeDisplay;
  final int tipAmount;
  final String tipAmountDisplay;
  final int totalAmount;
  final String totalAmountDisplay;
  final String estimatedEarnings;

  // Items
  final List<OrderItem> items;
  final int itemsCount;

  // Distances
  final String? pickupDistanceKm;
  final String? deliveryDistanceKm;
  final String? totalDistanceKm;

  // Restaurant
  final OrderRestaurant? restaurant;

  // Customer
  final OrderCustomer? customer;

  // Delivery
  final OrderDelivery? delivery;

  // Payment
  final String? paymentMethod;
  final String? paymentStatus;

  // Notes
  final String? notes;
  final String? specialInstructions;

  // Availability
  final bool isAvailable;
  final bool alreadyAssigned;
  final bool isMyOrder;

  OrderDetails({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.orderType,
    this.createdAt,
    this.readyForPickupAt,
    this.timeSinceReady,
    this.estimatedDeliveryMinutes,
    required this.subtotal,
    required this.subtotalDisplay,
    required this.deliveryFee,
    required this.deliveryFeeDisplay,
    required this.serviceFee,
    required this.serviceFeeDisplay,
    required this.tipAmount,
    required this.tipAmountDisplay,
    required this.totalAmount,
    required this.totalAmountDisplay,
    required this.estimatedEarnings,
    required this.items,
    required this.itemsCount,
    this.pickupDistanceKm,
    this.deliveryDistanceKm,
    this.totalDistanceKm,
    this.restaurant,
    this.customer,
    this.delivery,
    this.paymentMethod,
    this.paymentStatus,
    this.notes,
    this.specialInstructions,
    this.isAvailable = false,
    this.alreadyAssigned = false,
    this.isMyOrder = false,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      id: json['id'] ?? json['xata_id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? '',
      orderType: json['order_type'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      readyForPickupAt: json['ready_for_pickup_at'] != null
          ? DateTime.tryParse(json['ready_for_pickup_at'])
          : null,
      timeSinceReady: json['time_since_ready'],
      estimatedDeliveryMinutes: json['estimated_delivery_time_minutes'],
      subtotal: json['subtotal'] ?? 0,
      subtotalDisplay: json['subtotal_display'] ?? '0 CFA',
      deliveryFee: json['delivery_fee'] ?? 0,
      deliveryFeeDisplay: json['delivery_fee_display'] ?? '0 CFA',
      serviceFee: json['service_fee'] ?? 0,
      serviceFeeDisplay: json['service_fee_display'] ?? '0 CFA',
      tipAmount: json['tip_amount'] ?? 0,
      tipAmountDisplay: json['tip_amount_display'] ?? '0 CFA',
      totalAmount: json['total_amount'] ?? 0,
      totalAmountDisplay: json['total_amount_display'] ?? '0 CFA',
      estimatedEarnings: json['estimated_earnings'] ?? '0 CFA',
      items: (json['items'] as List?)
              ?.map((i) => OrderItem.fromJson(i))
              .toList() ??
          [],
      itemsCount: json['items_count'] ?? 0,
      pickupDistanceKm: json['pickup_distance_km']?.toString(),
      deliveryDistanceKm: json['delivery_distance_km']?.toString(),
      totalDistanceKm: json['total_distance_km']?.toString(),
      restaurant: json['restaurant'] != null
          ? OrderRestaurant.fromJson(json['restaurant'])
          : null,
      customer: json['customer'] != null
          ? OrderCustomer.fromJson(json['customer'])
          : null,
      delivery: json['delivery'] != null
          ? OrderDelivery.fromJson(json['delivery'])
          : null,
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      notes: json['notes'],
      specialInstructions: json['special_instructions'],
      isAvailable: json['is_available'] ?? false,
      alreadyAssigned: json['already_assigned'] ?? false,
      isMyOrder: json['is_my_order'] ?? false,
    );
  }
}

class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final int unitPrice;
  final String unitPriceDisplay;
  final int totalPrice;
  final String totalPriceDisplay;
  final String? specialInstructions;
  final String? imageUrl;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.unitPriceDisplay,
    required this.totalPrice,
    required this.totalPriceDisplay,
    this.specialInstructions,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: json['unit_price'] ?? 0,
      unitPriceDisplay: json['unit_price_display'] ?? '0 CFA',
      totalPrice: json['total_price'] ?? 0,
      totalPriceDisplay: json['total_price_display'] ?? '0 CFA',
      specialInstructions: json['special_instructions'],
      imageUrl: json['image_url'],
    );
  }
}

class OrderRestaurant {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final String? logoUrl;
  final String? cuisineType;

  OrderRestaurant({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.logoUrl,
    this.cuisineType,
  });

  factory OrderRestaurant.fromJson(Map<String, dynamic> json) {
    return OrderRestaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      logoUrl: json['logo_url'],
      cuisineType: json['cuisine_type'],
    );
  }
}

class OrderCustomer {
  final String id;
  final String name;
  final String? phone;
  final String? email;

  OrderCustomer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
  });

  factory OrderCustomer.fromJson(Map<String, dynamic> json) {
    return OrderCustomer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
    );
  }
}

class OrderDelivery {
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? apartment;
  final String? instructions;
  final String? phone;

  OrderDelivery({
    this.address,
    this.latitude,
    this.longitude,
    this.apartment,
    this.instructions,
    this.phone,
  });

  factory OrderDelivery.fromJson(Map<String, dynamic> json) {
    return OrderDelivery(
      address: json['address'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      apartment: json['apartment'],
      instructions: json['instructions'],
      phone: json['phone'],
    );
  }
}

class OrderDetailsResponse {
  final bool success;
  final OrderDetails? order;
  final String? message;

  OrderDetailsResponse({
    required this.success,
    this.order,
    this.message,
  });
}

class AcceptOrderResponse {
  final bool success;
  final String? message;

  AcceptOrderResponse({
    required this.success,
    this.message,
  });
}

class UpdateStatusResponse {
  final bool success;
  final String? message;
  final String? newStatus;

  UpdateStatusResponse({
    required this.success,
    this.message,
    this.newStatus,
  });
}

// Order History Models
class OrderHistoryResponse {
  final bool success;
  final HistoryOrder? activeOrder;
  final List<HistoryOrder> orders;
  final OrderStats? stats;
  final String? message;

  OrderHistoryResponse({
    required this.success,
    this.activeOrder,
    this.orders = const [],
    this.stats,
    this.message,
  });
}

class HistoryOrder {
  final String id;
  final String orderNumber;
  final String status;
  final String statusDisplay;
  final String statusColor;

  final DateTime? createdAt;
  final DateTime? driverAssignedAt;
  final DateTime? driverPickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final int? deliveryTimeMinutes;

  final int itemsCount;
  final List<HistoryOrderItem> items;

  final int totalAmount;
  final String totalAmountDisplay;
  final int deliveryFee;
  final String deliveryFeeDisplay;
  final int driverEarnings;
  final String driverEarningsDisplay;
  final int driverBaseEarnings;
  final String driverBaseEarningsDisplay;

  // Tips
  final int tipAmount;
  final String? tipAmountDisplay;

  // Rating/Review
  final double? driverRating;
  final String? driverReview;

  final HistoryRestaurant? restaurant;
  final HistoryCustomer? customer;
  final String? deliveryAddress;
  final String? paymentMethod;

  HistoryOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.statusDisplay,
    required this.statusColor,
    this.createdAt,
    this.driverAssignedAt,
    this.driverPickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.deliveryTimeMinutes,
    required this.itemsCount,
    this.items = const [],
    required this.totalAmount,
    required this.totalAmountDisplay,
    required this.deliveryFee,
    required this.deliveryFeeDisplay,
    required this.driverEarnings,
    required this.driverEarningsDisplay,
    this.driverBaseEarnings = 0,
    this.driverBaseEarningsDisplay = '0 CFA',
    this.tipAmount = 0,
    this.tipAmountDisplay,
    this.driverRating,
    this.driverReview,
    this.restaurant,
    this.customer,
    this.deliveryAddress,
    this.paymentMethod,
  });

  factory HistoryOrder.fromJson(Map<String, dynamic> json) {
    return HistoryOrder(
      id: json['xata_id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? json['status'] ?? '',
      statusColor: json['status_color'] ?? '#6B7280',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      driverAssignedAt: json['driver_assigned_at'] != null
          ? DateTime.tryParse(json['driver_assigned_at'])
          : null,
      driverPickedUpAt: json['driver_picked_up_at'] != null
          ? DateTime.tryParse(json['driver_picked_up_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'])
          : null,
      deliveryTimeMinutes: json['delivery_time_minutes'],
      itemsCount: json['items_count'] ?? 0,
      items: (json['items'] as List?)
              ?.map((i) => HistoryOrderItem.fromJson(i))
              .toList() ??
          [],
      totalAmount: json['total_amount'] ?? 0,
      totalAmountDisplay: json['total_amount_display'] ?? '0 CFA',
      deliveryFee: json['delivery_fee'] ?? 0,
      deliveryFeeDisplay: json['delivery_fee_display'] ?? '0 CFA',
      driverEarnings: json['driver_earnings'] ?? 0,
      driverEarningsDisplay: json['driver_earnings_display'] ?? '0 CFA',
      driverBaseEarnings: json['driver_base_earnings'] ?? 0,
      driverBaseEarningsDisplay:
          json['driver_base_earnings_display'] ?? '0 CFA',
      tipAmount: json['tip_amount'] ?? 0,
      tipAmountDisplay: json['tip_amount_display'],
      driverRating: (json['driver_rating'] as num?)?.toDouble(),
      driverReview: json['driver_review'],
      restaurant: json['restaurant'] != null
          ? HistoryRestaurant.fromJson(json['restaurant'])
          : null,
      customer: json['customer'] != null
          ? HistoryCustomer.fromJson(json['customer'])
          : null,
      deliveryAddress: json['delivery_address'],
      paymentMethod: json['payment_method'],
    );
  }

  bool get isActive => [
        'driver_assigned',
        'driver_arrived',
        'picked_up',
        'on_the_way',
        'arrived'
      ].contains(status);
  bool get isCompleted => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get hasTip => tipAmount > 0;
  bool get hasRating => driverRating != null && driverRating! > 0;
}

class HistoryOrderItem {
  final String name;
  final int quantity;

  HistoryOrderItem({required this.name, required this.quantity});

  factory HistoryOrderItem.fromJson(Map<String, dynamic> json) {
    return HistoryOrderItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }
}

class HistoryRestaurant {
  final String id;
  final String name;
  final String? address;
  final String? phone;

  HistoryRestaurant({
    required this.id,
    required this.name,
    this.address,
    this.phone,
  });

  factory HistoryRestaurant.fromJson(Map<String, dynamic> json) {
    return HistoryRestaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
    );
  }
}

class HistoryCustomer {
  final String name;
  final String? phone;

  HistoryCustomer({required this.name, this.phone});

  factory HistoryCustomer.fromJson(Map<String, dynamic> json) {
    return HistoryCustomer(
      name: json['name'] ?? '',
      phone: json['phone'],
    );
  }
}

class OrderStats {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int activeOrders;

  OrderStats({
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.activeOrders = 0,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      activeOrders: json['active_orders'] ?? 0,
    );
  }
}

// Earnings Models
class EarningsResponse {
  final bool success;
  final EarningsSummary? summary;
  final PayoutInfo? payoutInfo;
  final List<Earning> earnings;
  final String? message;

  EarningsResponse({
    required this.success,
    this.summary,
    this.payoutInfo,
    this.earnings = const [],
    this.message,
  });
}

class EarningsSummary {
  final int totalEarnings;
  final String totalEarningsDisplay;
  final int pendingEarnings;
  final String pendingEarningsDisplay;
  final int availableEarnings;
  final String availableEarningsDisplay;
  final int paidEarnings;
  final String paidEarningsDisplay;
  final int todayEarnings;
  final String todayEarningsDisplay;
  final int totalDeliveries;
  final int todayDeliveries;
  // Earnings breakdown
  final int totalTips;
  final String totalTipsDisplay;
  final int totalBonuses;
  final String totalBonusesDisplay;
  final int baseEarnings;
  final String baseEarningsDisplay;

  EarningsSummary({
    this.totalEarnings = 0,
    this.totalEarningsDisplay = '0 CFA',
    this.pendingEarnings = 0,
    this.pendingEarningsDisplay = '0 CFA',
    this.availableEarnings = 0,
    this.availableEarningsDisplay = '0 CFA',
    this.paidEarnings = 0,
    this.paidEarningsDisplay = '0 CFA',
    this.todayEarnings = 0,
    this.todayEarningsDisplay = '0 CFA',
    this.totalDeliveries = 0,
    this.todayDeliveries = 0,
    this.totalTips = 0,
    this.totalTipsDisplay = '0 CFA',
    this.totalBonuses = 0,
    this.totalBonusesDisplay = '0 CFA',
    this.baseEarnings = 0,
    this.baseEarningsDisplay = '0 CFA',
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    final breakdown = json['earnings_breakdown'] as Map<String, dynamic>? ?? {};
    return EarningsSummary(
      totalEarnings: json['total_earnings'] ?? 0,
      totalEarningsDisplay: json['total_earnings_display'] ?? '0 CFA',
      pendingEarnings: json['pending_earnings'] ?? 0,
      pendingEarningsDisplay: json['pending_earnings_display'] ?? '0 CFA',
      availableEarnings: json['available_earnings'] ?? 0,
      availableEarningsDisplay: json['available_earnings_display'] ?? '0 CFA',
      paidEarnings: json['paid_earnings'] ?? 0,
      paidEarningsDisplay: json['paid_earnings_display'] ?? '0 CFA',
      todayEarnings: json['today_earnings'] ?? 0,
      todayEarningsDisplay: json['today_earnings_display'] ?? '0 CFA',
      totalDeliveries: json['total_deliveries'] ?? 0,
      todayDeliveries: json['today_deliveries'] ?? 0,
      totalTips: breakdown['tips'] ?? 0,
      totalTipsDisplay: breakdown['tips_display'] ?? '0 CFA',
      totalBonuses: breakdown['bonuses'] ?? 0,
      totalBonusesDisplay: breakdown['bonuses_display'] ?? '0 CFA',
      baseEarnings: breakdown['base_earnings'] ?? 0,
      baseEarningsDisplay: breakdown['base_earnings_display'] ?? '0 CFA',
    );
  }
}

class PayoutInfo {
  final String? preferredMethod;
  final String? mobileMoneyNumber;
  final String? mobileMoneyProvider;
  final String? bankName;
  final String? bankAccount;
  final bool canRequestPayout;
  final int minimumPayout;
  final String minimumPayoutDisplay;

  PayoutInfo({
    this.preferredMethod,
    this.mobileMoneyNumber,
    this.mobileMoneyProvider,
    this.bankName,
    this.bankAccount,
    this.canRequestPayout = false,
    this.minimumPayout = 0,
    this.minimumPayoutDisplay = '0 CFA',
  });

  factory PayoutInfo.fromJson(Map<String, dynamic> json) {
    return PayoutInfo(
      preferredMethod: json['preferred_method'],
      mobileMoneyNumber: json['mobile_money_number'],
      mobileMoneyProvider: json['mobile_money_provider'],
      bankName: json['bank_name'],
      bankAccount: json['bank_account'],
      canRequestPayout: json['can_request_payout'] ?? false,
      minimumPayout: json['minimum_payout'] ?? 0,
      minimumPayoutDisplay: json['minimum_payout_display'] ?? '0 CFA',
    );
  }
}

class Earning {
  final String id;
  final String orderNumber;
  final String? orderId;
  final int baseAmount;
  final int tipAmount;
  final int distanceBonus;
  final int peakBonus;
  final int totalAmount;
  final String totalAmountDisplay;
  final String status;
  final String statusDisplay;
  final DateTime? createdAt;
  final DateTime? availableAt;
  final DateTime? paidAt;
  final String? payoutId;

  Earning({
    required this.id,
    required this.orderNumber,
    this.orderId,
    this.baseAmount = 0,
    this.tipAmount = 0,
    this.distanceBonus = 0,
    this.peakBonus = 0,
    this.totalAmount = 0,
    this.totalAmountDisplay = '0 CFA',
    this.status = 'pending',
    this.statusDisplay = 'Pending',
    this.createdAt,
    this.availableAt,
    this.paidAt,
    this.payoutId,
  });

  factory Earning.fromJson(Map<String, dynamic> json) {
    return Earning(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      orderId: json['order_id'],
      baseAmount: json['base_amount'] ?? 0,
      tipAmount: json['tip_amount'] ?? 0,
      distanceBonus: json['distance_bonus'] ?? 0,
      peakBonus: json['peak_bonus'] ?? 0,
      totalAmount: json['total_amount'] ?? 0,
      totalAmountDisplay: json['total_amount_display'] ?? '0 CFA',
      status: json['status'] ?? 'pending',
      statusDisplay: json['status_display'] ?? 'Pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      availableAt: json['available_at'] != null
          ? DateTime.tryParse(json['available_at'])
          : null,
      paidAt:
          json['paid_at'] != null ? DateTime.tryParse(json['paid_at']) : null,
      payoutId: json['payout_id'],
    );
  }

  bool get isAvailable => status == 'available';
  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
}

class PayoutRequestResponse {
  final bool success;
  final String? message;
  final PayoutRequest? payout;

  PayoutRequestResponse({
    required this.success,
    this.message,
    this.payout,
  });
}

class PayoutRequest {
  final String id;
  final int amount;
  final String amountDisplay;
  final String status;
  final String paymentMethod;
  final DateTime? requestedAt;

  PayoutRequest({
    required this.id,
    this.amount = 0,
    this.amountDisplay = '0 CFA',
    this.status = 'pending',
    this.paymentMethod = 'mobile_money',
    this.requestedAt,
  });

  factory PayoutRequest.fromJson(Map<String, dynamic> json) {
    return PayoutRequest(
      id: json['id'] ?? '',
      amount: json['amount'] ?? 0,
      amountDisplay: json['amount_display'] ?? '0 CFA',
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? 'mobile_money',
      requestedAt: json['requested_at'] != null
          ? DateTime.tryParse(json['requested_at'])
          : null,
    );
  }
}

class PayoutHistoryResponse {
  final bool success;
  final List<PayoutHistory> payouts;
  final String? message;

  PayoutHistoryResponse({
    required this.success,
    this.payouts = const [],
    this.message,
  });
}

class PayoutHistory {
  final String id;
  final int amount;
  final String amountDisplay;
  final String status;
  final String statusDisplay;
  final String paymentMethod;
  final String paymentMethodDisplay;
  final String? paymentAccount;
  final String? paymentProvider;
  final DateTime? requestedAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final String? failureReason;
  final String? transactionReference;

  PayoutHistory({
    required this.id,
    this.amount = 0,
    this.amountDisplay = '0 CFA',
    this.status = 'pending',
    this.statusDisplay = 'Pending',
    this.paymentMethod = 'mobile_money',
    this.paymentMethodDisplay = 'Mobile Money',
    this.paymentAccount,
    this.paymentProvider,
    this.requestedAt,
    this.processedAt,
    this.completedAt,
    this.failureReason,
    this.transactionReference,
  });

  factory PayoutHistory.fromJson(Map<String, dynamic> json) {
    return PayoutHistory(
      id: json['id'] ?? '',
      amount: json['amount'] ?? 0,
      amountDisplay: json['amount_display'] ?? '0 CFA',
      status: json['status'] ?? 'pending',
      statusDisplay: json['status_display'] ?? 'Pending',
      paymentMethod: json['payment_method'] ?? 'mobile_money',
      paymentMethodDisplay: json['payment_method_display'] ?? 'Mobile Money',
      paymentAccount: json['payment_account'],
      paymentProvider: json['payment_provider'],
      requestedAt: json['requested_at'] != null
          ? DateTime.tryParse(json['requested_at'])
          : null,
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
          : null,
      failureReason: json['failure_reason'],
      transactionReference: json['transaction_reference'],
    );
  }

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}

class DriverProfileResponse {
  final bool success;
  final bool isDriver;
  final Driver? driver;
  final String? message;

  DriverProfileResponse({
    required this.success,
    required this.isDriver,
    this.driver,
    this.message,
  });
}

class DriverUpdateResponse {
  final bool success;
  final bool? isOnline;
  final bool? isAvailable;
  final String? message;

  DriverUpdateResponse({
    required this.success,
    this.isOnline,
    this.isAvailable,
    this.message,
  });
}
