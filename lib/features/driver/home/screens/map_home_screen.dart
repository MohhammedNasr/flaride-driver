import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/features/driver/home/widgets/home_online_toggle.dart';
import 'package:flaride_driver/features/driver/home/widgets/home_location_bar.dart';
import 'package:flaride_driver/features/driver/home/widgets/declined_orders_sheet.dart';
import 'package:flaride_driver/features/driver/parcels/parcel_driver_provider.dart';
import 'package:flaride_driver/features/driver/parcels/parcel_order_model.dart';
import 'package:flaride_driver/features/driver/parcels/active_parcel_delivery_screen.dart';

class MapHomeScreen extends StatefulWidget {
  final VoidCallback onLocationTap;
  final Function(AvailableOrder) onOrderTap;
  final VoidCallback onToggleOnline;
  final Function(String)? onActiveOrderTap;

  const MapHomeScreen({
    super.key,
    required this.onLocationTap,
    required this.onOrderTap,
    required this.onToggleOnline,
    this.onActiveOrderTap,
  });

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  int _currentOrderIndex = 0;
  PageController? _pageController;
  Timer? _countdownTimer;
  int _secondsRemaining = 38;
  double? _lastWorkLocationLat;
  double? _lastWorkLocationLng;

  Set<String> _declinedOrderIds = {};
  Set<String> _hiddenOrderIds = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _getCurrentLocation();
    _startCountdownTimer();

