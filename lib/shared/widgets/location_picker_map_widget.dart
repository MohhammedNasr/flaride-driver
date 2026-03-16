import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/shared/widgets/google_map_widget.dart';
import 'package:flaride_driver/core/services/places_service.dart';

class LocationPickerMapWidget extends StatefulWidget {
  final LatLng? initialPosition;
  final Function(LatLng)? onLocationSelected;
  final Function(LatLng)? onLocationChanged;
  final String? searchHint;
  final bool showSearchBar;
  final bool showCurrentLocationButton;
  final double? height;
  final String? confirmButtonText;
  final String? cancelButtonText;

  const LocationPickerMapWidget({
    super.key,
    this.initialPosition,
    this.onLocationSelected,
    this.onLocationChanged,
    this.searchHint = 'Search for a location',
    this.showSearchBar = true,
    this.showCurrentLocationButton = true,
    this.height = 400,
    this.confirmButtonText = 'Select Location',
    this.cancelButtonText = 'Cancel',
  });

  @override
  State<LocationPickerMapWidget> createState() => _LocationPickerMapWidgetState();
}

class _LocationPickerMapWidgetState extends State<LocationPickerMapWidget> {
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  LatLng? _currentPosition;
  LatLng? _centerPosition; // Track the center of the map (crosshair position)
  Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  List<PlaceSearchResult> _searchResults = [];
  bool _isSearching = false;
  String? _selectedAddress;
  double? _distanceFromCurrent;
  bool _isUpdatingFromCamera = false; // Prevent recursive updates

