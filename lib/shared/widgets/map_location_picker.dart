import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/places_service.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialAddress;
  final Function(LatLng position, String address) onLocationSelected;
  final Function(String address) onAddressChanged;

  const MapLocationPicker({
    super.key,
    this.initialPosition,
    this.initialAddress,
    required this.onLocationSelected,
    required this.onAddressChanged,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  LatLng _selectedPosition = const LatLng(30.0444, 31.2357); // Cairo default
  String _currentAddress = '';
  bool _isLoadingAddress = false;
  Set<Marker> _markers = {};
  
  final TextEditingController _searchController = TextEditingController();
  List<PlaceSearchResult> _searchResults = [];
  bool _isSearching = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _selectedPosition = widget.initialPosition!;
      _currentAddress = widget.initialAddress ?? '';
      _updateMarker();
    } else {
      _getCurrentLocation();
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _getCurrentLocation() async {
    try {
      // Try to get current location
      // This would typically use a location service
      // For now, we'll use the default Cairo position
      _updateMarker();
      await _reverseGeocode(_selectedPosition);
    } catch (e) {
      print('DEBUG: Error getting current location: $e');
    }
  }

  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedPosition,
          draggable: true,
          onDragEnd: (LatLng newPosition) {
            _selectedPosition = newPosition;
            _reverseGeocode(newPosition);
          },
        ),
      };
    });
  }

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      print('DEBUG: Reverse geocoding position: ${position.latitude}, ${position.longitude}');
      
      // Use PlacesService for reverse geocoding
      final address = await PlacesService.reverseGeocode(position.latitude, position.longitude);
      
      setState(() {
        _currentAddress = address;
        _isLoadingAddress = false;
      });
      
      widget.onAddressChanged(address);
    } catch (e) {
      print('DEBUG: Error reverse geocoding: $e');
      setState(() {
        _currentAddress = 'Unable to determine address';
        _isLoadingAddress = false;
      });
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
    _updateMarker();
    _reverseGeocode(position);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }
  
  void _searchPlaces(String query) async {
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
      print('DEBUG: Search error: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }
  
  void _selectSearchResult(PlaceSearchResult place) async {
    setState(() {
      _selectedPosition = place.location;
      _currentAddress = place.formattedAddress;
      _searchResults = [];
      _searchController.clear();
    });
    
    _updateMarker();
    
    // Animate camera to selected location
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: place.location,
          zoom: 16.0,
        ),
      ),
    );
    
    widget.onAddressChanged(place.formattedAddress);
  }

  void _confirmLocation() {
    widget.onLocationSelected(_selectedPosition, _currentAddress);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Select Location',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _confirmLocation,
            child: Text(
              'Confirm',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchPlaces(value);
              },
              decoration: InputDecoration(
                hintText: 'Search for a location',
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.midGray,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.primaryOrange,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.lightGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
          
          // Search results
          if (_isSearching)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.white,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryOrange,
                ),
              ),
            )
          else if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              color: AppColors.white,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: AppColors.primaryOrange,
                    ),
                    title: Text(
                      place.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      place.formattedAddress,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.midGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectSearchResult(place),
                  );
                },
              ),
            ),
          
          // Address display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Address',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.midGray,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isLoadingAddress)
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Getting address...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.midGray,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    _currentAddress.isNotEmpty ? _currentAddress : 'Tap on map to select location',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkGray,
                    ),
                  ),
              ],
            ),
          ),
          
          // Map
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _selectedPosition,
                zoom: 15.0,
              ),
              markers: _markers,
              onTap: _onMapTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
            ),
          ),
          
          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: AppColors.primaryOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search for a location or tap on the map',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.midGray,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.drag_indicator,
                      color: AppColors.primaryOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drag the marker to fine-tune your location',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.midGray,
                        ),
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
}
