import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/features/driver/earning/widgets/area_chart_painter.dart';

class WeeklyEarningsChart extends StatelessWidget {
  final List<Earning> earnings;
  final bool isSmallScreen;

  const WeeklyEarningsChart({
    super.key,
    required this.earnings,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final currentDay = DateTime.now().weekday % 7;
    
    final weeklyData = _calculateWeeklyEarnings();
    
    final maxValue = weeklyData.isEmpty ? 100.0 : weeklyData.reduce((a, b) => a > b ? a : b);
    final avgValue = weeklyData.isEmpty ? 0.0 : weeklyData.reduce((a, b) => a + b) / weeklyData.length;
    final currentValue = weeklyData.isEmpty ? 0.0 : weeklyData[currentDay];
    final percentChange = avgValue > 0 ? ((currentValue - avgValue) / avgValue * 100).toStringAsFixed(0) : '0';
    final isPositive = currentValue >= avgValue;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerGray.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Earnings',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive ? AppColors.lightGreenIconColor : AppColors.lightRedBadge,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}$percentChange%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? AppColors.lightGreenIconColor : AppColors.lightRedBadge,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 20 : 24),
          SizedBox(
            height: isSmallScreen ? 160 : 180,
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: AreaChartPainter(
                      data: weeklyData,
                      maxValue: maxValue,
                    ),
                    child: Container(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    final isToday = index == currentDay;
                    return Text(
                      weekDays[index],
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 10 : 11,
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                        color: isToday ? AppColors.primaryOrange : AppColors.midGray,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<double> _calculateWeeklyEarnings() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    
    final dailyEarnings = List<double>.filled(7, 0.0);
    
    for (final earning in earnings) {
      if (earning.createdAt != null) {
        final earningDate = earning.createdAt!;
        final daysDiff = earningDate.difference(weekStart).inDays;
        
        if (daysDiff >= 0 && daysDiff < 7) {
          dailyEarnings[daysDiff] += earning.totalAmount / 100.0;
        }
      }
    }
    
    return dailyEarnings;
  }
}
