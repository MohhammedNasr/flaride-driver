import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class OrderHistoryHeader extends StatelessWidget {
  final bool isSmallScreen;
  final double padding;

  const OrderHistoryHeader({
    super.key,
    required this.isSmallScreen,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Align(
        alignment: AlignmentGeometry.topLeft,
        child: Text(
          'Order History',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
      ),
    );
  }
}
