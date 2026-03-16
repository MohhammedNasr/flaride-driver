
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class TodaySummaryCard extends StatelessWidget {
  final String earnings;
  final int trips;
  final String onlineTime;
final bool isOnline;
  const TodaySummaryCard({
    super.key,
    required this.earnings,
    required this.trips,
    required this.onlineTime,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.lightGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today Summary',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          SizedBox(
            height: isSmallScreen ? 60 : 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Earnings',
                    value: earnings,
                    isOnline: isOnline,
                  ),
                ),
                VerticalDivider(
                  color: Colors.grey,
                  thickness: 1,
                  width: 20,
                  indent: 5,
                  endIndent: 5,
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Trips',
                    value: trips.toString(),
                    isOnline: isOnline,
                  ),
                ),
                VerticalDivider(
                  color: Colors.grey,
                  thickness: 1,
                  width: 20,
                  indent: 5,
                  endIndent: 5,
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Online',
                    value: onlineTime,
                    isOnline: isOnline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
final bool isOnline;
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 16 : 18,
            color:isOnline? AppColors.primaryOrange : AppColors.midGray,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
