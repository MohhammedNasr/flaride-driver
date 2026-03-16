import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/shared/widgets/google_map_widget.dart';
import 'package:flaride_driver/core/services/directions_service.dart';

class RideRouteMapWidget extends StatefulWidget {
  final String? departureCoordinates; // Format: "lat,lng"
  final String? destinationCoordinates; // Format: "lat,lng"
  final List<LatLng>? routePoints;
  final bool showRoute;
  final Color? routeColor;
  final double routeWidth;
  final bool showMarkers;
  final String? departureTitle;
  final String? destinationTitle;
  final Function(LatLng)? onMapTap;
  final double? height;
  final bool showMyLocation;
  final bool showControls;

  const RideRouteMapWidget({
    super.key,
    this.departureCoordinates,
    this.destinationCoordinates,
    this.routePoints,
    this.showRoute = true,
    this.routeColor,
    this.routeWidth = 5.0,
    this.showMarkers = true,
    this.departureTitle = 'Pickup',
    this.destinationTitle = 'Drop-off',
    this.onMapTap,
    this.height = 300,
    this.showMyLocation = true,
    this.showControls = false,
  });

  @override
  State<RideRouteMapWidget> createState() => _RideRouteMapWidgetState();
}

class _RideRouteMapWidgetState extends State<RideRouteMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  DirectionsResult? _directionsResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupMap();
  }

  void _setupMap() async {
    if (widget.departureCoordinates == null || widget.destinationCoordinates == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Parse coordinates
    final departure = _parseCoordinates(widget.departureCoordinates!);
    final destination = _parseCoordinates(widget.destinationCoordinates!);

    if (departure == null || destination == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _createMarkers(departure, destination);
    
    // Get real driving directions
    await _getDirections(departure, destination);
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    try {
      final directions = await DirectionsService.getDirections(
        origin: origin,
        destination: destination,
        travelMode: TravelMode.driving,
        avoidHighways: false,
        avoidTolls: false,
      );

      if (directions != null && directions.isOk) {
        setState(() {
          _directionsResult = directions;
          _errorMessage = null;
        });
        _createRoutePolylines(directions);
      } else {
        setState(() {
          _errorMessage = 'Could not get directions. Showing direct route.';
        });
        _createDirectPolyline(origin, destination);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting directions: $e';
      });
      _createDirectPolyline(origin, destination);
    }
  }

  void _createMarkers(LatLng departure, LatLng destination) {
    if (!widget.showMarkers) return;

    _markers = {
      Marker(
        markerId: const MarkerId('departure'),
        position: departure,
        infoWindow: InfoWindow(title: widget.departureTitle ?? 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        infoWindow: InfoWindow(title: widget.destinationTitle ?? 'Drop-off'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  void _createRoutePolylines(DirectionsResult directions) {
    if (!widget.showRoute) return;

    final route = directions.firstRoute;
    if (route == null) return;

    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        color: widget.routeColor ?? AppColors.primaryOrange,
        width: widget.routeWidth.toInt(),
        points: route.overviewPolyline.decodedPoints,
        patterns: [],
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  void _createDirectPolyline(LatLng departure, LatLng destination) {
    if (!widget.showRoute) return;

    List<LatLng> points = [departure, destination];
    
    // Use custom route points if provided
    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      points = [departure, ...widget.routePoints!, destination];
    }

    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        color: (widget.routeColor ?? AppColors.primaryOrange).withValues(alpha: 0.6),
        width: widget.routeWidth.toInt(),
        points: points,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  LatLng? _parseCoordinates(String coordinates) {
    try {
      final parts = coordinates.split(',');
      if (parts.length != 2) return null;

      final lat = double.parse(parts[0].trim());
      final lng = double.parse(parts[1].trim());

      // Validate ranges
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        return null;
      }

      return LatLng(lat, lng);
    } catch (e) {
      return null;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Fit the map to show both markers
    if (widget.departureCoordinates != null && widget.destinationCoordinates != null) {
      final departure = _parseCoordinates(widget.departureCoordinates!);
      final destination = _parseCoordinates(widget.destinationCoordinates!);
      
      if (departure != null && destination != null) {
        _fitBounds(departure, destination);
      }
    }
  }

  void _fitBounds(LatLng point1, LatLng point2) {
    final bounds = LatLngBounds(
      southwest: LatLng(
        point1.latitude < point2.latitude ? point1.latitude : point2.latitude,
        point1.longitude < point2.longitude ? point1.longitude : point2.longitude,
      ),
      northeast: LatLng(
        point1.latitude > point2.latitude ? point1.latitude : point2.latitude,
        point1.longitude > point2.longitude ? point1.longitude : point2.longitude,
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        color: AppColors.lightGray,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primaryOrange,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading route...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.midGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      child: Column(
        children: [
          // Route Information
          if (_directionsResult != null && _directionsResult!.isOk)
            _buildRouteInfo(),
          
          // Error Message
          if (_errorMessage != null)
            _buildErrorMessage(),
          
          // Map
          Expanded(
            child: GoogleMapWidget(
              markers: _markers,
              polylines: _polylines,
              showMyLocation: widget.showMyLocation,
              showMyLocationButton: widget.showControls,
              showZoomControls: widget.showControls,
              showCompass: widget.showControls,
              onMapCreated: _onMapCreated,
              onTap: widget.onMapTap,
              mapType: MapType.normal,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              trafficEnabled: false,
              buildingsEnabled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo() {
    final route = _directionsResult!.firstRoute;
    if (route == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.white,
      child: Row(
        children: [
          Icon(
            Icons.directions_car,
            color: AppColors.primaryOrange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route Information',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Distance: ${route.totalDistance.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.midGray,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Duration: ${_formatDuration(route.totalDuration)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.midGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.primaryOrange.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: AppColors.primaryOrange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  // Public methods for external control
  void updateRoute(String departureCoords, String destinationCoords) {
    setState(() {
      _isLoading = true;
    });
    
    // Update coordinates and rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupMap();
    });
  }

  void addCustomMarker(LatLng position, String title, {BitmapDescriptor? icon}) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('custom_${_markers.length}'),
          position: position,
          infoWindow: InfoWindow(title: title),
          icon: icon ?? BitmapDescriptor.defaultMarker,
        ),
      );
    });
  }

  void clearMarkers() {
    setState(() {
      _markers.clear();
    });
  }

  void clearPolylines() {
    setState(() {
      _polylines.clear();
    });
  }
}
