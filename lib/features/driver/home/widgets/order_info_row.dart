import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class OrderInfoRow extends StatelessWidget {
  final String estimatedTime;
  final String totalDistance;
  final String trafficStatus;

  const OrderInfoRow({
    super.key,
    required this.estimatedTime,
    required this.totalDistance,
    required this.trafficStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _InfoItem(
          icon: Icons.access_time_outlined,
          text: estimatedTime,
        ),
        _InfoItem(
          icon: Icons.route,
          text: totalDistance,
        ),
        Text(
          trafficStatus,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.darkGray,
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primaryOrange,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppColors.darkGray,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
