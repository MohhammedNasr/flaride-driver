import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/core/models/driver.dart';
import 'package:flaride_driver/features/driver/rides/ride_driver_apply_screen.dart';

/// Mode switcher widget shown at the top of the driver home screen.
/// Allows dual-mode drivers to toggle between Delivery and Rides.
/// For delivery-only drivers, shows a "Become a driver" CTA.
class DriverModeSwitcher extends StatelessWidget {
  const DriverModeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, provider, _) {
        final driver = provider.driver;
        if (driver == null) return const SizedBox.shrink();

        // Dual-mode or ride driver: tabs handle switching, no widget needed
        if (driver.isDualMode || driver.isRideDriver) {
          return const SizedBox.shrink();
        }

        // Delivery-only driver who can apply for rides
        if (driver.isDeliveryDriver && !driver.isRideDriver) {
          // If they have a pending application, show status
          if (driver.rideApplicationStatus == 'pending_review') {
            return _buildPendingBanner(context);
          }
          if (driver.rideApplicationStatus == 'rejected') {
            return const SizedBox.shrink();
          }
          if (driver.rideApplicationStatus == 'approved') {
            return const SizedBox.shrink();
          }
          // Show CTA to apply
          return _buildApplyCta(context);
        }

        // Ride-only driver: no switcher needed
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildToggle(BuildContext context, DriverProvider provider) {
    final isRides = provider.isInRideMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => provider.switchMode(DriverMode.delivery),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isRides ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isRides
                      ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delivery_dining, size: 20, color: !isRides ? AppColors.primaryOrange : Colors.grey),
                    const SizedBox(width: 6),
                    Text('Delivery', style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: !isRides ? FontWeight.w600 : FontWeight.w400,
                      color: !isRides ? AppColors.textPrimary : Colors.grey,
                    )),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => provider.switchMode(DriverMode.rides),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isRides ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isRides
                      ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car, size: 20, color: isRides ? AppColors.primaryGreen : Colors.grey),
                    const SizedBox(width: 6),
                    Text('Trips', style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: isRides ? FontWeight.w600 : FontWeight.w400,
                      color: isRides ? AppColors.textPrimary : Colors.grey,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyCta(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: AppColors.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RideDriverApplyScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_car, color: AppColors.primaryGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Become a ride driver!', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text('Earn more by transporting passengers', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.primaryGreen, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top, color: Colors.amber.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ride driver application pending', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.amber.shade800)),
                Text('Review within 24-48h', style: GoogleFonts.poppins(fontSize: 11, color: Colors.amber.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
