import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class WorkLocationCard extends StatelessWidget {
  final String? locationAddress;
  final VoidCallback onTap;

  const WorkLocationCard({
    super.key,
    this.locationAddress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = locationAddress != null && locationAddress!.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.lightGray,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: isSmallScreen ? 26 : 30,
              height: isSmallScreen ? 20 : 30,
              decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(
                Icons.location_on_outlined,
                color: AppColors.primaryOrange,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Work location',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.midGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasLocation ? locationAddress! : 'Set your delivery area',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.midGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
