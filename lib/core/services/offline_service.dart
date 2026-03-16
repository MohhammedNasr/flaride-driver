import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  
  // Cache keys
  static const String _driverProfileKey = 'cached_driver_profile';
  static const String _activeOrderKey = 'cached_active_order';
  static const String _pendingLocationsKey = 'pending_location_updates';
  static const String _pendingActionsKey = 'pending_actions';
  
  // Stream for connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Initialize offline service and listen for connectivity changes
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);
      
      if (_isOnline != wasOnline) {
        debugPrint('OfflineService: Connectivity changed - Online: $_isOnline');
        _connectivityController.add(_isOnline);
        
        if (_isOnline) {
          // Process queued items when back online
          _processQueuedItems();
        }
      }
    });
    
    debugPrint('OfflineService: Initialized - Online: $_isOnline');
  }

  /// Cache driver profile for offline access
  Future<void> cacheDriverProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_driverProfileKey, jsonEncode(profile));
      debugPrint('OfflineService: Driver profile cached');
    } catch (e) {
      debugPrint('OfflineService: Error caching driver profile: $e');
    }
  }

  /// Get cached driver profile
  Future<Map<String, dynamic>?> getCachedDriverProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_driverProfileKey);
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('OfflineService: Error getting cached driver profile: $e');
    }
    return null;
  }

  /// Cache active order for offline access
  Future<void> cacheActiveOrder(Map<String, dynamic>? order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (order != null) {
        await prefs.setString(_activeOrderKey, jsonEncode(order));
      } else {
        await prefs.remove(_activeOrderKey);
      }
      debugPrint('OfflineService: Active order cached');
    } catch (e) {
      debugPrint('OfflineService: Error caching active order: $e');
    }
  }

  /// Get cached active order
  Future<Map<String, dynamic>?> getCachedActiveOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_activeOrderKey);
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('OfflineService: Error getting cached active order: $e');
    }
    return null;
  }

  /// Queue a location update for when online
  Future<void> queueLocationUpdate(double latitude, double longitude) async {
    if (_isOnline) return; // Don't queue if online
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_pendingLocationsKey) ?? [];
      
      // Only keep the last 10 location updates to avoid too much data
      if (existing.length >= 10) {
        existing.removeAt(0);
      }
      
      existing.add(jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      
      await prefs.setStringList(_pendingLocationsKey, existing);
      debugPrint('OfflineService: Location update queued (${existing.length} pending)');
    } catch (e) {
      debugPrint('OfflineService: Error queuing location update: $e');
    }
  }

  /// Queue an action for when online (e.g., order status update)
  Future<void> queueAction(String actionType, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_pendingActionsKey) ?? [];
      
      existing.add(jsonEncode({
        'type': actionType,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      
      await prefs.setStringList(_pendingActionsKey, existing);
      debugPrint('OfflineService: Action queued - $actionType');
    } catch (e) {
      debugPrint('OfflineService: Error queuing action: $e');
    }
  }

  /// Process queued items when back online
  Future<void> _processQueuedItems() async {
    debugPrint('OfflineService: Processing queued items...');
    
    await _processPendingLocations();
    await _processPendingActions();
  }

  Future<void> _processPendingLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList(_pendingLocationsKey) ?? [];
      
      if (pending.isEmpty) return;
      
      debugPrint('OfflineService: Processing ${pending.length} pending location updates');
      
      // Get the most recent location only (others are outdated)
      if (pending.isNotEmpty) {
        final lastLocation = jsonDecode(pending.last) as Map<String, dynamic>;
        // TODO: Send to realtime service
        debugPrint('OfflineService: Would update location to ${lastLocation['latitude']}, ${lastLocation['longitude']}');
      }
      
      // Clear the queue
      await prefs.remove(_pendingLocationsKey);
      debugPrint('OfflineService: Pending locations cleared');
    } catch (e) {
      debugPrint('OfflineService: Error processing pending locations: $e');
    }
  }

  Future<void> _processPendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList(_pendingActionsKey) ?? [];
      
      if (pending.isEmpty) return;
      
      debugPrint('OfflineService: Processing ${pending.length} pending actions');
      
      for (final actionJson in pending) {
        final action = jsonDecode(actionJson) as Map<String, dynamic>;
        final type = action['type'] as String;
        final data = action['data'] as Map<String, dynamic>;
        
        // TODO: Process each action based on type
        debugPrint('OfflineService: Would process action: $type with data: $data');
      }
      
      // Clear the queue
      await prefs.remove(_pendingActionsKey);
      debugPrint('OfflineService: Pending actions cleared');
    } catch (e) {
      debugPrint('OfflineService: Error processing pending actions: $e');
    }
  }

  /// Clear all cached data (on logout)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_driverProfileKey);
      await prefs.remove(_activeOrderKey);
      await prefs.remove(_pendingLocationsKey);
      await prefs.remove(_pendingActionsKey);
      debugPrint('OfflineService: Cache cleared');
    } catch (e) {
      debugPrint('OfflineService: Error clearing cache: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    debugPrint('OfflineService: Disposed');
  }
}
