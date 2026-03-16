import 'package:flaride_driver/features/driver/home/widgets/available_orders_section.dart';
import 'package:flaride_driver/features/driver/home/widgets/driver_header.dart';
import 'package:flaride_driver/features/driver/home/widgets/online_status_toggle.dart';
import 'package:flaride_driver/features/driver/home/widgets/performance_card.dart';
import 'package:flaride_driver/features/driver/home/widgets/today_summary_card.dart';
import 'package:flaride_driver/features/driver/home/widgets/work_location_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/core/services/driver_service.dart';

class DriverHomeTab extends StatelessWidget {
  final VoidCallback onLocationTap;
  final Function(AvailableOrder) onOrderTap;
  final VoidCallback onToggleOnline;

  const DriverHomeTab({
    super.key,
    required this.onLocationTap,
    required this.onOrderTap,
    required this.onToggleOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, driverProvider, child) {
        if (driverProvider.isLoading && driverProvider.driver == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryOrange),
          );
        }

        final driver = driverProvider.driver;
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;
        final horizontalPadding = isSmallScreen ? 16.0 : 20.0;

        return RefreshIndicator(
          onRefresh: () => driverProvider.refreshProfile(),
          color: AppColors.primaryOrange,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DriverHeader(
                  driverName: driver?.name ?? 'Driver',
                  profileImageUrl: driver?.profilePhoto,
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                OnlineStatusToggle(
                  isOnline: driverProvider.isOnline,
                  isLoading: driverProvider.isLoading,
                  onToggle: onToggleOnline,
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                WorkLocationCard(
                  locationAddress: driverProvider.workLocationAddress,
                  onTap: onLocationTap,
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                TodaySummaryCard(
                  isOnline: driverProvider.isOnline,
                  earnings: driver?.todayEarningsDisplay ?? 'XOF 0.00',
                  trips: driver?.todayDeliveries ?? 0,
                  onlineTime: driver?.onlineTimeDisplay ?? '0H20m',
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                PerformanceCard(
                  isOnline: driverProvider.isOnline,
                  rating: driver?.ratingDisplay ?? '4.9',
                  acceptanceRate: driver?.acceptanceRate.toInt() ?? 98,
                  completionRate: driver?.completionRate.toInt() ?? 100,
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                if (driverProvider.isOnline) ...[
                  AvailableOrdersSection(
                    orders: driverProvider.availableOrders,
                    onOrderTap: onOrderTap,
                    isOnline: driverProvider.isOnline,
                    onViewMap: () {},
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
