import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';

class OrderCard extends StatelessWidget {
  final AvailableOrder order;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.lightGray,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.restaurant?.name ?? 'Restaurant',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'XOF',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    Text(
                      _extractAmount(order.estimatedEarnings),
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // SizedBox(height: isSmallScreen ? 10 : 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: isSmallScreen ? 14 : 16,
                  color: AppColors.primaryOrange,
                ),
                SizedBox(width: isSmallScreen ? 3 : 4),
                Text(
                  '25 min',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: AppColors.darkGray,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8),
                  child: Text(
                    '•',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: AppColors.midGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${order.itemsCount} items',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: AppColors.darkGray,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                Text(
                  'inc. tip',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: AppColors.midGray,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 10 : 12),
            Divider(
              color: AppColors.lightGray,
              thickness: 1,
              height: 1,
            ),
            SizedBox(height: isSmallScreen ? 10 : 12),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: isSmallScreen ? 14 : 16,
                  color: AppColors.primaryOrange,
                ),
                SizedBox(width: isSmallScreen ? 3 : 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress ?? 'Delivery address',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: AppColors.darkGray,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Container(
                  width: isSmallScreen ? 28 : 32,
                  height: isSmallScreen ? 28 : 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: AppColors.white,
                    size: isSmallScreen ? 16 : 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _extractAmount(String earnings) {
    final regex = RegExp(r'[\d,]+\.?\d*');
    final match = regex.firstMatch(earnings);
    return match?.group(0) ?? '0.00';
  }
}
