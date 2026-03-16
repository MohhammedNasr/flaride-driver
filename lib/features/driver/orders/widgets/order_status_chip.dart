import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class OrderStatusChip extends StatelessWidget {
  final String status;
  final bool isSmallScreen;

  const OrderStatusChip({
    super.key,
    required this.status,
    required this.isSmallScreen,
  });

  Color _getStatusColor() {
    if (status == 'in_progress' || status == 'driver_assigned') {
      return AppColors.primaryOrange;
    } else if (status == 'completed' || status == 'delivered') {
      return AppColors.lightGreenBadge;
    } else if (status == 'cancelled') {
      return AppColors.lightRedBadge;
    }
    return AppColors.midGray;
  }

  String _getStatusText() {
    if (status == 'in_progress' || status == 'driver_assigned') {
      return 'In progress';
    } else if (status == 'completed' || status == 'delivered') {
      return 'Completed';
    } else if (status == 'cancelled') {
      return 'Canceled';
    }
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 10 : 16,
        vertical: isSmallScreen ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _getStatusText(),
        style: TextStyle(
          fontSize: isSmallScreen ? 10 : 12,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }
}
