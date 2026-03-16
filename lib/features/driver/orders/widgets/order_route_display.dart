import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/features/driver/shared/widgets/dotted_line_painter.dart';

class OrderRouteDisplay extends StatelessWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final bool isSmallScreen;

  const OrderRouteDisplay({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              Icons.circle,
              size: 12,
              color: AppColors.primaryGreen,
            ),
            SizedBox(
              height: isSmallScreen ? 28 : 32,
              child: CustomPaint(
                painter: DottedLinePainter(
                  color: AppColors.midGray.withOpacity(0.4),
                  strokeWidth: 1.5,
                  dashWidth: 3,
                  dashSpace: 3,
                ),
                size: const Size(1.5, double.infinity),
              ),
            ),
            Icon(
              Icons.location_on,
              size: 16,
              color: AppColors.darkOrange,
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pick up',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.midGray,
                    ),
                  ),
                  Text(
                    'inc. tip',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: AppColors.midGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                pickupLocation,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmallScreen ? 8 : 10),
              Text(
                'Drop Off',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.midGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dropoffLocation,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
