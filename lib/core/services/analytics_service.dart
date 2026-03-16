import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      
      // Enable crashlytics collection
      await _crashlytics!.setCrashlyticsCollectionEnabled(true);
      
      // Pass Flutter errors to Crashlytics
      FlutterError.onError = _crashlytics!.recordFlutterFatalError;
      
      _isInitialized = true;
      debugPrint('AnalyticsService: Initialized');
    } catch (e) {
      debugPrint('AnalyticsService: Error initializing: $e');
    }
  }

  // User identification
  Future<void> setUserId(String? userId) async {
    await _analytics?.setUserId(id: userId);
    await _crashlytics?.setUserIdentifier(userId ?? '');
  }

  Future<void> setUserProperties({
    String? driverId,
    String? vehicleType,
    String? city,
  }) async {
    if (driverId != null) {
      await _analytics?.setUserProperty(name: 'driver_id', value: driverId);
    }
    if (vehicleType != null) {
      await _analytics?.setUserProperty(name: 'vehicle_type', value: vehicleType);
    }
    if (city != null) {
      await _analytics?.setUserProperty(name: 'city', value: city);
    }
  }

  // Screen tracking
  Future<void> logScreenView(String screenName) async {
    await _analytics?.logScreenView(screenName: screenName);
  }

  // Driver events
  Future<void> logDriverOnline() async {
    await _analytics?.logEvent(name: 'driver_online');
  }

  Future<void> logDriverOffline({int? onlineMinutes}) async {
    await _analytics?.logEvent(
      name: 'driver_offline',
      parameters: onlineMinutes != null ? {'online_minutes': onlineMinutes} : null,
    );
  }

  Future<void> logOrderViewed(String orderId) async {
    await _analytics?.logEvent(
      name: 'order_viewed',
      parameters: {'order_id': orderId},
    );
  }

  Future<void> logOrderAccepted(String orderId, double earnings) async {
    await _analytics?.logEvent(
      name: 'order_accepted',
      parameters: {
        'order_id': orderId,
        'earnings': earnings,
      },
    );
  }

  Future<void> logOrderDeclined(String orderId, String? reason) async {
    final params = <String, Object>{'order_id': orderId};
    if (reason != null) params['reason'] = reason;
    await _analytics?.logEvent(
      name: 'order_declined',
      parameters: params,
    );
  }

  Future<void> logPickupCompleted(String orderId) async {
    await _analytics?.logEvent(
      name: 'pickup_completed',
      parameters: {'order_id': orderId},
    );
  }

  Future<void> logDeliveryCompleted(String orderId, int deliveryMinutes) async {
    await _analytics?.logEvent(
      name: 'delivery_completed',
      parameters: {
        'order_id': orderId,
        'delivery_minutes': deliveryMinutes,
      },
    );
  }

  Future<void> logEarningsViewed(double totalEarnings) async {
    await _analytics?.logEvent(
      name: 'earnings_viewed',
      parameters: {'total_earnings': totalEarnings},
    );
  }

  Future<void> logPayoutRequested(double amount) async {
    await _analytics?.logEvent(
      name: 'payout_requested',
      parameters: {'amount': amount},
    );
  }

  // Navigation events
  Future<void> logNavigationStarted(String destination) async {
    await _analytics?.logEvent(
      name: 'navigation_started',
      parameters: {'destination': destination},
    );
  }

  // Error logging
  Future<void> logError(dynamic error, StackTrace? stackTrace, {String? reason}) async {
    await _crashlytics?.recordError(error, stackTrace, reason: reason);
  }

  Future<void> logMessage(String message) async {
    await _crashlytics?.log(message);
  }

  // Custom events
  Future<void> logCustomEvent(String name, Map<String, Object>? parameters) async {
    await _analytics?.logEvent(name: name, parameters: parameters);
  }
}
