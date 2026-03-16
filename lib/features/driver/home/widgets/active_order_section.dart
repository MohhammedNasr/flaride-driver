import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';

class ActiveOrderSection extends StatelessWidget {
  final OrderDetails order;
  final VoidCallback onTap;
  final VoidCallback? onNavigate;

  const ActiveOrderSection({
    super.key,
    required this.order,
    required this.onTap,
    this.onNavigate,
  });

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
    return '';
  }

  String _getStatusDisplay() {
    switch (order.status) {
      case 'driver_assigned':
        return 'In progress';
      case 'driver_arrived':
        return 'At restaurant';
      case 'picked_up':
        return 'Picked up';
      case 'on_the_way':
        return 'On the way';
      case 'arrived':
        return 'Arrived';
      default:
        return 'In progress';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Order',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        SizedBox(height: isSmallScreen ? 10 : 16),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryOrange.withOpacity(0.3),
                width: 1.5,
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
                // Status chip
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 12,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusDisplay(),
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 11 : 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 10),
                // Restaurant name and earnings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.restaurant?.name ?? 'Restaurant',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGray,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                _formatOrderNumber(),
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  color: AppColors.midGray,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 4 : 6,
                                ),
                                child: Text(
                                  '•',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: AppColors.midGray,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTime(),
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  color: AppColors.midGray,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
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
                  ],
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),
                // Pickup location
                Row(
                  children: [
                    Container(
                      width: isSmallScreen ? 18 : 20,
                      height: isSmallScreen ? 18 : 20,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.store_outlined,
                        size: isSmallScreen ? 10 : 12,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pick up',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 10 : 11,
                              color: AppColors.midGray,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            order.restaurant?.address ?? order.restaurant?.name ?? 'Pickup Location',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: AppColors.darkGray,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Dotted line connector
                Padding(
                  padding: EdgeInsets.only(left: isSmallScreen ? 8 : 9),
                  child: Container(
                    width: 2,
                    height: isSmallScreen ? 12 : 16,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColors.midGray.withOpacity(0.5),
                          width: 1,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
                  ),
                ),
                // Drop off location
                Row(
                  children: [
                    Container(
                      width: isSmallScreen ? 18 : 20,
                      height: isSmallScreen ? 18 : 20,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        size: isSmallScreen ? 10 : 12,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Drop Off',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 10 : 11,
                              color: AppColors.midGray,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            order.delivery?.address ?? 'Delivery Address',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: AppColors.darkGray,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 14),
                Container(
                  height: 1,
                  color: AppColors.dividerGray,
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),
                // Navigate button
                GestureDetector(
                  onTap: onNavigate ?? onTap,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Navigate',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 6),
                      Icon(
                        Icons.arrow_forward,
                        size: isSmallScreen ? 16 : 18,
                        color: AppColors.primaryOrange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _extractAmount(String earnings) {
    final regex = RegExp(r'[\d,]+\.?\d*');
    final match = regex.firstMatch(earnings);
    return match?.group(0) ?? '0.00';
  }
}
