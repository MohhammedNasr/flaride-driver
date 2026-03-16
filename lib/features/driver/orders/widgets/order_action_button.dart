import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class OrderActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const OrderActionButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.arrow_forward,
            size: isSmallScreen ? 16 : 18,
            color: AppColors.primaryOrange,
          ),
        ],
      ),
    );
  }
}
