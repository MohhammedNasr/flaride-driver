import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/features/driver/parcels/parcel_driver_provider.dart';
import 'package:flaride_driver/features/driver/parcels/parcel_order_model.dart';
import 'package:flaride_driver/features/driver/parcels/cancel_parcel_dialog.dart';
import 'package:flaride_driver/features/driver/parcels/parcel_rating_screen.dart';

class ActiveParcelDeliveryScreen extends StatefulWidget {
  const ActiveParcelDeliveryScreen({super.key});

  @override
  State<ActiveParcelDeliveryScreen> createState() =>
      _ActiveParcelDeliveryScreenState();
}

class _ActiveParcelDeliveryScreenState
    extends State<ActiveParcelDeliveryScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoadingLocation = true;
  StreamSubscription<Position>? _locationSub;
  bool _hasNavigatedToRating = false;
  String? _lastOrderStatus;
  _CapturedProof? _capturedPickupProof;
  _CapturedProof? _capturedDropoffProof;
  bool _isUploadingPickupProof = false;
  bool _isUploadingDropoffProof = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _isLoadingLocation = false;
      });
      _updateMapForOrder();
      _startLocationTracking();
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _startLocationTracking() {
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 30),
    ).listen((pos) {
      if (!mounted) return;
      setState(() => _currentPosition = LatLng(pos.latitude, pos.longitude));
      _updateMapForOrder();
    });
  }

  void _updateMapForOrder() {
    final provider = context.read<ParcelDriverProvider>();
    final order = provider.activeOrder;
    if (order == null) return;

    final status = order.status;
    Set<Marker> markers = {};
    List<LatLng> routePoints = [];

    // Determine which locations to show based on status
    final isHeadingToPickup =
        ['driver_assigned', 'driver_en_route_pickup'].contains(status);
    final isAtPickup = status == 'at_pickup';
    final isHeadingToDropoff = ['picked_up', 'in_transit'].contains(status);
    final isAtDropoff = status == 'at_dropoff';

    if (isHeadingToPickup || isAtPickup) {
      // Show route from driver to pickup
      if (_currentPosition != null) {
        markers.add(Marker(
          markerId: const MarkerId('driver'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You'),
        ));
        routePoints.add(_currentPosition!);
      }
      if (order.pickupLat != null && order.pickupLng != null) {
        final pickupPos = LatLng(order.pickupLat!, order.pickupLng!);
        markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: pickupPos,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: 'Pickup', snippet: order.pickupAddress),
        ));
        routePoints.add(pickupPos);
      }
    } else if (isHeadingToDropoff || isAtDropoff) {
      // Show route from pickup/driver to dropoff
      if (_currentPosition != null) {
        markers.add(Marker(
          markerId: const MarkerId('driver'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You'),
        ));
        routePoints.add(_currentPosition!);
      }
      if (order.dropoffLat != null && order.dropoffLng != null) {
        final dropoffPos = LatLng(order.dropoffLat!, order.dropoffLng!);
        markers.add(Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffPos,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow:
              InfoWindow(title: 'Drop Off', snippet: order.dropoffAddress),
        ));
        routePoints.add(dropoffPos);
      }
    }

    Set<Polyline> polylines = {};
    if (routePoints.length == 2) {
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: AppColors.primaryOrange,
        width: 4,
      ));
      _fitMapToBounds(routePoints);
    } else if (routePoints.length == 1) {
      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(routePoints.first, 15));
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  void _fitMapToBounds(List<LatLng> points) {
    if (points.length < 2 || _mapController == null) return;
    double minLat =
        points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat =
        points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng =
        points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng =
        points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
          southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
      80,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ParcelDriverProvider>(
      builder: (context, provider, _) {
        final order = provider.activeOrder;
        if (order == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                      color: AppColors.primaryOrange),
                  const SizedBox(height: 16),
                  Text('Loading delivery...',
                      style: TextStyle(color: AppColors.midGray)),
                ],
              ),
            ),
          );
        }

        if (_lastOrderStatus != order.status) {
          _lastOrderStatus = order.status;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _updateMapForOrder();
          });
        }

        return Scaffold(
          body: Stack(
            children: [
              // Map
              _buildMap(),
              // Top bar with back button and status info
              _buildTopBar(order),
              // Bottom panel
              _buildBottomPanel(order, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap() {
    if (_isLoadingLocation) {
      return Container(
        color: AppColors.lightGray,
        child: const Center(
            child: CircularProgressIndicator(color: AppColors.primaryOrange)),
      );
    }
    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        _updateMapForOrder();
      },
      initialCameraPosition: CameraPosition(
        target: _currentPosition ?? const LatLng(5.3600, -4.0083),
        zoom: 14.0,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildTopBar(ActiveParcelOrder order) {
    final isHeadingToPickup =
        ['driver_assigned', 'driver_en_route_pickup'].contains(order.status);
    final isHeadingToDropoff =
        ['picked_up', 'in_transit'].contains(order.status);

    String topLabel = '';
    if (isHeadingToPickup) {
      topLabel = 'Pick up in ${order.estimatedDurationMin ?? 5} min';
    } else if (order.status == 'at_pickup') {
      topLabel = 'At pickup location';
    } else if (isHeadingToDropoff) {
      topLabel = '${order.distanceKm?.toStringAsFixed(1) ?? '?'} KM';
    } else if (order.status == 'at_dropoff') {
      topLabel = 'At drop-off location';
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1), blurRadius: 8)
                    ],
                  ),
                  child: const Icon(Icons.arrow_back,
                      size: 20, color: AppColors.darkGray),
                ),
              ),
              const SizedBox(width: 12),
              if (topLabel.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1), blurRadius: 8)
                    ],
                  ),
                  child: Text(topLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(
      ActiveParcelOrder order, ParcelDriverProvider provider) {
    final status = order.status;

    // Different bottom panels based on status
    if (status == 'driver_assigned' || status == 'driver_en_route_pickup') {
      return _buildEnRouteToPickupPanel(order, provider);
    } else if (status == 'at_pickup') {
      return _buildAtPickupPanel(order, provider);
    } else if (status == 'picked_up') {
      return _buildPickedUpPanel(order, provider);
    } else if (status == 'in_transit') {
      return _buildInTransitPanel(order, provider);
    } else if (status == 'at_dropoff') {
      return _buildAtDropoffPanel(order, provider);
    } else if (status == 'delivered') {
      if (!_hasNavigatedToRating) {
        _hasNavigatedToRating = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ParcelRatingScreen(order: order)),
          );
        });
      }
      return const SizedBox.shrink();
    }

    return const SizedBox.shrink();
  }

  /// Panel: En route to pickup — shows customer info, pickup address, Arrived + Cancel buttons
  Widget _buildEnRouteToPickupPanel(
      ActiveParcelOrder order, ParcelDriverProvider provider) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: _panelDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dragHandle(),
            const SizedBox(height: 16),
            // Customer info row
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.lightGray,
                  backgroundImage: order.customer?.profilePicture != null
                      ? NetworkImage(order.customer!.profilePicture!)
                      : null,
                  child: order.customer?.profilePicture == null
                      ? Icon(Icons.person, color: AppColors.midGray)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.pickupContactName ??
                            order.customer?.name ??
                            'Customer',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray),
                      ),
                      Text(
                        '${order.distanceKm?.toStringAsFixed(1) ?? '?'} km away',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.midGray),
                      ),
                    ],
                  ),
                ),
                // Chat and call buttons
                _iconButton(
                    Icons.chat_bubble_outline, AppColors.primaryOrange, () {}),
                const SizedBox(width: 8),
                _iconButton(Icons.phone, AppColors.primaryOrange,
                    () => _callContact(order.pickupContactPhone)),
              ],
            ),
            const SizedBox(height: 16),
            // Pickup address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on,
                      color: AppColors.primaryOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pickup at',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGray)),
                      Text(
                        order.pickupAddress ?? 'Pickup location',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.midGray),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Start Trip or Arrived button based on status
            if (order.status == 'driver_assigned')
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () => _updateStatus(provider, 'driver_en_route_pickup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Start Trip',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () => _updateStatus(provider, 'at_pickup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Arrived',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              ),
            const SizedBox(height: 10),
            // Cancel trip
            TextButton(
              onPressed: () => _showCancelDialog(provider),
              child: Text('Cancel trip',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryOrange)),
            ),
          ],
        ),
      ),
    );
  }

  /// Panel: At pickup — confirm package picked up
  Widget _buildAtPickupPanel(
      ActiveParcelOrder order, ParcelDriverProvider provider) {
    final requiresPickupProof = order.securityRequirements.requirePickupPhoto;
    final effectivePickupProofUrl =
        _capturedPickupProof?.url ?? order.pickupProofPhoto;
    final hasPickupProof =
        effectivePickupProofUrl != null && effectivePickupProofUrl.isNotEmpty;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: _panelDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dragHandle(),
            const SizedBox(height: 16),
            Icon(Icons.inventory_2, color: AppColors.primaryOrange, size: 40),
            const SizedBox(height: 8),
            Text('Collect the package',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray)),
            const SizedBox(height: 4),
            Text(
              'Verify the package details and collect from the sender',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.midGray),
            ),
            const SizedBox(height: 12),
            // Package info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      color: AppColors.primaryOrange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.packageSize,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkGray)),
                        Text('${order.quantity} item(s)',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.midGray)),
                      ],
                    ),
                  ),
                  if (order.isFragile)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('Fragile',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildProofCard(
              title: 'Pickup proof photo',
              isRequired: requiresPickupProof,
              instructions: order.securityRequirements.pickupPhotoInstructions,
              isUploaded: hasPickupProof,
              previewUrl: effectivePickupProofUrl,
              isUploading: _isUploadingPickupProof || provider.isUploadingProof,
              onCapture: () => _captureAndUploadProof(provider, isPickup: true),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: provider.isLoading ||
                        (requiresPickupProof && !hasPickupProof)
                    ? null
                    : () => _updateStatus(provider, 'picked_up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Package Collected',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ),
            if (requiresPickupProof && !hasPickupProof) ...[
              const SizedBox(height: 8),
              Text(
                'Pickup photo is required before confirming collection.',
                style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _showCancelDialog(provider),
              child: Text('Cancel trip',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryOrange)),
            ),
          ],
        ),
      ),
    );
  }

  /// Panel: Picked up — heading to dropoff with slide to start
  Widget _buildPickedUpPanel(
      ActiveParcelOrder order, ParcelDriverProvider provider) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: _panelDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dragHandle(),
            const SizedBox(height: 12),
            Text(
              'Picking up ${order.dropoffContactName ?? order.customer?.name ?? 'Customer'}',
              style: TextStyle(fontSize: 12, color: AppColors.midGray),
            ),
            const SizedBox(height: 4),
            Text(
              'Heading to ${order.dropoffAddress ?? 'Drop-off'}',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkGray),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              order.dropoffAddress ?? '',
              style: TextStyle(fontSize: 13, color: AppColors.midGray),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // ETA / Distance / Arrival
            Row(
              children: [
                _infoColumn(
                    '${order.estimatedDurationMin ?? '?'}', 'min', 'ETA'),
                _divider(),
                _infoColumn('${order.distanceKm?.toStringAsFixed(1) ?? '?'}',
                    'km', 'Distance'),
                _divider(),
                _infoColumn(
                    _formatTime(DateTime.now().add(
                        Duration(minutes: order.estimatedDurationMin ?? 10))),
                    '',
                    'Arrival'),
              ],
            ),
            const SizedBox(height: 20),
            // Slide to start
            _buildSlideToStart(provider, 'in_transit', 'Slide to Start trip'),
          ],
        ),
      ),
    );
  }

  /// Panel: In transit — heading to dropoff
  Widget _buildInTransitPanel(
      ActiveParcelOrder order, ParcelDriverProvider provider) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: _panelDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dragHandle(),
            const SizedBox(height: 12),
            Text(
              'Delivering to ${order.dropoffContactName ?? 'Customer'}',
              style: TextStyle(fontSize: 12, color: AppColors.midGray),
            ),
            const SizedBox(height: 4),
            Text(
              order.dropoffAddress ?? 'Drop-off',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkGray),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _infoColumn(
                    '${order.estimatedDurationMin ?? '?'}', 'min', 'ETA'),
                _divider(),
                _infoColumn('${order.distanceKm?.toStringAsFixed(1) ?? '?'}',
                    'km', 'Distance'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () => _updateStatus(provider, 'at_dropoff'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Arrived at Drop-off',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Panel: At dropoff — confirm delivery
  Widget _buildAtDropoffPanel(
      ActiveParcelOrder order, ParcelDriverProvider provider) {
    final requiresDropoffProof = order.securityRequirements.requireDropoffPhoto;
    final effectiveDropoffProofUrl =
        _capturedDropoffProof?.url ?? order.dropoffProofPhoto;
    final hasDropoffProof =
        effectiveDropoffProofUrl != null && effectiveDropoffProofUrl.isNotEmpty;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: _panelDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dragHandle(),
            const SizedBox(height: 16),
            Icon(Icons.location_on, color: AppColors.primaryGreen, size: 40),
            const SizedBox(height: 8),
            Text('You have arrived',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray)),
            const SizedBox(height: 4),
            Text(
              'Hand over the package to the recipient',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.midGray),
            ),
            const SizedBox(height: 12),
            // Recipient info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.dropoffContactName ?? 'Recipient',
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        if (order.dropoffContactPhone != null)
                          Text(order.dropoffContactPhone!,
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.midGray)),
                      ],
                    ),
                  ),
                  if (order.dropoffContactPhone != null)
                    _iconButton(Icons.phone, AppColors.primaryGreen,
                        () => _callContact(order.dropoffContactPhone)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildProofCard(
              title: 'Drop-off proof photo',
              isRequired: requiresDropoffProof,
              instructions: order.securityRequirements.dropoffPhotoInstructions,
              isUploaded: hasDropoffProof,
              previewUrl: effectiveDropoffProofUrl,
              isUploading:
                  _isUploadingDropoffProof || provider.isUploadingProof,
              onCapture: () =>
                  _captureAndUploadProof(provider, isPickup: false),
            ),
            const SizedBox(height: 14),
            if (requiresDropoffProof && !hasDropoffProof)
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.lightGray.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Text(
                    'Drop-off photo required before completion',
                    style: TextStyle(fontSize: 13, color: AppColors.midGray),
                  ),
                ),
              )
            else
              _buildSlideToStart(
                  provider, 'delivered', 'Slide to Complete Delivery'),
          ],
        ),
      ),
    );
  }

  // ── Helper widgets ──

  Widget _buildSlideToStart(
      ParcelDriverProvider provider, String nextStatus, String label) {
    return _SlideToAction(
      key: ValueKey(nextStatus),
      label: label,
      isLoading: provider.isLoading,
      onSlideComplete: () => _updateStatus(provider, nextStatus),
    );
  }

  Widget _buildProofCard({
    required String title,
    required bool isRequired,
    required String instructions,
    required bool isUploaded,
    required String? previewUrl,
    required bool isUploading,
    required VoidCallback onCapture,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded ? AppColors.primaryGreen : AppColors.lightGray,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUploaded ? Icons.check_circle : Icons.camera_alt_outlined,
                size: 18,
                color: isUploaded ? AppColors.primaryGreen : AppColors.darkGray,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
              ),
              if (isRequired)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            instructions,
            style: const TextStyle(fontSize: 12, color: AppColors.midGray),
          ),
          if (previewUrl != null && previewUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                previewUrl,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 110,
                    color: AppColors.lightGray,
                    alignment: Alignment.center,
                    child: const Text(
                      'Photo uploaded',
                      style: TextStyle(color: AppColors.midGray, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isUploading ? null : onCapture,
              icon: isUploading
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isUploaded ? Icons.refresh : Icons.camera_alt,
                      size: 16,
                    ),
              label: Text(isUploaded ? 'Retake Photo' : 'Take Photo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _infoColumn(String value, String unit, String label) {
    return Expanded(
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: value,
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGray)),
                if (unit.isNotEmpty)
                  TextSpan(
                      text: ' $unit',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: AppColors.midGray)),
              ],
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.midGray)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: AppColors.lightGray);
  }

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: AppColors.lightGray, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2))
      ],
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour;
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _updateStatus(
      ParcelDriverProvider provider, String newStatus) async {
    if (provider.isLoading) return;
    final activeOrder = provider.activeOrder;
    final currentStatus = activeOrder?.status;
    if (currentStatus == null || currentStatus == newStatus) return;

    final requiresPickupProof =
        activeOrder?.securityRequirements.requirePickupPhoto ?? true;
    final requiresDropoffProof =
        activeOrder?.securityRequirements.requireDropoffPhoto ?? true;
    final hasPickupProof = (_capturedPickupProof?.url.isNotEmpty == true) ||
        (activeOrder?.hasPickupProof == true);
    final hasDropoffProof = (_capturedDropoffProof?.url.isNotEmpty == true) ||
        (activeOrder?.hasDropoffProof == true);

    if (['picked_up', 'in_transit', 'at_dropoff', 'delivered']
            .contains(newStatus) &&
        requiresPickupProof &&
        !hasPickupProof) {
      _showError('Pickup proof photo is required before this step.');
      return;
    }

    if (newStatus == 'delivered' && requiresDropoffProof && !hasDropoffProof) {
      _showError(
          'Drop-off proof photo is required before completing delivery.');
      return;
    }

    final success = await provider.updateStatus(
      newStatus,
      driverLat: _currentPosition?.latitude,
      driverLng: _currentPosition?.longitude,
      pickupProofPhoto: _capturedPickupProof?.url,
      pickupProofMimeType: _capturedPickupProof?.mimeType,
      pickupProofSizeBytes: _capturedPickupProof?.sizeBytes,
      pickupProofTakenAt: _capturedPickupProof?.takenAt.toIso8601String(),
      pickupProofTakenLat: _capturedPickupProof?.lat,
      pickupProofTakenLng: _capturedPickupProof?.lng,
      dropoffProofPhoto: _capturedDropoffProof?.url,
      dropoffProofMimeType: _capturedDropoffProof?.mimeType,
      dropoffProofSizeBytes: _capturedDropoffProof?.sizeBytes,
      dropoffProofTakenAt: _capturedDropoffProof?.takenAt.toIso8601String(),
      dropoffProofTakenLat: _capturedDropoffProof?.lat,
      dropoffProofTakenLng: _capturedDropoffProof?.lng,
    );
    if (!success && mounted) {
      _showError(provider.error ?? 'Failed to update status');
    }
  }

  Future<void> _captureAndUploadProof(ParcelDriverProvider provider,
      {required bool isPickup}) async {
    if (provider.activeOrder == null) return;
    final isUploading =
        isPickup ? _isUploadingPickupProof : _isUploadingDropoffProof;
    if (isUploading || provider.isUploadingProof) return;

    final xFile = await _pickProofPhotoFromCamera();

    if (xFile == null) return;

    final file = File(xFile.path);
    if (isPickup) {
      setState(() => _isUploadingPickupProof = true);
    } else {
      setState(() => _isUploadingDropoffProof = true);
    }

    final upload = await provider.uploadProofPhoto(
      file: file,
      proofType: isPickup ? 'pickup' : 'dropoff',
    );

    if (isPickup) {
      setState(() => _isUploadingPickupProof = false);
    } else {
      setState(() => _isUploadingDropoffProof = false);
    }

    if (!upload.success || upload.url == null || upload.url!.isEmpty) {
      _showError(upload.message ?? 'Failed to upload photo');
      return;
    }

    final takenAt = DateTime.now();
    final proof = _CapturedProof(
      url: upload.url!,
      mimeType: upload.mimeType ?? _guessMimeTypeFromPath(xFile.path),
      sizeBytes: upload.sizeBytes,
      takenAt: takenAt,
      lat: _currentPosition?.latitude,
      lng: _currentPosition?.longitude,
    );

    setState(() {
      if (isPickup) {
        _capturedPickupProof = proof;
      } else {
        _capturedDropoffProof = proof;
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isPickup
            ? 'Pickup proof photo uploaded.'
            : 'Drop-off proof photo uploaded.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<XFile?> _pickProofPhotoFromCamera() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
        maxWidth: 2000,
        maxHeight: 2000,
      );
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('permission') ||
          code.contains('denied') ||
          code.contains('camera_access')) {
        _showError(
            'Camera permission is required. Please allow camera access in Settings.');
      } else {
        _showError('Unable to open camera. Please try again.');
      }
      return null;
    } catch (_) {
      _showError('Unable to open camera. Please try again.');
      return null;
    }
  }

  String _guessMimeTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showCancelDialog(ParcelDriverProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CancelParcelDialog(
        onCancel: (reason) async {
          Navigator.pop(ctx);
          final success = await provider.cancelDelivery(reason: reason);
          if (success && mounted) {
            Navigator.pop(context); // Go back to home
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(provider.error ?? 'Failed to cancel'),
                  backgroundColor: Colors.red),
            );
          }
        },
        onKeep: () => Navigator.pop(ctx),
      ),
    );
  }

  void _callContact(String? phone) async {
    if (phone == null) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _CapturedProof {
  final String url;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime takenAt;
  final double? lat;
  final double? lng;

  _CapturedProof({
    required this.url,
    required this.takenAt,
    this.mimeType,
    this.sizeBytes,
    this.lat,
    this.lng,
  });
}

/// Slide-to-action widget matching driver 3.png design
class _SlideToAction extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onSlideComplete;

  const _SlideToAction({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onSlideComplete,
  });

  @override
  State<_SlideToAction> createState() => _SlideToActionState();
}

