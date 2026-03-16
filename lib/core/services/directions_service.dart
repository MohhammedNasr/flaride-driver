import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flaride_driver/core/config/environment.dart';
import 'package:flaride_driver/core/config/api_config.dart';

class DirectionsService {
  static String get _apiKey => EnvironmentConfig.googleMapsApiKey;
  static const String _directionsBaseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Get driving directions between two points
  static Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    LatLng? waypoint,
    TravelMode travelMode = TravelMode.driving,
    bool avoidHighways = false,
    bool avoidTolls = false,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': _getTravelModeString(travelMode),
        'key': _apiKey,
      };

      if (waypoint != null) {
        queryParams['waypoints'] = '${waypoint.latitude},${waypoint.longitude}';
      }

      if (avoidHighways) {
        queryParams['avoid'] = 'highways';
      }

      if (avoidTolls) {
        final currentAvoid = queryParams['avoid'] ?? '';
        queryParams['avoid'] = currentAvoid.isEmpty ? 'tolls' : '$currentAvoid|tolls';
      }

      final uri = Uri.parse(_directionsBaseUrl).replace(queryParameters: queryParams);
      
      print('Directions API Request: $uri');
      
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      print('Directions API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return DirectionsResult.fromJson(data);
        } else {
          print('Directions API Error: ${data['status']} - ${data['error_message']}');
          return null;
        }
      } else {
        print('Directions API HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Directions API Exception: $e');
      return null;
    }
  }

  static String _getTravelModeString(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'driving';
      case TravelMode.walking:
        return 'walking';
      case TravelMode.bicycling:
        return 'bicycling';
      case TravelMode.transit:
        return 'transit';
    }
  }
}

enum TravelMode {
  driving,
  walking,
  bicycling,
  transit,
}

class DirectionsResult {
  final List<Route> routes;
  final String status;
  final String? errorMessage;

  DirectionsResult({
    required this.routes,
    required this.status,
    this.errorMessage,
  });

  factory DirectionsResult.fromJson(Map<String, dynamic> json) {
    return DirectionsResult(
      routes: (json['routes'] as List?)
          ?.map((route) => Route.fromJson(route))
          .toList() ?? [],
      status: json['status'] ?? 'UNKNOWN_ERROR',
      errorMessage: json['error_message'],
    );
  }

  bool get isOk => status == 'OK' && routes.isNotEmpty;
  
  Route? get firstRoute => routes.isNotEmpty ? routes.first : null;
}

class Route {
  final List<Leg> legs;
  final OverviewPolyline overviewPolyline;
  final List<String> warnings;
  final Bounds? bounds;

  Route({
    required this.legs,
    required this.overviewPolyline,
    required this.warnings,
    this.bounds,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      legs: (json['legs'] as List?)
          ?.map((leg) => Leg.fromJson(leg))
          .toList() ?? [],
      overviewPolyline: OverviewPolyline.fromJson(json['overview_polyline'] ?? {}),
      warnings: List<String>.from(json['warnings'] ?? []),
      bounds: json['bounds'] != null ? Bounds.fromJson(json['bounds']) : null,
    );
  }

  Duration get totalDuration {
    return legs.fold(
      Duration.zero,
      (total, leg) => total + leg.duration,
    );
  }

  Distance get totalDistance {
    return legs.fold(
      Distance(value: 0, text: ''),
      (total, leg) => Distance(
        value: total.value + leg.distance.value,
        text: '${total.value + leg.distance.value} m',
      ),
    );
  }
}

class Leg {
  final Distance distance;
  final Duration duration;
  final String? durationText;
  final String? distanceText;
  final LatLng startLocation;
  final LatLng endLocation;
  final String? startAddress;
  final String? endAddress;
  final List<Step> steps;

  Leg({
    required this.distance,
    required this.duration,
    this.durationText,
    this.distanceText,
    required this.startLocation,
    required this.endLocation,
    this.startAddress,
    this.endAddress,
    required this.steps,
  });

  factory Leg.fromJson(Map<String, dynamic> json) {
    return Leg(
      distance: Distance.fromJson(json['distance'] ?? {}),
      duration: Duration(seconds: json['duration']?['value'] ?? 0),
      durationText: json['duration']?['text'],
      distanceText: json['distance']?['text'],
      startLocation: LatLng(
        json['start_location']?['lat']?.toDouble() ?? 0.0,
        json['start_location']?['lng']?.toDouble() ?? 0.0,
      ),
      endLocation: LatLng(
        json['end_location']?['lat']?.toDouble() ?? 0.0,
        json['end_location']?['lng']?.toDouble() ?? 0.0,
      ),
      startAddress: json['start_address'],
      endAddress: json['end_address'],
      steps: (json['steps'] as List?)
          ?.map((step) => Step.fromJson(step))
          .toList() ?? [],
    );
  }
}

class Step {
  final Distance distance;
  final Duration duration;
  final LatLng startLocation;
  final LatLng endLocation;
  final String? htmlInstructions;
  final String? maneuver;
  final OverviewPolyline polyline;

  Step({
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    this.htmlInstructions,
    this.maneuver,
    required this.polyline,
  });

  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      distance: Distance.fromJson(json['distance'] ?? {}),
      duration: Duration(seconds: json['duration']?['value'] ?? 0),
      startLocation: LatLng(
        json['start_location']?['lat']?.toDouble() ?? 0.0,
        json['start_location']?['lng']?.toDouble() ?? 0.0,
      ),
      endLocation: LatLng(
        json['end_location']?['lat']?.toDouble() ?? 0.0,
        json['end_location']?['lng']?.toDouble() ?? 0.0,
      ),
      htmlInstructions: json['html_instructions'],
      maneuver: json['maneuver'],
      polyline: OverviewPolyline.fromJson(json['polyline'] ?? {}),
    );
  }
}

class OverviewPolyline {
  final String points;

  OverviewPolyline({required this.points});

  factory OverviewPolyline.fromJson(Map<String, dynamic> json) {
    return OverviewPolyline(
      points: json['points'] ?? '',
    );
  }

  /// Decode the polyline points to a list of LatLng coordinates
  List<LatLng> get decodedPoints {
    return _decodePolyline(points);
  }

  static List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < polyline.length) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}

class Distance {
  final int value; // in meters
  final String text;

  Distance({required this.value, required this.text});

  factory Distance.fromJson(Map<String, dynamic> json) {
    return Distance(
      value: json['value'] ?? 0,
      text: json['text'] ?? '',
    );
  }
}

class Bounds {
  final LatLng northeast;
  final LatLng southwest;

  Bounds({required this.northeast, required this.southwest});

  factory Bounds.fromJson(Map<String, dynamic> json) {
    return Bounds(
      northeast: LatLng(
        json['northeast']?['lat']?.toDouble() ?? 0.0,
        json['northeast']?['lng']?.toDouble() ?? 0.0,
      ),
      southwest: LatLng(
        json['southwest']?['lat']?.toDouble() ?? 0.0,
        json['southwest']?['lng']?.toDouble() ?? 0.0,
      ),
    );
  }
}
