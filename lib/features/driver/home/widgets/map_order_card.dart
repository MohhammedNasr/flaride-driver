import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/features/driver/home/widgets/location_row.dart';
import 'package:flaride_driver/features/driver/home/widgets/order_header.dart';
import 'package:flaride_driver/features/driver/home/widgets/order_info_row.dart';
import 'package:flaride_driver/features/driver/home/widgets/countdown_timer.dart';
import 'package:flaride_driver/features/driver/home/widgets/order_action_buttons.dart';

class MapOrderCard extends StatefulWidget {
  final AvailableOrder order;
  final VoidCallback onDecline;
  final VoidCallback onAccept;
  final VoidCallback? onCardTap;

  const MapOrderCard({
    super.key,
    required this.order,
    required this.onDecline,
    required this.onAccept,
    this.onCardTap,
  });

  @override
  State<MapOrderCard> createState() => _MapOrderCardState();
}

class _MapOrderCardState extends State<MapOrderCard> {
  bool _isDeclined = false;

  void _handleDecline() {
    setState(() {
      _isDeclined = true;
    });
    widget.onDecline();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return AnimatedOpacity(
      opacity: _isDeclined ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
        child: Material(
          color: _isDeclined ? AppColors.lightGray : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _isDeclined ? null : widget.onCardTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: AppColors.primaryOrange.withOpacity(0.1),
            highlightColor: AppColors.primaryOrange.withOpacity(0.05),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isDeclined ? AppColors.midGray : AppColors.lightGray,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrderHeader(
                    orderNumber: widget.order.orderNumber,
                    restaurantName: widget.order.restaurant?.name,
                    countdownTimer: CountdownTimer(
                      secondsRemaining: _getSecondsRemaining(),
                    ),
                    isSmallScreen: isSmallScreen,
                  ),
                  const SizedBox(height: 12),
                  OrderInfoRow(
                    estimatedTime: _getEstimatedTime(),
                    totalDistance: _getTotalDistance(),
                    trafficStatus: 'Light traffic',
                  ),
                  const SizedBox(height: 6),
                  const Divider(),
                  const SizedBox(height: 10),
                  LocationRow(
                    icon: Icons.restaurant_outlined,
                    label: 'Pick up',
                    address: _getPickupAddress(),
                  ),
                  const SizedBox(height: 12),
                  LocationRow(
                    icon: Icons.location_on_outlined,
                    label: 'Drop Off',
                    address: _getDropOffAddress(),
                  ),
                  const SizedBox(height: 16),
                  if (!_isDeclined)
                    OrderActionButtons(
                      onDecline: _handleDecline,
                      onAccept: widget.onAccept,
                    )
                  else
                    Center(
                      child: Text(
                        'Declined',
                        style: TextStyle(
                          color: AppColors.midGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _getSecondsRemaining() {
    final now = DateTime.now();
    final readyTime = widget.order.readyForPickupAt ?? now;
    return readyTime.difference(now).inSeconds;
  }

  String _getEstimatedTime() {
    final pickupDistance = double.tryParse(widget.order.pickupDistanceKm ?? '0') ?? 0;
    final deliveryDistance = double.tryParse(widget.order.deliveryDistanceKm ?? '0') ?? 0;
    final totalDistance = pickupDistance + deliveryDistance;
    
    final estimatedMinutes = (totalDistance * 3).round();
    
    return '$estimatedMinutes min';
  }

  String _getTotalDistance() {
    final pickupDistance = double.tryParse(widget.order.pickupDistanceKm ?? '0') ?? 0;
    final deliveryDistance = double.tryParse(widget.order.deliveryDistanceKm ?? '0') ?? 0;
    final totalDistance = pickupDistance + deliveryDistance;
    
    return '${totalDistance.toStringAsFixed(1)} KM';
  }

  String _getPickupAddress() {
    // Show restaurant address if available, otherwise show restaurant name
    if (widget.order.restaurant?.address != null && widget.order.restaurant!.address!.isNotEmpty) {
      return widget.order.restaurant!.address!;
    }
    return widget.order.restaurant?.name ?? 'Restaurant';
  }

  String _getDropOffAddress() {
    // Show delivery address if available
    if (widget.order.deliveryAddress != null && widget.order.deliveryAddress!.isNotEmpty) {
      // Truncate long addresses
      final address = widget.order.deliveryAddress!;
      if (address.length > 40) {
        return '${address.substring(0, 40)}...';
      }
      return address;
    }
    return 'Delivery location';
  }
}
