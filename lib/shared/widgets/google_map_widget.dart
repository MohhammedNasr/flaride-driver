import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class GoogleMapWidget extends StatefulWidget {
  final LatLng? initialPosition;
  final double? initialZoom;
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final bool showMyLocation;
  final bool showMyLocationButton;
  final bool showZoomControls;
  final bool showCompass;
  final bool showMapToolbar;
  final MapType mapType;
  final Function(GoogleMapController)? onMapCreated;
  final Function(LatLng)? onTap;
  final Function(CameraPosition)? onCameraMove;
  final VoidCallback? onCameraIdle;
  final String? mapStyle;
  final MinMaxZoomPreference? zoomPreference;
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool trafficEnabled;
  final bool buildingsEnabled;

  const GoogleMapWidget({
    super.key,
    this.initialPosition,
    this.initialZoom = 15.0,
    this.markers,
    this.polylines,
    this.showMyLocation = true,
    this.showMyLocationButton = true,
    this.showZoomControls = false,
    this.showCompass = false,
    this.showMapToolbar = false,
    this.mapType = MapType.normal,
    this.onMapCreated,
    this.onTap,
    this.onCameraMove,
    this.onCameraIdle,
    this.mapStyle,
    this.zoomPreference,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.rotateGesturesEnabled = false,
    this.tiltGesturesEnabled = false,
    this.trafficEnabled = false,
    this.buildingsEnabled = false,
  });

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isLoading = true;

  // Default position (Cairo, Egypt - since that's where restaurants are)
  static const LatLng _defaultPosition = LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Apply custom map style if provided
    if (widget.mapStyle != null) {
      controller.setMapStyle(widget.mapStyle);
    }
    
    // Call the provided callback
    widget.onMapCreated?.call(controller);
  }

  LatLng get _initialPosition {
    return widget.initialPosition ?? 
           _currentPosition ?? 
           _defaultPosition;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
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
                'Loading map...',
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

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _initialPosition,
        zoom: widget.initialZoom ?? 15.0,
      ),
      markers: widget.markers ?? {},
      polylines: widget.polylines ?? {},
      myLocationEnabled: widget.showMyLocation,
      myLocationButtonEnabled: widget.showMyLocationButton,
      zoomControlsEnabled: widget.showZoomControls,
      compassEnabled: widget.showCompass,
      mapToolbarEnabled: widget.showMapToolbar,
      mapType: widget.mapType,
      onTap: widget.onTap,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
      minMaxZoomPreference: widget.zoomPreference ?? const MinMaxZoomPreference(5, 20),
      scrollGesturesEnabled: widget.scrollGesturesEnabled,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      rotateGesturesEnabled: widget.rotateGesturesEnabled,
      tiltGesturesEnabled: widget.tiltGesturesEnabled,
      trafficEnabled: widget.trafficEnabled,
      buildingsEnabled: widget.buildingsEnabled,
    );
  }

  // Public methods for external control
  void moveCamera(LatLng position, {double? zoom}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: zoom ?? 15.0,
        ),
      ),
    );
  }

  void fitBounds(LatLng southwest, LatLng northeast, {double padding = 50}) {
    final bounds = LatLngBounds(
      southwest: southwest,
      northeast: northeast,
    );
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  void fitMarkers(List<LatLng> positions, {double padding = 50}) {
    if (positions.isEmpty) return;
    
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (LatLng position in positions) {
      minLat = minLat < position.latitude ? minLat : position.latitude;
      maxLat = maxLat > position.latitude ? maxLat : position.latitude;
      minLng = minLng < position.longitude ? minLng : position.longitude;
      maxLng = maxLng > position.longitude ? maxLng : position.longitude;
    }

    fitBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
      padding: padding,
    );
  }

  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
