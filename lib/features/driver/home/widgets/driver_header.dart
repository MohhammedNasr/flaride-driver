import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class DriverHeader extends StatelessWidget {
  final String driverName;
  final String? profileImageUrl;

  const DriverHeader({
    super.key,
    required this.driverName,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final firstName = driverName.split(' ').first;

    return Row(
      children: [
        Container(
          width: isSmallScreen ? 44 : 48,
          height: isSmallScreen ? 44 : 48,
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryOrange.withOpacity(0.3),
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: profileImageUrl != null && profileImageUrl!.isNotEmpty
              ? Image.network(
                  profileImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.person,
                    color: AppColors.midGray,
                    size: 24,
                  ),
                )
              : Icon(
                  Icons.person,
                  color: AppColors.midGray,
                  size: 24,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Driver Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: AppColors.midGray,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                firstName,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.notifications_outlined,
          color: AppColors.darkGray,
          size: 32,
        ),
      ],
    );
  }
}