    // Listen for work location changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverProvider = context.read<DriverProvider>();
      _lastWorkLocationLat = driverProvider.workLocationLat;
      _lastWorkLocationLng = driverProvider.workLocationLng;
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _countdownTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _secondsRemaining = 38;
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Move to work location if set
    final driverProvider = context.read<DriverProvider>();
    if (driverProvider.hasWorkLocation) {
      _moveToWorkLocation(
          driverProvider.workLocationLat!, driverProvider.workLocationLng!);
    }
  }

  void _moveToWorkLocation(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15.0),
    );
  }

  void _checkAndMoveToWorkLocation(DriverProvider driverProvider) {
    final newLat = driverProvider.workLocationLat;
    final newLng = driverProvider.workLocationLng;

    // Check if work location has changed
    if (newLat != null &&
        newLng != null &&
        (newLat != _lastWorkLocationLat || newLng != _lastWorkLocationLng)) {
      _lastWorkLocationLat = newLat;
      _lastWorkLocationLng = newLng;
      _moveToWorkLocation(newLat, newLng);
    }
  }

  void _updateMapMarkers(List<AvailableOrder> allOrders) {
    Set<Marker> newMarkers = {};
    List<LatLng> boundsPoints = [];

    // Filter valid orders
    final visibleOrders =
        allOrders.where((o) => !_declinedOrderIds.contains(o.id)).toList();

    // Filter orders by distance from work location (10km radius)
    final filteredOrders = visibleOrders.where((order) {
      if (order.restaurant?.latitude == null ||
          order.restaurant?.longitude == null) return false;

      // If no work location set, show all orders
      if (_lastWorkLocationLat == null || _lastWorkLocationLng == null)
        return true;

      // Calculate distance from work location
      final distance = Geolocator.distanceBetween(
        _lastWorkLocationLat!,
        _lastWorkLocationLng!,
        order.restaurant!.latitude!,
        order.restaurant!.longitude!,
      );

      // Only show orders within 10km of work location
      return distance <= 10000; // 10km in meters
    }).toList();

    final activeOrders =
        filteredOrders.where((o) => !_hiddenOrderIds.contains(o.id)).toList();

    // Determine current active order based on index
    AvailableOrder? currentActiveOrder;
    if (activeOrders.isNotEmpty) {
      if (_currentOrderIndex >= activeOrders.length) {
        _currentOrderIndex = 0;
      }
      currentActiveOrder = activeOrders[_currentOrderIndex];
    }

    // Process all filtered orders - only show pickup pins
    for (final order in filteredOrders) {
      // Skip if no restaurant location
      if (order.restaurant?.latitude == null ||
          order.restaurant?.longitude == null) continue;

      final isHidden = _hiddenOrderIds.contains(order.id);
      final isActive = !isHidden && order.id == currentActiveOrder?.id;
      final pickupPos =
          LatLng(order.restaurant!.latitude!, order.restaurant!.longitude!);

      if (isHidden) {
        // Hidden order: Show semi-transparent marker
        newMarkers.add(
          Marker(
            markerId: MarkerId('hidden_${order.id}'),
            position: pickupPos,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
            alpha: 0.6,
            infoWindow: InfoWindow(
              title: order.restaurant?.name ?? 'Available Order',
              snippet: 'Tap to view',
              onTap: () => _unhideOrder(order.id, activeOrders),
            ),
            onTap: () => _unhideOrder(order.id, activeOrders),
          ),
        );
        boundsPoints.add(pickupPos);
      } else if (isActive) {
        // Current Active Order: Show pickup marker only with GREEN color to highlight
        newMarkers.add(
          Marker(
            markerId: const MarkerId('pickup_active'),
            position: pickupPos,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: order.restaurant?.name ?? 'Pickup',
              snippet: order.restaurant?.address,
            ),
            zIndex: 10,
          ),
        );
        boundsPoints.add(pickupPos);
      } else {
        // Other Active Orders (Visible but not currently selected card)
        final index = activeOrders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          newMarkers.add(
            Marker(
              markerId: MarkerId('order_${order.id}'),
              position: pickupPos,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange),
              infoWindow: InfoWindow(
                title: order.restaurant?.name,
                snippet: 'Tap to select',
                onTap: () {
                  if (_pageController != null && _pageController!.hasClients) {
                    _pageController!.animateToPage(index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  }
                },
              ),
              onTap: () {
                if (_pageController != null && _pageController!.hasClients) {
                  _pageController!.animateToPage(index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                }
              },
            ),
          );
          boundsPoints.add(pickupPos);
        }
      }
    }

    // Fit bounds to all pickup points
    if (boundsPoints.isNotEmpty) {
      _fitMapToBounds(boundsPoints);
    }

    setState(() {
      _markers = newMarkers;
      _polylines = {}; // No polylines needed
    });
  }

  bool isActiveOrderValid(AvailableOrder order) {
    return (order.restaurant?.latitude != null &&
            order.restaurant?.longitude != null) ||
        (order.deliveryLatitude != null && order.deliveryLongitude != null);
  }

  void _hideOrder(String orderId) {
    setState(() {
      _hiddenOrderIds.add(orderId);
      // Determine new index is handled by UI rebuild usually, but let's be safe
      if (_currentOrderIndex > 0) _currentOrderIndex--;
    });
  }

  void _unhideOrder(String orderId, List<AvailableOrder> currentActiveOrders) {
    setState(() {
      _hiddenOrderIds.remove(orderId);
      // Wait for rebuild to find new index
    });

    // Find where the order will be
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Need to fetch fresh list or recalculate
      // This is a bit tricky since we need the 'future' list state.
      // Simplification: Just let the Map/Page update.

      // We want to jump to this order.
      final driverProvider = context.read<DriverProvider>();
      final orders = driverProvider.availableOrders
          .where((o) =>
              !_declinedOrderIds.contains(o.id) &&
              !_hiddenOrderIds.contains(o.id))
          .toList();

      final index = orders.indexWhere((o) => o.id == orderId);
      if (index != -1 && _pageController!.hasClients) {
        _pageController?.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _restoreDeclinedOrder(String orderId) {
    setState(() {
      _declinedOrderIds.remove(orderId);
    });
  }

  void _openDeclinedOrdersSheet() {
    final driverProvider = context.read<DriverProvider>();
    final declinedOrders = driverProvider.availableOrders
        .where((o) => _declinedOrderIds.contains(o.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeclinedOrdersSheet(
        declinedOrders: declinedOrders,
        onRestore: _restoreDeclinedOrder,
      ),
    );
  }

  // Create a curved route that looks more like a real road path
  List<LatLng> _createCurvedRoute(LatLng start, LatLng end) {
    List<LatLng> points = [];
    const int segments = 20;

    // Calculate the midpoint with an offset to create a curve
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;

    // Calculate perpendicular offset for the curve
    final latDiff = end.latitude - start.latitude;
    final lngDiff = end.longitude - start.longitude;
    final distance = sqrt(latDiff * latDiff + lngDiff * lngDiff);

    // Offset the midpoint perpendicular to the line (creates a curve)
    final offsetAmount = distance * 0.15; // 15% of distance for curve
    final perpLat = -lngDiff / distance * offsetAmount;
    final perpLng = latDiff / distance * offsetAmount;

    final controlLat = midLat + perpLat;
    final controlLng = midLng + perpLng;

    // Generate points along a quadratic bezier curve
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final lat = (1 - t) * (1 - t) * start.latitude +
          2 * (1 - t) * t * controlLat +
          t * t * end.latitude;
      final lng = (1 - t) * (1 - t) * start.longitude +
          2 * (1 - t) * t * controlLng +
          t * t * end.longitude;
      points.add(LatLng(lat, lng));
    }

    return points;
  }

  void _fitMapToBounds(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    // Expand bounds to show more context (about 2km around the points)
    const double padding = 0.015; // ~1.5km in each direction
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }

  void _clearMapMarkers() {
    setState(() {
      _markers = {};
      _polylines = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DriverProvider, ParcelDriverProvider>(
      builder: (context, driverProvider, parcelProvider, child) {
        final foodOrders = driverProvider.availableOrders;
        final parcelOrders = parcelProvider.availableOrders;
        final isOnline = driverProvider.isOnline;
        final hasActiveFoodOrder = driverProvider.hasActiveOrderFromApi;
        final activeOrderDetails = driverProvider.activeOrderDetails;
        final hasActiveParcelOrder = parcelProvider.hasActiveParcelOrder;
        final hasAnyActiveOrder = hasActiveFoodOrder || hasActiveParcelOrder;
        final hasAnyOrders = foodOrders.isNotEmpty || parcelOrders.isNotEmpty;
        final hasInitialFetch = driverProvider.hasInitialOrdersFetch;

        // Check if work location changed and move map
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndMoveToWorkLocation(driverProvider);
        });

        return Stack(
          children: [
            _buildMap(),
            _buildTopSection(driverProvider),
            if (isOnline && hasActiveFoodOrder && activeOrderDetails != null)
              _buildActiveOrderCard(activeOrderDetails, driverProvider)
            else if (isOnline &&
                hasActiveParcelOrder &&
                parcelProvider.activeOrder != null)
              _buildActiveParcelOrderCard(
                  parcelProvider.activeOrder!, parcelProvider)
            else if (isOnline && hasAnyOrders)
              _buildUnifiedOrderCards(foodOrders, parcelOrders, driverProvider),
            if (isOnline &&
                !hasAnyActiveOrder &&
                !hasAnyOrders &&
                hasInitialFetch)
              _buildNoOrdersMessage(),
            if (isOnline && !hasInitialFetch) _buildLoadingOrders(),
          ],
        );
      },
    );
  }

  Widget _buildMap() {
    if (_isLoadingLocation) {
      return Container(
        color: AppColors.lightGray,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
      );
    }

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _currentPosition ?? const LatLng(5.3600, -4.0083),
        zoom: 14.0,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      minMaxZoomPreference: const MinMaxZoomPreference(5.0, 20.0),
    );
  }

  Widget _buildTopSection(DriverProvider driverProvider) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Column(
        children: [
          HomeOnlineToggle(
            isOnline: driverProvider.isOnline,
            isLoading: driverProvider.isLoading,
            onToggle: widget.onToggleOnline,
            profilePictureUrl: driverProvider.driver?.profilePhoto,
          ),
          const SizedBox(height: 12),
          HomeLocationBar(
            locationAddress: driverProvider.workLocationAddress,
            onTap: widget.onLocationTap,
          ),
          if (_declinedOrderIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _openDeclinedOrdersSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history,
                        size: 16, color: AppColors.primaryOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Declined: ${_declinedOrderIds.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderCards(
      List<AvailableOrder> allOrders, DriverProvider driverProvider) {
    // Filter out declined AND hidden orders for the card view
    final visibleOrders =
        allOrders.where((o) => !_declinedOrderIds.contains(o.id)).toList();
    final activeOrders =
        visibleOrders.where((o) => !_hiddenOrderIds.contains(o.id)).toList();

    // Update map markers whenever list changes or build happens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMapMarkers(allOrders);
    });

    if (activeOrders.isEmpty && visibleOrders.isNotEmpty) {
      // All orders hidden
      return Positioned(
        bottom: 32,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: const Text("All orders hidden. Tap pins on map to view."),
          ),
        ),
      );
    }

    if (activeOrders.isEmpty) {
      return _buildNoOrdersMessage();
    }

    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 320,
        child: PageView.builder(
          controller: _pageController,
          itemCount: activeOrders.length,
          onPageChanged: (index) {
            setState(() {
              _currentOrderIndex = index;
              _secondsRemaining = 38;
            });
            // Map update happens automatically due to state change triggering build -> postFrameCallback
            // or we can force it here for smoothness if needed, but setState triggers build.
          },
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildFloatingOrderCard(activeOrders[index], activeOrders),
            );
          },
        ),
      ),
    );
  }

  void _declineOrder(String orderId) {
    setState(() {
      _declinedOrderIds.add(orderId);
      _secondsRemaining = 38;
    });
  }

  Widget _buildFloatingOrderCard(
      AvailableOrder order, List<AvailableOrder> orders) {
    final totalDistance = _getTotalDistance(order);
    final estimatedTime = _getEstimatedTime(order);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with badge and close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant, color: AppColors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Delivery',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _hideOrder(order.id),
                  icon: Icon(Icons.close, color: AppColors.midGray, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Hide for now',
                ),
              ],
            ),
          ),
          // Time and distance info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Icon(Icons.access_time, color: AppColors.midGray, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$estimatedTime ($totalDistance) total',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Pickup location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(Icons.circle, color: AppColors.darkGray, size: 10),
                    Container(width: 2, height: 30, color: AppColors.lightGray),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.restaurant?.name ?? 'Restaurant',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                        ),
                      ),
                      if (order.restaurant?.address != null)
                        Text(
                          order.restaurant!.address!,
                          style:
                              TextStyle(fontSize: 12, color: AppColors.midGray),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Delivery location (Destination)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle_outlined, color: AppColors.midGray, size: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.deliveryAddress ?? 'Destination',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Countdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Respond in ',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.midGray)),
                    Text(
                      '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryOrange),
                    ),
                  ],
                ),
                Text('${_secondsRemaining}s left',
                    style: TextStyle(fontSize: 13, color: AppColors.midGray)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _secondsRemaining / 38,
                backgroundColor: AppColors.lightGray,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                minHeight: 4,
              ),
            ),
          ),
          const Spacer(),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _declineOrder(order.id);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.lightGray, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Decline',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => widget.onOrderTap(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Accept Order',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEstimatedTime(AvailableOrder order) {
    final pickupDistance = double.tryParse(order.pickupDistanceKm ?? '0') ?? 0;
    final deliveryDistance =
        double.tryParse(order.deliveryDistanceKm ?? '0') ?? 0;
    final totalDistance = pickupDistance + deliveryDistance;
    final estimatedMinutes = (totalDistance * 3).round();
    return '$estimatedMinutes min';
  }

  String _getTotalDistance(AvailableOrder order) {
    final pickupDistance = double.tryParse(order.pickupDistanceKm ?? '0') ?? 0;
    final deliveryDistance =
        double.tryParse(order.deliveryDistanceKm ?? '0') ?? 0;
    final totalDistance = pickupDistance + deliveryDistance;
    return '${totalDistance.toStringAsFixed(1)} km';
  }

  Widget _buildNoOrdersMessage() {
    return Positioned(
      bottom: 32,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delivery_dining_outlined,
              size: 48,
              color: AppColors.midGray,
            ),
            const SizedBox(height: 12),
            Text(
              'No orders available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'New orders will appear here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.midGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOrders() {
    return Positioned(
      bottom: 32,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Looking for orders...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.midGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(
      OrderDetails order, DriverProvider driverProvider) {
    // Update map to show active order route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMapForActiveOrder(order);
    });

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreenBadge,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delivery_dining,
                        color: AppColors.primaryGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Active Delivery',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '#${order.orderNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.midGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.restaurant?.name ?? 'Restaurant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(order.status),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (widget.onActiveOrderTap != null) {
                      widget.onActiveOrderTap!(order.id);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateMapForActiveOrder(OrderDetails order) {
    final pickupLat = order.restaurant?.latitude;
    final pickupLng = order.restaurant?.longitude;
    final dropoffLat = order.delivery?.latitude;
    final dropoffLng = order.delivery?.longitude;

    Set<Marker> newMarkers = {};
    Set<Polyline> newPolylines = {};
    List<LatLng> routePoints = [];

    if (pickupLat != null && pickupLng != null) {
      final pickupPosition = LatLng(pickupLat, pickupLng);
      routePoints.add(pickupPosition);
      newMarkers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupPosition,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: order.restaurant?.name ?? 'Pickup',
            snippet: order.restaurant?.address,
          ),
        ),
      );
    }

    if (dropoffLat != null && dropoffLng != null) {
      final dropoffPosition = LatLng(dropoffLat, dropoffLng);
      routePoints.add(dropoffPosition);
      newMarkers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffPosition,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Drop Off',
            snippet: order.delivery?.address,
          ),
        ),
      );
    }

    if (routePoints.length == 2) {
      newPolylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: AppColors.primaryGreen,
          width: 4,
        ),
      );

      _fitMapToBounds(routePoints);
    } else if (routePoints.length == 1) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(routePoints.first, 15),
      );
    }

    setState(() {
      _markers = newMarkers;
      _polylines = newPolylines;
    });
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'assigned':
        return 'Head to pickup';
      case 'picked_up':
        return 'On the way to customer';
      case 'arriving':
        return 'Almost there';
      default:
        return 'In progress';
    }
  }

  /// Unified order cards that show both food and parcel orders in one PageView
  Widget _buildUnifiedOrderCards(
    List<AvailableOrder> foodOrders,
    List<AvailableParcelOrder> parcelOrders,
    DriverProvider driverProvider,
  ) {
    // Build a unified list of card widgets
    final visibleFoodOrders = foodOrders
        .where((o) =>
            !_declinedOrderIds.contains(o.id) &&
            !_hiddenOrderIds.contains(o.id))
        .toList();

    final totalCards = visibleFoodOrders.length + parcelOrders.length;
    if (totalCards == 0) {
      return _buildNoOrdersMessage();
    }

    // Update map markers for food orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMapMarkers(foodOrders);
    });

    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 352,
        child: PageView.builder(
          controller: _pageController,
          itemCount: totalCards,
          onPageChanged: (index) {
            setState(() {
              _currentOrderIndex = index;
              _secondsRemaining = 38;
            });
          },
          itemBuilder: (context, index) {
            if (index < visibleFoodOrders.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildFloatingOrderCard(
                    visibleFoodOrders[index], visibleFoodOrders),
              );
            } else {
              final parcelIndex = index - visibleFoodOrders.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildFloatingParcelCard(parcelOrders[parcelIndex]),
              );
            }
          },
        ),
      ),
    );
  }

  /// Floating parcel order card matching the UI design
  Widget _buildFloatingParcelCard(AvailableParcelOrder order) {
    final pickupDistance = double.tryParse(order.pickupDistanceKm ?? '0') ?? 0;
    final deliveryDistance =
        double.tryParse(order.deliveryDistanceKm ?? '0') ?? 0;
    final totalDistance = pickupDistance + deliveryDistance;
    final estimatedMinutes =
        order.estimatedDurationMin ?? (totalDistance * 3).round();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with PACKAGE DELIVERY badge and countdown
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2,
                                  color: AppColors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'PACKAGE DELIVERY',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Countdown circle
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primaryOrange, width: 3),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$_secondsRemaining',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.darkGray)),
                                Text('sec',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.midGray)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Earnings
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.estimatedEarnings,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkGray),
                        ),
                        Text('est.total earning',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.midGray)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Time, distance, traffic
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            color: AppColors.midGray, size: 14),
                        const SizedBox(width: 4),
                        Text('$estimatedMinutes min',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.darkGray)),
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: AppColors.midGray)),
                        const SizedBox(width: 8),
                        Icon(Icons.circle_outlined,
                            color: AppColors.midGray, size: 14),
                        const SizedBox(width: 4),
                        Text('${totalDistance.toStringAsFixed(1)} KM',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.darkGray)),
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: AppColors.midGray)),
                        const SizedBox(width: 8),
                        Text('Light traffic',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.darkGray)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Package info row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            color: AppColors.primaryOrange, size: 16),
                        const SizedBox(width: 8),
                        Text('Package information',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.midGray)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${order.quantity} items',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryOrange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 1, 16, 0),
                    child: Text(order.packageSize.toLowerCase(),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray)),
                  ),
                  const SizedBox(height: 4),
                  // Pickup
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle,
                            color: AppColors.primaryOrange, size: 10),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pick up',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.midGray)),
                              Text(
                                order.pickupAddress ?? 'Pickup location',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.darkGray),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dropoff
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 3, 16, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle_outlined,
                            color: AppColors.midGray, size: 10),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Drop Off',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.midGray)),
                              Text(
                                order.dropoffAddress ?? 'Dropoff location',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.darkGray),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Action buttons: Decline | Accept Order
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineOrder(order.id),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.lightGray, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Decline',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _acceptParcelOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Accept Order',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white)),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward,
                            color: AppColors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _acceptParcelOrder(AvailableParcelOrder order) async {
    final parcelProvider = context.read<ParcelDriverProvider>();
    final success = await parcelProvider.acceptOrder(order.id);
    if (success && mounted) {
      // Home page listener handles navigation to avoid duplicate route stacking.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parcel order accepted'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(parcelProvider.error ?? 'Failed to accept order'),
            backgroundColor: Colors.red),
      );
    }
  }

  /// Active parcel order card on home (when driver has an active parcel delivery)
  Widget _buildActiveParcelOrderCard(
      ActiveParcelOrder order, ParcelDriverProvider parcelProvider) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppColors.lightGreenBadge,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2,
                          color: AppColors.primaryGreen, size: 14),
                      const SizedBox(width: 6),
                      Text('Active Parcel',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(order.packageSize,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.midGray)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.pickupAddress ?? 'Pickup',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getParcelStatusText(order.status),
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ActiveParcelDeliveryScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('View Details',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getParcelStatusText(String status) {
    switch (status) {
      case 'driver_assigned':
        return 'Head to pickup';
      case 'driver_en_route_pickup':
        return 'En route to pickup';
      case 'at_pickup':
        return 'At pickup location';
      case 'picked_up':
        return 'Package picked up';
      case 'in_transit':
        return 'On the way to drop-off';
      case 'at_dropoff':
        return 'At drop-off location';
      default:
        return 'In progress';
    }
  }
}