  // Default position (Cairo, Egypt)
  static const LatLng _defaultPosition = LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        if (_selectedPosition == null) {
          _selectedPosition = _currentPosition;
        }
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMarkers();
    // Initialize center position with initial position
    if (_selectedPosition != null) {
      _centerPosition = _selectedPosition;
    }
    // Get initial camera position
    controller.getVisibleRegion().then((region) {
      if (mounted && _centerPosition == null) {
        final center = LatLng(
          (region.northeast.latitude + region.southwest.latitude) / 2,
          (region.northeast.longitude + region.southwest.longitude) / 2,
        );
        setState(() {
          _centerPosition = center;
          if (_selectedPosition == null) {
            _selectedPosition = center;
            _updateMarkers();
          }
        });
      }
    });
  }
  
  void _onCameraMove(CameraPosition position) {
    // Update center position when camera moves
    if (!_isUpdatingFromCamera) {
      setState(() {
        _centerPosition = position.target;
        // Update selected position to center when user is panning
        _selectedPosition = position.target;
      });
      _updateMarkers();
      // Update address for the center position
      _updateAddressForPosition(position.target);
    }
  }
  
  void _onCameraIdle() {
    // When camera stops moving, finalize the selection
    if (_mapController != null && _centerPosition != null) {
      _updateAddressForPosition(_centerPosition!);
      widget.onLocationChanged?.call(_centerPosition!);
    }
  }
  
  Future<void> _updateAddressForPosition(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;
        final address = _formatAddress(placemark);
        setState(() {
          _selectedAddress = address;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _onMapTap(LatLng position) async {
    _isUpdatingFromCamera = true;
    setState(() {
      _selectedPosition = position;
      _centerPosition = position;
      _updateMarkers();
    });

    // Calculate distance from current position
    if (_currentPosition != null) {
      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      setState(() {
        _distanceFromCurrent = distance;
      });
    }

    // Get address for the selected position
    await _updateAddressForPosition(position);
    
    // Move camera to tapped position
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(position),
    );

    widget.onLocationChanged?.call(position);
    _isUpdatingFromCamera = false;
  }

  void _updateMarkers() {
    if (_selectedPosition != null) {
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: _selectedPosition!,
          infoWindow: const InfoWindow(title: 'Selected Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    }
  }

  void _moveToCurrentLocation() async {
    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 15.0,
          ),
        ),
      );
      
      setState(() {
        _selectedPosition = _currentPosition;
        _updateMarkers();
      });
      
      widget.onLocationChanged?.call(_currentPosition!);
    }
  }

  void _confirmSelection() async {
    // Use center position if available, otherwise use selected position
    LatLng? positionToConfirm = _centerPosition ?? _selectedPosition;
    
    if (positionToConfirm != null) {
      // Ensure we have the latest address
      if (_selectedAddress == null) {
        await _updateAddressForPosition(positionToConfirm);
      }
      
      // Update selected position to center
      setState(() {
        _selectedPosition = positionToConfirm;
      });
      
      debugPrint('Confirming location selection: ${positionToConfirm.latitude}, ${positionToConfirm.longitude}');
      widget.onLocationSelected?.call(positionToConfirm);
    } else {
      debugPrint('Warning: No position available to confirm');
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  String _formatAddress(Placemark placemark) {
    final parts = <String>[];
    
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }
    
    return parts.join(', ');
  }

  Widget _buildSelectedLocationInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.midGray.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primaryOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selected Location',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (_selectedAddress != null) ...[
            Text(
              _selectedAddress!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.midGray,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          
          if (_distanceFromCurrent != null) ...[
            Row(
              children: [
                Icon(
                  Icons.straighten,
                  color: AppColors.primaryGreen,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Distance: ${_distanceFromCurrent!.toStringAsFixed(1)} km',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await PlacesService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(PlaceSearchResult result) async {
    LatLng? selectedPosition;
    
    // If we don't have coordinates, get them from place details
    if (result.latitude == 0.0 && result.longitude == 0.0) {
      final details = await PlacesService.getPlaceDetails(result.placeId);
      if (details != null) {
        selectedPosition = LatLng(details.latitude, details.longitude);
      } else {
        // Fallback to current position or default
        selectedPosition = _currentPosition ?? _defaultPosition;
      }
    } else {
      selectedPosition = LatLng(result.latitude, result.longitude);
    }

    setState(() {
      _selectedPosition = selectedPosition;
      _centerPosition = selectedPosition;
      _selectedAddress = result.formattedAddress;
      _searchController.text = result.formattedAddress;
      _searchResults = [];
      _updateMarkers();
    });

    // Calculate distance from current position
    if (_currentPosition != null) {
      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        selectedPosition.latitude,
        selectedPosition.longitude,
      );
      setState(() {
        _distanceFromCurrent = distance;
      });
    }

    // Move camera to selected location
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: selectedPosition,
          zoom: 15.0,
        ),
      ),
    );

    widget.onLocationChanged?.call(selectedPosition);
  }

  LatLng get _initialPosition {
    return widget.initialPosition ?? 
           _currentPosition ?? 
           _defaultPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: Column(
        children: [
          // Search Bar
          if (widget.showSearchBar)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _performSearch,
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      hintStyle: GoogleFonts.poppins(
                        color: AppColors.midGray,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.midGray,
                      ),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.lightGray),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.lightGray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primaryOrange),
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                  
                  // Search Results
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(
                        maxHeight: 250, // Limit search results height
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.midGray.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length > 5 ? 5 : _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: AppColors.primaryOrange,
                              size: 20,
                            ),
                            title: Text(
                              result.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              result.formattedAddress,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.midGray,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSearchResult(result),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          
          // Selected Location Info
          if (_selectedPosition != null)
            _buildSelectedLocationInfo(),
          
          // Map
          Expanded(
            child: Stack(
              children: [
                GoogleMapWidget(
                  initialPosition: _initialPosition,
                  initialZoom: 15.0,
                  markers: _markers,
                  showMyLocation: true,
                  showMyLocationButton: false,
                  showZoomControls: false,
                  showCompass: false,
                  onMapCreated: _onMapCreated,
                  onTap: _onMapTap,
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  mapType: MapType.normal,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                ),
                
                // Current Location Button
                if (widget.showCurrentLocationButton)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: AppColors.white,
                      onPressed: _moveToCurrentLocation,
                      child: Icon(
                        Icons.my_location,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                
                // Center Crosshair
                const Center(
                  child: Icon(
                    Icons.add,
                    color: AppColors.primaryOrange,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.midGray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      widget.cancelButtonText ?? 'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.midGray,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_centerPosition != null || _selectedPosition != null) ? _confirmSelection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      widget.confirmButtonText ?? 'Select Location',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
}