class _SlideToActionState extends State<_SlideToAction> {
  double _dragPosition = 0;
  double _maxDrag = 0;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxDrag = constraints.maxWidth - 60;
        final progress =
            _maxDrag > 0 ? (_dragPosition / _maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.lightGray.withOpacity(0.5),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            children: [
              // Progress fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: _dragPosition + 60,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              // Label
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: Opacity(
                    opacity: (1 - progress * 2).clamp(0.0, 1.0),
                    child: Text(
                      widget.label,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.midGray),
                    ),
                  ),
                ),
              ),
              // Draggable thumb
              Positioned(
                left: _dragPosition,
                top: 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: widget.isLoading || _completed
                      ? null
                      : (details) {
                          setState(() {
                            _dragPosition = (_dragPosition + details.delta.dx)
                                .clamp(0.0, _maxDrag);
                          });
                        },
                  onHorizontalDragEnd: widget.isLoading || _completed
                      ? null
                      : (details) {
                          if (_dragPosition >= _maxDrag * 0.85) {
                            setState(() {
                              _completed = true;
                              _dragPosition = _maxDrag;
                            });
                            widget.onSlideComplete();
                          } else {
                            setState(() => _dragPosition = 0);
                          }
                        },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primaryOrange.withOpacity(0.3),
                            blurRadius: 8)
                      ],
                    ),
                    child: widget.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right,
                            color: Colors.white, size: 28),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
