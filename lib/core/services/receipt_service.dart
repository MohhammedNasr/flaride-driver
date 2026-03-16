import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flaride_driver/core/config/api_config.dart';

class ReceiptService {
  static final ReceiptService _instance = ReceiptService._internal();
  factory ReceiptService() => _instance;
  ReceiptService._internal();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Get receipt data for an order
  Future<ReceiptData> getReceipt(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/orders/$orderId/receipt'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ReceiptData.fromJson(data['receipt']);
        }
        throw Exception(data['error'] ?? 'Failed to load receipt');
      } else {
        throw Exception('Failed to load receipt: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading receipt: $e');
    }
  }

  /// Get receipt HTML URL for printing/sharing
  String getReceiptHtmlUrl(String orderId) {
    return '${ApiConfig.baseUrl}/api/orders/$orderId/receipt?format=html';
  }
}

class ReceiptData {
  final String orderId;
  final String orderCode;
  final String orderType;
  final String customerName;
  final bool disposableItems;
  final RestaurantInfo restaurant;
  final List<ReceiptItem> items;
  final ReceiptTotals totals;
  final ReceiptTimestamps timestamps;
  final String status;

  ReceiptData({
    required this.orderId,
    required this.orderCode,
    required this.orderType,
    required this.customerName,
    required this.disposableItems,
    required this.restaurant,
    required this.items,
    required this.totals,
    required this.timestamps,
    required this.status,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      orderId: json['order_id'] ?? '',
      orderCode: json['order_code'] ?? '',
      orderType: json['order_type'] ?? 'DELIVERY',
      customerName: json['customer_name'] ?? 'Customer',
      disposableItems: json['disposable_items'] ?? false,
      restaurant: RestaurantInfo.fromJson(json['restaurant'] ?? {}),
      items: (json['items'] as List?)
              ?.map((i) => ReceiptItem.fromJson(i))
              .toList() ??
          [],
      totals: ReceiptTotals.fromJson(json['totals'] ?? {}),
      timestamps: ReceiptTimestamps.fromJson(json['timestamps'] ?? {}),
      status: json['status'] ?? '',
    );
  }
}

class RestaurantInfo {
  final String name;
  final String? address;
  final String? phone;
  final String? logoUrl;

  RestaurantInfo({
    required this.name,
    this.address,
    this.phone,
    this.logoUrl,
  });

  factory RestaurantInfo.fromJson(Map<String, dynamic> json) {
    return RestaurantInfo(
      name: json['name'] ?? 'Restaurant',
      address: json['address'],
      phone: json['phone'],
      logoUrl: json['logo_url'],
    );
  }
}

class ReceiptItem {
  final int quantity;
  final String name;
  final List<ItemOption> options;
  final int unitPrice;
  final int totalPrice;
  final String? specialInstructions;

  ReceiptItem({
    required this.quantity,
    required this.name,
    required this.options,
    required this.unitPrice,
    required this.totalPrice,
    this.specialInstructions,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      quantity: json['quantity'] ?? 1,
      name: json['name'] ?? 'Item',
      options: (json['options'] as List?)
              ?.map((o) => ItemOption.fromJson(o))
              .toList() ??
          [],
      unitPrice: json['unit_price'] ?? 0,
      totalPrice: json['total_price'] ?? 0,
      specialInstructions: json['special_instructions'],
    );
  }
}

class ItemOption {
  final String group;
  final String choice;
  final int price;

  ItemOption({
    required this.group,
    required this.choice,
    required this.price,
  });

  factory ItemOption.fromJson(Map<String, dynamic> json) {
    return ItemOption(
      group: json['group'] ?? '',
      choice: json['choice'] ?? '',
      price: json['price'] ?? 0,
    );
  }
}

class ReceiptTotals {
  final int subtotal;
  final int vat;
  final int discount;
  final int amountPaid;

  ReceiptTotals({
    required this.subtotal,
    required this.vat,
    required this.discount,
    required this.amountPaid,
  });

  factory ReceiptTotals.fromJson(Map<String, dynamic> json) {
    return ReceiptTotals(
      subtotal: json['subtotal'] ?? 0,
      vat: json['vat'] ?? 0,
      discount: json['discount'] ?? 0,
      amountPaid: json['amount_paid'] ?? 0,
    );
  }
}

class ReceiptTimestamps {
  final DateTime? placedAt;
  final DateTime? dueAt;

  ReceiptTimestamps({
    this.placedAt,
    this.dueAt,
  });

  factory ReceiptTimestamps.fromJson(Map<String, dynamic> json) {
    return ReceiptTimestamps(
      placedAt:
          json['placed_at'] != null ? DateTime.tryParse(json['placed_at']) : null,
      dueAt: json['due_at'] != null ? DateTime.tryParse(json['due_at']) : null,
    );
  }
}
