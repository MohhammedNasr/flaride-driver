import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class OrderHeader extends StatelessWidget {
  final String orderNumber;
  final String? restaurantName;
  final Widget countdownTimer;
  final bool isSmallScreen;

  const OrderHeader({
    super.key,
    required this.orderNumber,
    this.restaurantName,
    required this.countdownTimer,
    this.isSmallScreen = false,
  });

  String _getDisplayTitle() {
    final restaurant = restaurantName ?? 'Order';
    // Get last 6 characters of order number
    final shortOrderNum = orderNumber.length > 6 
        ? orderNumber.substring(orderNumber.length - 6) 
        : orderNumber;
    return '$restaurant • #$shortOrderNum';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Food Delivery',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getDisplayTitle(),
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        countdownTimer,
      ],
    );
  }
}
