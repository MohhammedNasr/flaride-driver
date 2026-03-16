import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/core/providers/ride_provider.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/features/driver/order_details_screen.dart';
import 'package:flaride_driver/features/driver/active_delivery_screen.dart';
import 'package:flaride_driver/features/driver/rides/ride_offer_overlay.dart';
import 'package:flaride_driver/features/driver/rides/active_ride_screen.dart';
import 'package:flaride_driver/features/driver/home/screens/driver_home_screen.dart';
import 'package:flaride_driver/features/driver/widgets/driver_account_tab.dart';
import 'package:flaride_driver/features/driver/widgets/driver_bottom_nav.dart';
import 'package:flaride_driver/features/driver/location_picker_screen.dart';
import 'package:flaride_driver/features/driver/tabs/earnings_tab.dart';
import 'package:flaride_driver/features/driver/orders/screens/order_history_screen.dart';
import 'package:flaride_driver/shared/widgets/app_toast.dart';

class DriverHomePage extends StatefulWidget {
  static const String routeName = '/driver-home';

  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _orderCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().checkDriverStatus();
      _startBackgroundOrderCheck();
      // Check for existing ride trip and start offer polling
      final rideProvider = context.read<DriverRideProvider>();
      rideProvider.checkExistingTrip();
      rideProvider.addListener(_onRideStateChanged);
    });
  }
  
  @override
  void dispose() {
    _orderCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    try {
      context.read<DriverRideProvider>().removeListener(_onRideStateChanged);
    } catch (_) {}
    super.dispose();
  }

  bool _isShowingOffer = false;
  bool _isOnActiveRideScreen = false;

  void _onRideStateChanged() {
    if (!mounted) return;
    final rideProvider = context.read<DriverRideProvider>();

    // Show offer overlay when a new offer arrives
    if (rideProvider.state == DriverRideState.hasOffer && rideProvider.currentOffer != null && !_isShowingOffer) {
      _isShowingOffer = true;
      _showOfferOverlay(rideProvider.currentOffer!);
    }

    // Navigate to active ride screen when trip starts or is restored
    if ((rideProvider.state == DriverRideState.enRouteToPickup ||
         rideProvider.state == DriverRideState.waitingAtPickup ||
         rideProvider.state == DriverRideState.inProgress) &&
        rideProvider.activeTrip != null) {
      // Avoid pushing duplicate routes
      if (!_isOnActiveRideScreen) {
        _isOnActiveRideScreen = true;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActiveRideScreen(initialTrip: rideProvider.activeTrip!),
          ),
        ).then((_) => _isOnActiveRideScreen = false);
      }
    }
  }

  void _showOfferOverlay(offer) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (ctx, _, __) => RideOfferOverlay(
        offer: offer,
        onAccepted: () {
          Navigator.of(ctx).pop();
          _isShowingOffer = false;
        },
        onRejected: () {
          Navigator.of(ctx).pop();
          _isShowingOffer = false;
        },
        onExpired: () {
          Navigator.of(ctx).pop();
          _isShowingOffer = false;
        },
      ),
    );
  }

  void _startBackgroundOrderCheck() {
    _orderCheckTimer?.cancel();
    _orderCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final driverProvider = context.read<DriverProvider>();
      if (driverProvider.isOnline && mounted) {
        driverProvider.fetchAvailableOrders();
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final driverProvider = context.read<DriverProvider>();
      final rideProvider = context.read<DriverRideProvider>();
      if (driverProvider.isOnline) {
        driverProvider.fetchAvailableOrders();
      }
      // Re-check for existing ride trip on resume
      rideProvider.checkExistingTrip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
            _buildOrdersTab(),
            _buildEarningsTab(),
            _buildAccountTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab() {
    return DriverHomeScreen(
      onLocationTap: () {
        final driverProvider = context.read<DriverProvider>();
        _showLocationPicker(context, driverProvider);
      },
      onOrderTap: _openOrderDetails,
      onActiveOrderTap: _openActiveDelivery,
      onToggleOnline: () async {
        final driverProvider = context.read<DriverProvider>();
        await driverProvider.toggleOnlineStatus();
        final rideProvider = context.read<DriverRideProvider>();
        if (driverProvider.isOnline) {
          // Always start both polling types since both tabs are visible
          _startBackgroundOrderCheck();
          rideProvider.startOfferPolling();
        } else {
          _orderCheckTimer?.cancel();
          rideProvider.stopOfferPolling();
        }
      },
    );
  }

  void _openOrderDetails(AvailableOrder order) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(orderId: order.id),
      ),
    );
    
    if (result == true && mounted) {
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      await driverProvider.fetchAvailableOrders();
    }
  }

  void _openActiveDelivery(String orderId) async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final orderDetails = driverProvider.activeOrderDetails;
    
    if (orderDetails != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveDeliveryScreen(order: orderDetails),
        ),
      );
      
      // Refresh orders after returning from active delivery
      if (mounted) {
        await driverProvider.fetchAvailableOrders();
      }
    }
  }

  Widget _buildOrdersTab() {
    return const OrderHistoryScreen();
  }

  Widget _buildEarningsTab() {
    return const EarningsTab();
  }

  Widget _buildAccountTab() {
    return DriverAccountTab(
      onLocationTap: () {
        final driverProvider = context.read<DriverProvider>();
        _showLocationPicker(context, driverProvider);
      },
    );
  }

  void _showLocationPicker(BuildContext context, DriverProvider driverProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: driverProvider.hasWorkLocation
              ? LatLng(
                  driverProvider.workLocationLat!,
                  driverProvider.workLocationLng!,
                )
              : driverProvider.driver?.currentLatitude != null
                  ? LatLng(
                      driverProvider.driver!.currentLatitude!,
                      driverProvider.driver!.currentLongitude!,
                    )
                  : null,
          onLocationSelected: (LatLng location, String? address) async {
            final success = await driverProvider.updateWorkLocation(
              latitude: location.latitude,
              longitude: location.longitude,
              address: address,
            );
            if (success && context.mounted) {
              AppToast.success(context, 'Work location updated!');
            }
          },
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return DriverBottomNav(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
    );
  }
}
