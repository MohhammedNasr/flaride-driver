import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/places_service.dart';
import 'package:flaride_driver/shared/widgets/app_toast.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng, String?) onLocationSelected;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(5.3600, -4.0083);
  bool _isLoading = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<PlaceSearchResult> _searchResults = [];
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _getAddressFromCoordinates(widget.initialLocation!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty || query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await PlacesService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _selectSearchResult(PlaceSearchResult result) async {
    LatLng selectedPosition;

    if (result.latitude == 0.0 && result.longitude == 0.0) {
      final details = await PlacesService.getPlaceDetails(result.placeId);
      selectedPosition = details != null
          ? LatLng(details.latitude, details.longitude)
          : _selectedLocation;
    } else {
      selectedPosition = LatLng(result.latitude, result.longitude);
    }

    setState(() {
      _selectedLocation = selectedPosition;
      _selectedAddress = result.formattedAddress;
      _searchResults = [];
      _searchController.clear();
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_selectedLocation, 15),
    );
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    try {
      final address = await PlacesService.reverseGeocode(
        location.latitude,
        location.longitude,
      );
      if (mounted) {
        setState(() => _selectedAddress = address);
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = newLocation);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLocation, 15),
      );
      _getAddressFromCoordinates(newLocation);
    } catch (e) {
      debugPrint('Get current location error: $e');
      if (mounted) {
        AppToast.error(context, 'Could not get current location');
      }
    }
  }

  Future<void> _confirmLocation() async {
    setState(() => _isLoading = true);
    await widget.onLocationSelected(_selectedLocation, _selectedAddress);
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Set Work Location',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: (location) {
              setState(() {
                _selectedLocation = location;
                _searchResults = [];
              });
              _getAddressFromCoordinates(location);
            },
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: horizontalPadding,
            left: horizontalPadding,
            right: horizontalPadding,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a location...',
                      hintStyle: GoogleFonts.poppins(
                        color: AppColors.midGray,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.primaryOrange,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      suffixIcon: _isSearching
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: AppColors.midGray,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchResults = []);
                                  },
                                )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 13 : 14,
                    ),
                    onChanged: _searchLocation,
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      maxHeight: screenHeight * 0.35,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _searchResults.length > 5 ? 5 : _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectSearchResult(result),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 10 : 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: isSmallScreen ? 36 : 40,
                                    height: isSmallScreen ? 36 : 40,
                                    decoration: BoxDecoration(
                                      color: index == 0
                                          ? AppColors.primaryOrange
                                          : AppColors.primaryOrange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      index == 0
                                          ? Icons.star_rounded
                                          : Icons.location_on_rounded,
                                      color: index == 0
                                          ? Colors.white
                                          : AppColors.primaryOrange,
                                      size: isSmallScreen ? 18 : 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          result.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: isSmallScreen ? 13 : 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.darkGray,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          result.formattedAddress,
                                          style: GoogleFonts.poppins(
                                            fontSize: isSmallScreen ? 11 : 12,
                                            color: AppColors.midGray,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: AppColors.midGray,
                                    size: isSmallScreen ? 12 : 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            right: horizontalPadding,
            bottom: screenHeight * 0.25,
            child: FloatingActionButton.small(
              heroTag: 'myLocation',
              backgroundColor: AppColors.white,
              onPressed: _getCurrentLocation,
              child: const Icon(
                Icons.my_location,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
          Positioned(
            bottom: isSmallScreen ? 24 : 32,
            left: horizontalPadding + 4,
            right: horizontalPadding + 4,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_selectedAddress != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.primaryGreen,
                              size: isSmallScreen ? 18 : 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedAddress!,
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  color: AppColors.darkGray,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                      ],
                      Text(
                        'Lat: ${_selectedLocation.latitude.toStringAsFixed(4)}, '
                        'Lng: ${_selectedLocation.longitude.toStringAsFixed(4)}',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 10 : 11,
                          color: AppColors.midGray,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),
                SizedBox(
                  width: double.infinity,
                  height: isSmallScreen ? 46 : 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirmLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Confirm Location',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 14 : 16,
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
