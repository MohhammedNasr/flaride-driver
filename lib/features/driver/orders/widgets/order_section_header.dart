import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class OrderSectionHeader extends StatelessWidget {
  final String title;

  const OrderSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Padding(
      padding: EdgeInsets.only(
        left: isSmallScreen ? 16 : 20,
        right: isSmallScreen ? 16 : 20,
        top: 8,
        bottom: 8,
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 13 : 14,
          fontWeight: FontWeight.w600,
          color: AppColors.midGray,
        ),
      ),
    );
  }
}
