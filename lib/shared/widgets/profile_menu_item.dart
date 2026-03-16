import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/utils/responsive_utils.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.darkGray;
    final effectiveTextColor = textColor ?? AppColors.darkGray;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal:  12,
            vertical: 13,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: effectiveIconColor,
                size: context.scaleFontSize(22),
              ),
              SizedBox(width: context.responsiveValue(mobile: 16, tablet: 20)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: context.scaleFontSize(16),
                    fontWeight: FontWeight.w400,
                    color: effectiveTextColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.midGray,
                size: context.scaleFontSize(24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
