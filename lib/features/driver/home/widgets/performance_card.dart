import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class PerformanceCard extends StatelessWidget {
  final String rating;
  final int acceptanceRate;
  final int completionRate;
final bool isOnline;
  const PerformanceCard({
    super.key,
    required this.rating,
    required this.acceptanceRate,
    required this.completionRate,
    required this.isOnline
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: screenWidth < 360 ? 12 : 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: _PerformanceItem(
                icon: Icons.star_border_outlined,
                value: rating,
                label: 'Rating',
                iconColor:isOnline ? AppColors.primaryOrange : AppColors.midGray ,
              ),
            ),
            SizedBox(width: 5),
            Flexible(
              fit: FlexFit.loose,
              child: _PerformanceItem(
                icon: Icons.check_circle_outline,
                value: '$acceptanceRate%',
                label: 'Acceptance',
               iconColor: isOnline ? AppColors.lightGreenIconColor : AppColors.midGray,
              ),
            ),
           SizedBox(width: 5),
            Flexible(
              fit: FlexFit.loose,
              child: _PerformanceItem(
                icon: Icons.grid_view_outlined,
                value: '$completionRate%',
                label: 'Completion',
                iconColor:isOnline ? AppColors.lightBlueIconColor : AppColors.midGray,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PerformanceItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _PerformanceItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      
      padding: EdgeInsets.symmetric(
        vertical: 12,
        horizontal: screenWidth * 0.08,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
       
      ),
      child: Column(
          children: [
            Icon(
              icon,
              size: screenWidth < 350 ? 30 : 35,
              color: iconColor,
            ),
            const SizedBox(height: 8),
        
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
        
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.midGray,
              ),
            ),
          ],
        ),
      
    );
  }
}
