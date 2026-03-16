import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/core/providers/ride_provider.dart';
import 'package:flaride_driver/core/models/driver.dart';
import 'package:flaride_driver/features/driver/home/screens/map_home_screen.dart';
import 'package:flaride_driver/features/driver/trips/trips_tab_screen.dart';
import 'package:flaride_driver/shared/widgets/app_toast.dart';

class DriverHomeScreen extends StatefulWidget {
  final VoidCallback onLocationTap;
  final Function(AvailableOrder) onOrderTap;
  final VoidCallback onToggleOnline;
  final Function(String)? onActiveOrderTap;

  const DriverHomeScreen({super.key, required this.onLocationTap, required this.onOrderTap, required this.onToggleOnline, this.onActiveOrderTap});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    final dp = context.read<DriverProvider>();
    _tab = TabController(length: 2, vsync: this, initialIndex: dp.isInRideMode ? 1 : 0);
    _tab.addListener(_onTab);
  }

  void _onTab() {
    if (_tab.indexIsChanging) return;
    final dp = context.read<DriverProvider>();
    final rp = context.read<DriverRideProvider>();

    // Block switching to Rides tab if there's an active food delivery
    if (_tab.index == 1 && dp.hasActiveOrderFromApi) {
      _tab.animateTo(0);
      AppToast.warning(context, 'Complete your active delivery first');
      return;
    }

    // Block switching to Food Delivery tab if there's an active ride
    if (_tab.index == 0 && rp.hasActiveTrip) {
      _tab.animateTo(1);
      AppToast.warning(context, 'Complete your active ride first');
      return;
    }

    if (_tab.index == 1 && !dp.isInRideMode) dp.switchMode(DriverMode.rides);
    if (_tab.index == 0 && dp.isInRideMode) dp.switchMode(DriverMode.delivery);
  }

  @override
  void dispose() { _tab.removeListener(_onTab); _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DriverProvider, DriverRideProvider>(
      builder: (context, dp, rp, _) {
        // Determine if tabs should be locked
        final hasActiveDelivery = dp.hasActiveOrderFromApi;
        final hasActiveRide = rp.hasActiveTrip;

        return Column(children: [
          Container(
            color: AppColors.white,
            child: SafeArea(
              bottom: false,
              child: TabBar(
                controller: _tab,
                labelColor: AppColors.primaryOrange,
                unselectedLabelColor: AppColors.midGray,
                labelStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w400),
                indicatorColor: AppColors.primaryOrange,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delivery_dining, size: 18),
                        const SizedBox(width: 6),
                        const Text('Food Delivery'),
                        if (hasActiveDelivery) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_car, size: 18),
                        const SizedBox(width: 6),
                        const Text('Rides'),
                        if (hasActiveRide) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              // Always disable swipe to prevent gesture conflicts with Google Map
              physics: const NeverScrollableScrollPhysics(),
              children: [
                MapHomeScreen(
                  onLocationTap: widget.onLocationTap,
                  onOrderTap: widget.onOrderTap,
                  onToggleOnline: widget.onToggleOnline,
                  onActiveOrderTap: widget.onActiveOrderTap,
                ),
                TripsTabScreen(onToggleOnline: widget.onToggleOnline),
              ],
            ),
          ),
        ]);
      },
    );
  }
}
