import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/features/driver/orders/widgets/order_card.dart';
import 'package:flaride_driver/features/driver/orders/widgets/no_orders_state.dart';

class AvailableOrdersSection extends StatelessWidget {
  final List<AvailableOrder> orders;
  final Function(AvailableOrder) onOrderTap;
  final VoidCallback? onViewMap;
final bool isOnline;
  const AvailableOrdersSection({
    super.key,
    required this.orders,
    required this.onOrderTap,
    this.onViewMap,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Orders',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
            if (onViewMap != null)
              TextButton(
                onPressed: onViewMap,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View map',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:isOnline ?  AppColors.primaryOrange : AppColors.midGray,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 10 : 16),
        if (orders.isEmpty)
           NoOrdersState(isOnline: isOnline,)
        else
          ...orders.map((order) => OrderCard(
                order: order,
                onTap: () => onOrderTap(order),
              )),
      ],
    );
  }
}
