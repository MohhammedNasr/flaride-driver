import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/features/driver/orders/widgets/order_status_chip.dart';
import 'package:flaride_driver/features/driver/orders/widgets/order_header_info.dart';
import 'package:flaride_driver/features/driver/orders/widgets/order_route_display.dart';
import 'package:flaride_driver/features/driver/orders/widgets/order_action_button.dart';

class OrderHistoryCard extends StatelessWidget {
  final HistoryOrder order;
  final VoidCallback onTap;
  final VoidCallback? onNavigate;

  const OrderHistoryCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onNavigate,
  });

  bool _isInProgress() {
    return order.status == 'in_progress' || order.status == 'driver_assigned';
  }

  String _getActionText() {
    return _isInProgress() ? 'Navigate' : 'More details';
  }

  String _formatOrderNumber() {
    return '#${order.orderNumber}';
  }

  String _formatTime() {
    if (order.createdAt != null) {
      final hour = order.createdAt!.hour;
      final minute = order.createdAt!.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    }
    return 'No Time';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isInProgress = _isInProgress();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: 6,
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          onTap: isInProgress ? (onNavigate ?? onTap) : onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.primaryOrange.withOpacity(0.1),
          highlightColor: AppColors.primaryOrange.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    OrderStatusChip(
                      status: order.status,
                      isSmallScreen: isSmallScreen,
                    ),
                    const Spacer(),
                    // Show tip badge if has tip
                    if (order.hasTip) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volunteer_activism,
                              size: isSmallScreen ? 12 : 14,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${order.tipAmountDisplay}',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 10 : 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: isSmallScreen ? 8 : 10),
                OrderHeaderInfo(
                  restaurantName: order.restaurant?.name ?? 'Restaurant',
                  orderNumber: _formatOrderNumber(),
                  time: _formatTime(),
                  earnings: order.driverEarningsDisplay,
                  isSmallScreen: isSmallScreen,
                ),
                const SizedBox(height: 2),
                OrderRouteDisplay(
                  pickupLocation: order.restaurant?.address ??
                      order.restaurant?.name ??
                      'Pickup Location',
                  dropoffLocation: order.deliveryAddress ?? 'Delivery Address',
                  isSmallScreen: isSmallScreen,
                ),
                // Show rating if exists
                if (order.hasRating) ...[
                  SizedBox(height: isSmallScreen ? 8 : 10),
                  _buildRatingRow(isSmallScreen),
                ],
                SizedBox(height: isSmallScreen ? 12 : 14),
                Container(
                  height: 1,
                  color: AppColors.dividerGray,
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),
                OrderActionButton(
                  text: _getActionText(),
                  onTap: isInProgress ? (onNavigate ?? onTap) : onTap,
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Star rating
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final rating = order.driverRating ?? 0;
              return Icon(
                index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: isSmallScreen ? 16 : 18,
                color: Colors.amber,
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            order.driverRating?.toStringAsFixed(1) ?? '0',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          // Show review text if exists
          if (order.driverReview != null && order.driverReview!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '"${order.driverReview}"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 11 : 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.midGray,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
