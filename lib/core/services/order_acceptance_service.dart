import 'package:flutter/material.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/features/driver/home/widgets/acceptance_rules_dialog.dart';
import 'package:flaride_driver/features/driver/active_delivery_screen.dart';
import 'package:flaride_driver/shared/widgets/app_toast.dart';

/// Service to handle order acceptance flow with confirmation dialog
/// This centralizes the acceptance logic to avoid duplication across screens
class OrderAcceptanceService {
  final DriverService _driverService = DriverService();

  /// Accept an order with confirmation dialog and navigation
  /// 
  /// Returns true if order was successfully accepted, false otherwise
  /// Handles showing the rules dialog, accepting the order, fetching details,
  /// and navigating to the active delivery screen
  Future<bool> acceptOrder({
    required BuildContext context,
    required String orderId,
    required VoidCallback onAcceptingStateChanged,
    VoidCallback? onSuccess,
  }) async {
    // Show rules confirmation dialog first
    final confirmed = await AcceptanceRulesDialog.show(context);
    if (confirmed != true) return false;

    // Notify that acceptance is in progress
    onAcceptingStateChanged();

    try {
      final response = await _driverService.acceptOrder(orderId);

      if (!context.mounted) return false;

      if (response.success) {
        // Fetch full order details for active delivery screen
        final detailsResponse = await _driverService.getOrderDetails(orderId);
        
        if (detailsResponse.success && detailsResponse.order != null) {
          if (!context.mounted) return false;

          // Call success callback if provided (for updating provider, etc.)
          onSuccess?.call();
          
          // Navigate to active delivery screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ActiveDeliveryScreen(order: detailsResponse.order!),
            ),
          );
          
          return true;
        } else {
          if (!context.mounted) return false;
          
          _showSnackBar(
            context,
            'Order accepted but failed to load details: ${detailsResponse.message}',
            Colors.orange,
          );
          
          // Still consider it successful since order was accepted
          // Just pop back to previous screen
          Navigator.of(context).pop();
          return true;
        }
      } else {
        if (!context.mounted) return false;
        
        _showSnackBar(
          context,
          response.message ?? 'Failed to accept order',
          Colors.red,
        );
        
        return false;
      }
    } catch (e) {
      if (!context.mounted) return false;
      
      _showSnackBar(
        context,
        'Error accepting order: $e',
        Colors.red,
      );
      
      return false;
    } finally {
      // Notify that acceptance process is complete
      onAcceptingStateChanged();
    }
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    if (backgroundColor == Colors.red) {
      AppToast.error(context, message);
    } else {
      AppToast.success(context, message);
    }
  }
}
