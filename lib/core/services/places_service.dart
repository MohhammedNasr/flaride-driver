import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flaride_driver/core/config/api_config.dart';
import 'package:flaride_driver/core/config/environment.dart';

class PlacesService {
  static String get _placesApiKey => EnvironmentConfig.googleMapsApiKey;
  static const String _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Search for places using Google Places Text Search API (more reliable)
  static Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      print('DEBUG: Searching for places with query: "$query"');
      print('DEBUG: Using API key: ${_placesApiKey.substring(0, 10)}...');
      
      // Use Text Search API instead of Autocomplete for better reliability
      final url = Uri.parse('$_placesBaseUrl/textsearch/json');
      final response = await http.get(
        url.replace(
          queryParameters: {
            'query': query,
            'key': _placesApiKey,
            'language': 'en',
          },
        ),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG: Places API Request: $url');
      print('DEBUG: Places API Response: ${response.statusCode} - Body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: API Response data: $data');
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          print('DEBUG: Found ${results.length} results');
          
          return results.map((json) => PlaceSearchResult.fromJson(json)).toList();
        } else {
          print('DEBUG: Places API error: ${data['status']} - ${data['error_message']}');
          // Fallback to geocoding
          return await _fallbackGeocodingSearch(query);
        }
      } else {
        print('DEBUG: Places API HTTP error: ${response.statusCode} - ${response.body}');
        // Fallback to geocoding
        return await _fallbackGeocodingSearch(query);
      }
    } catch (e) {
      print('DEBUG: Places search error: $e');
      // Fallback to geocoding
      return await _fallbackGeocodingSearch(query);
    }
  }

  /// Get place details by place ID
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse('$_placesBaseUrl/details/json');
      final response = await http.get(
        url.replace(
          queryParameters: {
            'place_id': placeId,
            'key': _placesApiKey,
            'fields': 'name,formatted_address,geometry,place_id',
          },
        ),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        }
      }
      return null;
    } catch (e) {
      print('Place details error: $e');
      return null;
    }
  }

  /// Reverse geocoding - get address from coordinates
  static Future<String> reverseGeocode(double latitude, double longitude) async {
    try {
      print('DEBUG: Reverse geocoding for lat: $latitude, lng: $longitude');
      
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isEmpty) {
        print('DEBUG: No placemarks found');
        return 'Unknown location';
      }
      
      final placemark = placemarks.first;
      final addressParts = <String>[];
      
      if (placemark.street?.isNotEmpty == true) {
        addressParts.add(placemark.street!);
      }
      if (placemark.subLocality?.isNotEmpty == true) {
        addressParts.add(placemark.subLocality!);
      }
      if (placemark.locality?.isNotEmpty == true) {
        addressParts.add(placemark.locality!);
      }
      if (placemark.administrativeArea?.isNotEmpty == true) {
        addressParts.add(placemark.administrativeArea!);
      }
      if (placemark.country?.isNotEmpty == true) {
        addressParts.add(placemark.country!);
      }
      
      final address = addressParts.join(', ');
      print('DEBUG: Reverse geocoded address: $address');
      
      return address.isNotEmpty ? address : 'Unknown location';
    } catch (e) {
      print('DEBUG: Reverse geocoding error: $e');
      return 'Unknown location';
    }
  }

  /// Fallback search using Geocoding API
  static Future<List<PlaceSearchResult>> _fallbackGeocodingSearch(String query) async {
    try {
      print('DEBUG: Using fallback geocoding search for: $query');
      final locations = await locationFromAddress(query);
      
      if (locations.isEmpty) {
        print('DEBUG: No locations found via geocoding');
        return [];
      }
      
      print('DEBUG: Found ${locations.length} locations via geocoding');
      
      return locations.map((location) => PlaceSearchResult(
        placeId: 'geocoding_${location.latitude}_${location.longitude}',
        name: query,
        formattedAddress: '${location.latitude}, ${location.longitude}',
        latitude: location.latitude,
        longitude: location.longitude,
      )).toList();
    } catch (e) {
      print('DEBUG: Geocoding fallback error: $e');
      return [];
    }
  }
}

class PlaceSearchResult {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  PlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });
  
  LatLng get location => LatLng(latitude, longitude);

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final location = geometry['location'] as Map<String, dynamic>;
    
    return PlaceSearchResult(
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      formattedAddress: json['formatted_address'] as String,
      latitude: (location['lat'] as num).toDouble(),
      longitude: (location['lng'] as num).toDouble(),
    );
  }

  factory PlaceSearchResult.fromAutocompleteJson(Map<String, dynamic> json) {
    return PlaceSearchResult(
      placeId: json['place_id'] as String,
      name: json['structured_formatting']?['main_text'] as String? ?? json['description'] as String,
      formattedAddress: json['description'] as String,
      latitude: 0.0, // Will be filled by getPlaceDetails
      longitude: 0.0, // Will be filled by getPlaceDetails
    );
  }
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final location = geometry['location'] as Map<String, dynamic>;
    
    return PlaceDetails(
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      formattedAddress: json['formatted_address'] as String,
      latitude: (location['lat'] as num).toDouble(),
      longitude: (location['lng'] as num).toDouble(),
    );
  }
}
