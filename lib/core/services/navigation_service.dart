import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// Open Google Maps with directions to destination
  Future<bool> openGoogleMapsNavigation({
    required double destinationLat,
    required double destinationLng,
    String? destinationName,
  }) async {
    try {
      // Get current location
      final position = await _getCurrentPosition();
      
      String url;
      if (position != null) {
        // With origin (current location)
        url = 'https://www.google.com/maps/dir/?api=1'
            '&origin=${position.latitude},${position.longitude}'
            '&destination=$destinationLat,$destinationLng'
            '&travelmode=driving';
      } else {
        // Without origin (Google Maps will use device location)
        url = 'https://www.google.com/maps/dir/?api=1'
            '&destination=$destinationLat,$destinationLng'
            '&travelmode=driving';
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('NavigationService: Error opening Google Maps: $e');
      return false;
    }
  }

  /// Open Apple Maps with directions (iOS)
  Future<bool> openAppleMapsNavigation({
    required double destinationLat,
    required double destinationLng,
    String? destinationName,
  }) async {
    try {
      final name = destinationName ?? 'Destination';
      final url = 'http://maps.apple.com/?daddr=$destinationLat,$destinationLng&dirflg=d&t=m';
      
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('NavigationService: Error opening Apple Maps: $e');
      return false;
    }
  }

  /// Open Waze with directions
  Future<bool> openWazeNavigation({
    required double destinationLat,
    required double destinationLng,
  }) async {
    try {
      final url = 'https://waze.com/ul?ll=$destinationLat,$destinationLng&navigate=yes';
      
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('NavigationService: Error opening Waze: $e');
      return false;
    }
  }

  /// Navigate to restaurant for pickup
  Future<bool> navigateToPickup({
    required double restaurantLat,
    required double restaurantLng,
    String? restaurantName,
  }) async {
    return openGoogleMapsNavigation(
      destinationLat: restaurantLat,
      destinationLng: restaurantLng,
      destinationName: restaurantName,
    );
  }

  /// Navigate to customer for delivery
  Future<bool> navigateToDelivery({
    required double customerLat,
    required double customerLng,
    String? customerName,
  }) async {
    return openGoogleMapsNavigation(
      destinationLat: customerLat,
      destinationLng: customerLng,
      destinationName: customerName,
    );
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000;
  }

  /// Estimate delivery time based on distance (rough estimate)
  int estimateDeliveryMinutes(double distanceKm) {
    // Assume average speed of 25 km/h in city traffic
    // Add 5 minutes for pickup and 3 minutes for delivery
    const avgSpeedKmh = 25.0;
    const pickupTime = 5;
    const deliveryTime = 3;
    
    final travelMinutes = (distanceKm / avgSpeedKmh * 60).round();
    return travelMinutes + pickupTime + deliveryTime;
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) return null;
      }
      
      if (permission == LocationPermission.deniedForever) return null;
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('NavigationService: Error getting current position: $e');
      return null;
    }
  }
}
