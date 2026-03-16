import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class CountdownTimer extends StatelessWidget {
  final int secondsRemaining;

  const CountdownTimer({
    super.key,
    required this.secondsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryOrange,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            secondsRemaining > 0 ? secondsRemaining.toString() : '0',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryOrange,
            ),
          ),
          Text(
            'sec',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
}
