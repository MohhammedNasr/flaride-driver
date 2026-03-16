import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';

class EarningCard extends StatelessWidget {
  final Earning earning;
  final bool isSmallScreen;

  const EarningCard({
    super.key,
    required this.earning,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = earning.isAvailable
        ? AppColors.primaryGreen
        : earning.isPaid
            ? Colors.blue
            : AppColors.primaryOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerGray),
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 36 : 40,
            height: isSmallScreen ? 36 : 40,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.receipt,
              color: AppColors.primaryOrange,
              size: isSmallScreen ? 18 : 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${earning.orderNumber}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: isSmallScreen ? 13 : 14,
                    color: AppColors.darkGray,
                  ),
                ),
                Text(
                  _formatTimeAgo(earning.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: AppColors.midGray,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                earning.totalAmountDisplay,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: isSmallScreen ? 14 : 15,
                  color: AppColors.primaryGreen,
                ),
              ),
              // Show tip if exists
              if (earning.tipAmount > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volunteer_activism,
                      size: isSmallScreen ? 10 : 11,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '+${(earning.tipAmount / 100).toStringAsFixed(0)} tip',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 9 : 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 2),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 5 : 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  earning.statusDisplay,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 9 : 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
