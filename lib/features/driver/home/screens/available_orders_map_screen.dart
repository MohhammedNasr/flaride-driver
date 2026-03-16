import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/shared/widgets/google_map_widget.dart';
import 'package:flaride_driver/features/driver/home/widgets/available_orders_bottom_sheet.dart';
import 'package:flaride_driver/features/driver/home/widgets/map_online_status_toggle.dart';

class AvailableOrdersMapScreen extends StatefulWidget {
  final List<AvailableOrder> orders;
  final bool isOnline;
  final Function(AvailableOrder) onOrderTap;
  final VoidCallback onToggleOnline;

  const AvailableOrdersMapScreen({
    super.key,
    required this.orders,
    required this.isOnline,
    required this.onOrderTap,
    required this.onToggleOnline,
  });

  @override
  State<AvailableOrdersMapScreen> createState() => _AvailableOrdersMapScreenState();
}

class _AvailableOrdersMapScreenState extends State<AvailableOrdersMapScreen> {
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  // Store order positions for consistent marker placement
  final Map<String, LatLng> _orderPositions = {};

  @override
  void initState() {
    super.initState();
    _initializePositions();
    _createMarkers();
  }

  void _initializePositions() {
    // Use actual restaurant coordinates if available, otherwise use offset positions
    for (int i = 0; i < widget.orders.length; i++) {
      final order = widget.orders[i];
      final lat = order.restaurant?.latitude;
      final lng = order.restaurant?.longitude;
      
      if (lat != null && lng != null) {
        // Use real restaurant coordinates
        _orderPositions[order.id] = LatLng(lat, lng);
      } else {
        // Fallback to offset positions if coordinates not available
        _orderPositions[order.id] = LatLng(30.0444 + (i * 0.01), 31.2357 + (i * 0.01));
      }
    }
  }

  void _createMarkers({String? highlightOrderId}) {
    final markers = <Marker>{};
    
    for (final order in widget.orders) {
      final isHighlighted = order.id == highlightOrderId;
      final position = _orderPositions[order.id] ?? const LatLng(30.0444, 31.2357);
      
      markers.add(
        Marker(
          markerId: MarkerId(order.id),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isHighlighted ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: order.restaurant?.name ?? 'Restaurant',
            snippet: order.estimatedEarnings,
          ),
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }

  void _onOrderCardTap(AvailableOrder order) {
    // Update markers to highlight selected order
    _createMarkers(highlightOrderId: order.id);
    
    // Get order location
    final position = _orderPositions[order.id] ?? const LatLng(30.0444, 31.2357);
    
    // Animate map to the pickup location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, 15.0),
    );
    
    // Show the marker info window
    _mapController?.showMarkerInfoWindow(MarkerId(order.id));
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _handleToggleOnline() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.toggleOnlineStatus();
    
    // If going offline, pop back to home
    if (!driverProvider.isOnline && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, driverProvider, child) {
        return Scaffold(
          body: Stack(
            children: [
              GoogleMapWidget(
                markers: _markers,
                initialZoom: 13.0,
                showMyLocationButton: false,
                onMapCreated: _onMapCreated,
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.darkGray,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: MapOnlineStatusToggle(
                    isOnline: driverProvider.isOnline,
                    onToggle: _handleToggleOnline,
                  ),
                ),
              ),
              AvailableOrdersBottomSheet(
                orders: widget.orders,
                onOrderTap: widget.onOrderTap,
                onCardTap: _onOrderCardTap,
              ),
            ],
          ),
        );
      },
    );
  }
}
