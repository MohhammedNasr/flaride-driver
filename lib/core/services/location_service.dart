import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _lastKnownLatitudeKey = 'last_known_latitude';
  static const String _lastKnownLongitudeKey = 'last_known_longitude';
  static const String _lastKnownCityKey = 'last_known_city';
  static const String _lastKnownAddressKey = 'last_known_address';

  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  
  LocationService._();

  Position? _currentPosition;
  String? _currentCity;
  String? _currentAddress;

  Position? get currentPosition => _currentPosition;
  String? get currentCity => _currentCity;
  String? get currentAddress => _currentAddress;

  Future<void> loadSavedLocation() async {
    try {
      final savedPosition = await _getLastKnownPosition();
      if (savedPosition != null) {
        _currentPosition = savedPosition;
        _currentCity = await _getLastKnownCity();
        _currentAddress = await _getLastKnownAddress();
        debugPrint('LocationService: Loaded saved location - Address: $_currentAddress, City: $_currentCity');
      }
    } catch (e) {
      debugPrint('LocationService: Error loading saved location: $e');
    }
  }

  Future<bool> requestLocationPermission() async {
    debugPrint('LocationService: Checking if location service is enabled...');
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('LocationService: Location service enabled: $serviceEnabled');
    
    if (!serviceEnabled) {
      debugPrint('LocationService: Location services are disabled');
      throw LocationServiceException('Location services are disabled.');
    }

    debugPrint('LocationService: Checking location permission...');
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('LocationService: Current permission: $permission');
    
    if (permission == LocationPermission.denied) {
      debugPrint('LocationService: Permission denied, requesting permission...');
      permission = await Geolocator.requestPermission();
      debugPrint('LocationService: Permission after request: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: Permission still denied after request');
        throw LocationServiceException('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('LocationService: Permission permanently denied');
      throw LocationServiceException(
        'Location permissions are permanently denied, we cannot request permissions.'
      );
    }

    debugPrint('LocationService: Permission granted: $permission');
    return true;
  }

  Future<Position> getCurrentPosition() async {
    try {
      debugPrint('LocationService: Requesting location permission...');
      await requestLocationPermission();
      
      debugPrint('LocationService: Getting current position from GPS...');
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      debugPrint('LocationService: Got GPS position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      debugPrint('LocationService: Position accuracy: ${_currentPosition?.accuracy}');

      // Save to preferences
      await _saveLocationToPreferences(_currentPosition!);
      
      return _currentPosition!;
    } catch (e) {
      debugPrint('LocationService: Error getting current position: $e');
      
      // Try to get last known location from preferences
      debugPrint('LocationService: Trying to get last known position from preferences...');
      final lastKnownPosition = await _getLastKnownPosition();
      if (lastKnownPosition != null) {
        debugPrint('LocationService: Using last known position: ${lastKnownPosition.latitude}, ${lastKnownPosition.longitude}');
        _currentPosition = lastKnownPosition;
        return lastKnownPosition;
      }
      
      debugPrint('LocationService: No saved location found, using default location (Abidjan)');
      // If all else fails, return a default location (Abidjan, Côte d'Ivoire)
      _currentPosition = Position(
        latitude: 5.3600,
        longitude: -4.0083,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      return _currentPosition!;
    }
  }

  Future<String> getCurrentCity() async {
    if (_currentCity != null) {
      debugPrint('LocationService: Returning cached city: $_currentCity');
      return _currentCity!;
    }
    
    try {
      final position = _currentPosition ?? await getCurrentPosition();
      debugPrint('LocationService: Getting city for position: ${position.latitude}, ${position.longitude}');
      
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      debugPrint('LocationService: Found ${placemarks.length} placemarks for city');
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _currentCity = placemark.locality ?? placemark.administrativeArea ?? 'Abidjan';
        
        debugPrint('LocationService: Formatted city: $_currentCity');
        
        // Save to preferences
        await _saveCityToPreferences(_currentCity!);
        
        return _currentCity!;
      }
      
      debugPrint('LocationService: No placemarks found for city, returning Abidjan');
      return 'Abidjan';
    } catch (e) {
      debugPrint('LocationService: Error getting city: $e');
      
      // Try to get last known city from preferences
      final lastKnownCity = await _getLastKnownCity();
      if (lastKnownCity != null) {
        _currentCity = lastKnownCity;
        return lastKnownCity;
      }
      
      // Default to Abidjan if all else fails
      _currentCity = 'Abidjan';
      return _currentCity!;
    }
  }

  Future<String> getCurrentAddress() async {
    if (_currentAddress != null) {
      debugPrint('LocationService: Returning cached address: $_currentAddress');
      return _currentAddress!;
    }
    
    try {
      final position = _currentPosition ?? await getCurrentPosition();
      debugPrint('LocationService: Getting address for position: ${position.latitude}, ${position.longitude}');
      
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      debugPrint('LocationService: Found ${placemarks.length} placemarks');
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _currentAddress = _formatAddress(placemark);
        
        debugPrint('LocationService: Formatted address: $_currentAddress');
        
        // Save to preferences
        await _saveAddressToPreferences(_currentAddress!);
        
        return _currentAddress!;
      }
      
      debugPrint('LocationService: No placemarks found, returning Unknown Address');
      return 'Unknown Address';
    } catch (e) {
      debugPrint('LocationService: Error getting address: $e');
      // Try to get last known address from preferences
      final lastKnownAddress = await _getLastKnownAddress();
      if (lastKnownAddress != null) {
        _currentAddress = lastKnownAddress;
        return lastKnownAddress;
      }
      
      throw LocationServiceException('Failed to get current address: $e');
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      _currentPosition = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      // Clear cached values to force recalculation
      _currentCity = null;
      _currentAddress = null;

      // Get city and address for new location
      _currentCity = await getCurrentCity();
      _currentAddress = await getCurrentAddress();

      debugPrint('LocationService: Updated address to: $_currentAddress');
      debugPrint('LocationService: Updated city to: $_currentCity');

      // Save to preferences
      await _saveLocationToPreferences(_currentPosition!);
    } catch (e) {
      throw LocationServiceException('Failed to update location: $e');
    }
  }

  Future<double> calculateDistance(
    double lat1, double lon1, double lat2, double lon2,
  ) async {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  Future<List<Location>> searchPlaces(String query) async {
    try {
      final locations = await locationFromAddress(query);
      return locations;
    } catch (e) {
      throw LocationServiceException('Failed to search places: $e');
    }
  }

  Future<void> _saveLocationToPreferences(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lastKnownLatitudeKey, position.latitude);
    await prefs.setDouble(_lastKnownLongitudeKey, position.longitude);
  }

  Future<void> _saveCityToPreferences(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKnownCityKey, city);
  }

  Future<void> _saveAddressToPreferences(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKnownAddressKey, address);
  }

  Future<Position?> _getLastKnownPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_lastKnownLatitudeKey);
    final lng = prefs.getDouble(_lastKnownLongitudeKey);
    
    if (lat != null && lng != null) {
      return Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
    
    return null;
  }

  Future<String?> _getLastKnownCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastKnownCityKey);
  }

  Future<String?> _getLastKnownAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastKnownAddressKey);
  }

  String _formatAddress(Placemark placemark) {
    final parts = <String>[];

    // Prioritize specific street components and avoid Plus Codes
    if (placemark.thoroughfare?.isNotEmpty == true) {
      parts.add(placemark.thoroughfare!);
    } else if (placemark.street?.isNotEmpty == true) {
      // Check if placemark.street is a Plus Code (e.g., "49HF+GM8")
      final plusCodeRegex = RegExp(r'^[0-9A-Z]{4}\+[0-9A-Z]{2,4}$');
      if (!plusCodeRegex.hasMatch(placemark.street!)) {
        parts.add(placemark.street!);
      } else if (placemark.name?.isNotEmpty == true && !plusCodeRegex.hasMatch(placemark.name!)) {
        // If street is a Plus Code, try to use name if it's not also a Plus Code
        parts.add(placemark.name!);
      }
    } else if (placemark.name?.isNotEmpty == true) {
      // Fallback to name if no street info and name is not a Plus Code
      final plusCodeRegex = RegExp(r'^[0-9A-Z]{4}\+[0-9A-Z]{2,4}$');
      if (!plusCodeRegex.hasMatch(placemark.name!)) {
        parts.add(placemark.name!);
      }
    }

    if (placemark.subLocality?.isNotEmpty == true) {
      parts.add(placemark.subLocality!);
    }
    if (placemark.locality?.isNotEmpty == true) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea?.isNotEmpty == true) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.country?.isNotEmpty == true) {
      parts.add(placemark.country!);
    }

    // Remove duplicates and empty strings, then join
    return parts.where((element) => element.isNotEmpty).toSet().join(', ');
  }

  void clearLocation() {
    _currentPosition = null;
    _currentCity = null;
    _currentAddress = null;
  }

  Future<void> clearSavedLocation() async {
    debugPrint('LocationService: Clearing saved location from SharedPreferences...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastKnownLatitudeKey);
      await prefs.remove(_lastKnownLongitudeKey);
      await prefs.remove(_lastKnownCityKey);
      await prefs.remove(_lastKnownAddressKey);
      debugPrint('LocationService: Saved location cleared successfully');
    } catch (e) {
      debugPrint('LocationService: Error clearing saved location: $e');
    }
  }
}

class LocationServiceException implements Exception {
  final String message;
  
  const LocationServiceException(this.message);
  
  @override
  String toString() => 'LocationServiceException: $message';
}
