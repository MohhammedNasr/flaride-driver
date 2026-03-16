import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class EmptyEarningsPlaceholder extends StatelessWidget {
  final bool isSmallScreen;

  const EmptyEarningsPlaceholder({
    super.key,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 28 : 32),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'No earnings yet',
          style: GoogleFonts.poppins(color: AppColors.midGray),
        ),
      ),
    );
  }
}
