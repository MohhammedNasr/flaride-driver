import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flaride_driver/core/models/driver.dart';
import 'package:flaride_driver/core/services/driver_service.dart';

class DriverProvider extends ChangeNotifier {
  final DriverService _driverService = DriverService();

  // Storage keys
  static const String _workLocationLatKey = 'driver_work_location_lat';
  static const String _workLocationLngKey = 'driver_work_location_lng';
  static const String _workLocationAddressKey = 'driver_work_location_address';

  Driver? _driver;
  bool _isLoading = false;
  bool _isDriver = false;
  String? _error;
  Timer? _locationTimer;
  Timer? _ordersTimer;
  StreamSubscription<Position>? _locationSubscription;
  List<AvailableOrder> _availableOrders = [];
  bool _isLoadingOrders = false;
  bool _hasActiveOrder = false;
  String? _activeOrderId;
  String? _activeOrderMessage;
  OrderDetails? _activeOrderDetails;
  bool _isLoadingActiveOrder = false;
  bool _hasInitialOrdersFetch = false;
  bool _isFetchingAvailableOrders = false;
  Future<bool>? _driverStatusCheckFuture;
  DateTime? _lastOrdersFetchAt;

  // Work location
  double? _workLocationLat;
  double? _workLocationLng;
  String? _workLocationAddress;

  // Driver mode
  DriverMode _currentMode = DriverMode.delivery;
  static const String _driverModeKey = 'driver_current_mode';
  static const Duration _ordersPollingInterval = Duration(seconds: 5);
  static const Duration _minOrdersFetchGap = Duration(seconds: 3);

  // Getters
  Driver? get driver => _driver;
  bool get isLoading => _isLoading;
  bool get isDriver => _isDriver;
  String? get error => _error;
  bool get isOnline => _driver?.isOnline ?? false;
  bool get isAvailable => _driver?.isAvailable ?? false;
  bool get hasActiveOrder => _driver?.hasActiveOrder ?? false;
  List<AvailableOrder> get availableOrders => _availableOrders;
  bool get isLoadingOrders => _isLoadingOrders;
  bool get hasInitialOrdersFetch => _hasInitialOrdersFetch;
  bool get hasActiveOrderFromApi => _hasActiveOrder;
  String? get activeOrderId => _activeOrderId;
  String? get activeOrderMessage => _activeOrderMessage;
  OrderDetails? get activeOrderDetails => _activeOrderDetails;
  bool get isLoadingActiveOrder => _isLoadingActiveOrder;
  double? get workLocationLat => _workLocationLat;
  double? get workLocationLng => _workLocationLng;
  String? get workLocationAddress => _workLocationAddress;
  bool get hasWorkLocation =>
      _workLocationLat != null && _workLocationLng != null;

  // Mode getters
  DriverMode get currentMode => _currentMode;
  bool get isInRideMode => _currentMode == DriverMode.rides;
  bool get isInDeliveryMode => _currentMode == DriverMode.delivery;
  bool get canSwitchToRides => _driver?.isRideDriver ?? false;
  bool get canSwitchToDelivery => _driver?.isDeliveryDriver ?? false;
  bool get isDualMode => _driver?.isDualMode ?? false;

  /// Switch between delivery and rides mode
  Future<void> switchMode(DriverMode mode) async {
    if (mode == _currentMode) return;
    if (mode == DriverMode.rides && !canSwitchToRides) return;
    if (mode == DriverMode.delivery && !canSwitchToDelivery) return;

    _currentMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _driverModeKey, mode == DriverMode.rides ? 'rides' : 'delivery');
    _driver = _driver?.copyWith(driverMode: mode);
    notifyListeners();
  }

  /// Load saved driver mode
  Future<void> _loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_driverModeKey);
      if (saved == 'rides' && canSwitchToRides) {
        _currentMode = DriverMode.rides;
      } else {
        _currentMode = DriverMode.delivery;
      }
    } catch (_) {}
  }

  /// Load saved work location from local storage
  Future<void> loadSavedWorkLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _workLocationLat = prefs.getDouble(_workLocationLatKey);
      _workLocationLng = prefs.getDouble(_workLocationLngKey);
      _workLocationAddress = prefs.getString(_workLocationAddressKey);

      debugPrint(
          'Loaded work location: $_workLocationAddress ($_workLocationLat, $_workLocationLng)');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading work location: $e');
    }
  }

  /// Save work location to local storage
  Future<void> _saveWorkLocation(
      double lat, double lng, String? address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_workLocationLatKey, lat);
      await prefs.setDouble(_workLocationLngKey, lng);
      if (address != null) {
        await prefs.setString(_workLocationAddressKey, address);
      }
      debugPrint('Saved work location: $address ($lat, $lng)');
    } catch (e) {
      debugPrint('Error saving work location: $e');
    }
  }

  /// Check if current user is a driver and load profile
  Future<bool> checkDriverStatus() {
    if (_driverStatusCheckFuture != null) {
      return _driverStatusCheckFuture!;
    }

    final future = _checkDriverStatusInternal();
    _driverStatusCheckFuture = future;
    future.whenComplete(() => _driverStatusCheckFuture = null);
    return future;
  }

  Future<bool> _checkDriverStatusInternal() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _driverService.getMyProfile().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Driver status check timed out');
          return DriverProfileResponse(
            success: false,
            isDriver: _isDriver,
            message: 'Request timed out',
          );
        },
      );

      // Only update if we got a successful response
      if (response.success) {
        _isDriver = response.isDriver;
        _driver = response.driver;
      } else if (response.message != null) {
        _error = response.message;
        debugPrint('Driver status check failed: ${response.message}');
      }

      // Load saved work location and driver mode
      await loadSavedWorkLocation();
      await _loadSavedMode();

      debugPrint(
          'Driver check: isDriver=$_isDriver, isOnline=$isOnline, mode=$_currentMode');

      _isLoading = false;
      notifyListeners();

      // If driver is already online, update location and start fetching orders
      if (_isDriver && isOnline) {
        // Get current location and update server first
        final position = await _getCurrentLocation();
        if (position != null) {
          await _driverService
              .updateLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          )
              .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Location update timed out');
              return false;
            },
          );
          if (_driver != null) {
            _driver = _driver!.copyWith(
              currentLatitude: position.latitude,
              currentLongitude: position.longitude,
            );
          }
        }

        _startLocationTracking();
        _startOrdersPolling();
        await fetchAvailableOrders(
            force: true); // Fetch immediately after location update
      }

      return _isDriver;
    } catch (e) {
      debugPrint('Check driver status error: $e');
      _error = e.toString();
      // Don't reset _isDriver to false on error, keep cached value
      _isLoading = false;
      notifyListeners();
      return _isDriver;
    }
  }

  /// Refresh driver profile
  Future<void> refreshProfile() async {
    if (!_isDriver) return;

    try {
      final response = await _driverService.getMyProfile();
      if (response.success && response.driver != null) {
        _driver = response.driver;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Refresh profile error: $e');
    }
  }

  /// Check if all required documents are uploaded
  bool get areDocumentsComplete {
    if (_driver == null) return false;
    return _driver!.driverLicenseFrontUrl != null &&
        _driver!.nationalIdFrontUrl != null &&
        _driver!.vehicleRegistrationUrl != null &&
        (_driver!.insuranceCertificateUrl != null || _driver!.vehicleInsuranceUrl != null) &&
        _driver!.vehiclePhotoFrontUrl != null &&
        _driver!.inspectionCertificateUrl != null;
  }

  /// Get list of missing document names
  List<String> get missingDocuments {
    if (_driver == null) return ['All documents'];
    final missing = <String>[];
    if (_driver!.driverLicenseFrontUrl == null) missing.add('Driver License');
    if (_driver!.nationalIdFrontUrl == null) missing.add('National ID');
    if (_driver!.vehicleRegistrationUrl == null) missing.add('Vehicle Registration');
    if (_driver!.insuranceCertificateUrl == null && _driver!.vehicleInsuranceUrl == null) missing.add('Insurance Certificate');
    if (_driver!.vehiclePhotoFrontUrl == null) missing.add('Vehicle Photo (Front)');
    if (_driver!.inspectionCertificateUrl == null) missing.add('Inspection Certificate');
    return missing;
  }

  /// Go online - start accepting orders
  Future<bool> goOnline() async {
    if (_driver == null) return false;

    // Check documents before going online
    if (!areDocumentsComplete) {
      _error = 'Please upload all required documents before going online. Missing: ${missingDocuments.join(", ")}';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Get current location first
      final position = await _getCurrentLocation();

      final response = await _driverService.updateStatus(
        isOnline: true,
        isAvailable: true,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      if (response.success) {
        _driver = _driver!.copyWith(
          isOnline: true,
          isAvailable: true,
          currentLatitude: position?.latitude,
          currentLongitude: position?.longitude,
        );

        // Start location tracking
        _startLocationTracking();
        // Start fetching available orders
        _startOrdersPolling();
        // Fetch orders immediately
        await fetchAvailableOrders(force: true);
      } else {
        _error = response.message;
      }

      _isLoading = false;
      notifyListeners();
      return response.success;
    } catch (e) {
      debugPrint('Go online error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Go offline - stop accepting orders
  Future<bool> goOffline() async {
    if (_driver == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _driverService.updateStatus(
        isOnline: false,
        isAvailable: false,
      );

      if (response.success) {
        _driver = _driver!.copyWith(
          isOnline: false,
          isAvailable: false,
        );

        // Stop location tracking
        _stopLocationTracking();
        // Stop orders polling
        _stopOrdersPolling();
        // Clear available orders and reset initial fetch flag
        _availableOrders = [];
        _hasInitialOrdersFetch = false;
        _hasActiveOrder = false;
        _activeOrderDetails = null;
      } else {
        _error = response.message;
      }

      _isLoading = false;
      notifyListeners();
      return response.success;
    } catch (e) {
      debugPrint('Go offline error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle online status
  Future<bool> toggleOnlineStatus() async {
    if (isOnline) {
      return await goOffline();
    } else {
      return await goOnline();
    }
  }

  /// Start tracking driver location
  void _startLocationTracking() {
    // Update location every 30 seconds
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateLocation();
    });

    // Also listen for significant location changes
    _locationSubscription?.cancel();
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update when moved 50 meters
      ),
    ).listen((position) {
      _updateLocationWithPosition(position);
    });
  }

  /// Stop tracking driver location
  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Get location error: $e');
      return null;
    }
  }

  /// Update location to server
  Future<void> _updateLocation() async {
    final position = await _getCurrentLocation();
    if (position != null) {
      await _updateLocationWithPosition(position);
    }
  }

  Future<void> _updateLocationWithPosition(Position position) async {
    final success = await _driverService.updateLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (success && _driver != null) {
      _driver = _driver!.copyWith(
        currentLatitude: position.latitude,
        currentLongitude: position.longitude,
        lastLocationUpdate: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Update work location
  Future<bool> updateWorkLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    if (_driver == null) return false;

    try {
      final response = await _driverService.updateLocation(
        latitude: latitude,
        longitude: longitude,
      );

      if (response) {
        // Update driver model
        _driver = _driver!.copyWith(
          currentLatitude: latitude,
          currentLongitude: longitude,
          lastLocationUpdate: DateTime.now(),
        );

        // Save work location locally
        _workLocationLat = latitude;
        _workLocationLng = longitude;
        _workLocationAddress = address;
        await _saveWorkLocation(latitude, longitude, address);

        notifyListeners();

        // Refresh available orders with new location
        if (isOnline) {
          await fetchAvailableOrders(force: true);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Update work location error: $e');
      return false;
    }
  }

  /// Fetch available orders
  Future<void> fetchAvailableOrders({bool force = false}) async {
    if (!isOnline || _driver == null) {
      return;
    }
    if (_isFetchingAvailableOrders) {
      return;
    }
    final now = DateTime.now();
    if (!force &&
        _lastOrdersFetchAt != null &&
        now.difference(_lastOrdersFetchAt!) < _minOrdersFetchGap) {
      return;
    }

    _lastOrdersFetchAt = now;
    _isFetchingAvailableOrders = true;

    _isLoadingOrders = true;
    notifyListeners();

    try {
      // Use work location if set, otherwise use current location
      final lat = _workLocationLat ?? _driver?.currentLatitude;
      final lng = _workLocationLng ?? _driver?.currentLongitude;

      final response = await _driverService.getAvailableOrders(
        latitude: lat,
        longitude: lng,
      );

      if (response.success) {
        _availableOrders = response.orders;
        _hasActiveOrder = response.hasActiveOrder;
        _activeOrderId = response.activeOrderId;
        _activeOrderMessage = response.message;
        _hasInitialOrdersFetch = true;

        // Fetch active order details if there's an active order
        if (_hasActiveOrder && _activeOrderId != null) {
          await _fetchActiveOrderDetails();
        } else {
          _activeOrderDetails = null;
        }
      } else {
        _hasInitialOrdersFetch = true;
      }
    } catch (e) {
      debugPrint('Fetch available orders error: $e');
      _hasInitialOrdersFetch = true;
    } finally {
      _isFetchingAvailableOrders = false;
    }

    _isLoadingOrders = false;
    notifyListeners();
  }

  /// Fetch active order details
  Future<void> _fetchActiveOrderDetails() async {
    if (_activeOrderId == null) return;

    _isLoadingActiveOrder = true;
    // Don't notify here to avoid UI flicker

    try {
      final response = await _driverService.getOrderDetails(_activeOrderId!);
      if (response.success && response.order != null) {
        _activeOrderDetails = response.order;
        debugPrint(
            'Fetched active order details: ${_activeOrderDetails?.orderNumber}');
      }
    } catch (e) {
      debugPrint('Fetch active order details error: $e');
    }

    _isLoadingActiveOrder = false;
  }

  /// Refresh active order details
  Future<void> refreshActiveOrder() async {
    if (_activeOrderId == null) return;
    await _fetchActiveOrderDetails();
    notifyListeners();
  }

  /// Start polling for available orders
  void _startOrdersPolling() {
    _ordersTimer?.cancel();
    // Poll frequently while keeping a fetch cooldown to avoid network spam.
    _ordersTimer = Timer.periodic(_ordersPollingInterval, (_) {
      fetchAvailableOrders();
    });
  }

  /// Stop polling for available orders
  void _stopOrdersPolling() {
    _ordersTimer?.cancel();
    _ordersTimer = null;
  }

  /// Update order type preferences
  Future<bool> updateOrderPreferences({
    required bool acceptsFoodDelivery,
    required bool acceptsRideRequests,
    required bool acceptsParcelDelivery,
  }) async {
    if (_driver == null) return false;

    try {
      final response = await _driverService.updateOrderPreferences(
        acceptsFoodDelivery: acceptsFoodDelivery,
        acceptsRideRequests: acceptsRideRequests,
        acceptsParcelDelivery: acceptsParcelDelivery,
      );

      if (response.success) {
        _driver = _driver!.copyWith(
          acceptsFoodDelivery: acceptsFoodDelivery,
          acceptsRideRequests: acceptsRideRequests,
          acceptsParcelDelivery: acceptsParcelDelivery,
        );
        notifyListeners();

        // Refresh available orders with new preferences
        if (isOnline) {
          await fetchAvailableOrders(force: true);
        }
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Update order preferences error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear driver state (on logout)
  void clear() {
    _stopLocationTracking();
    _stopOrdersPolling();
    _driver = null;
    _isDriver = false;
    _error = null;
    _availableOrders = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _stopLocationTracking();
    _stopOrdersPolling();
    super.dispose();
  }
}
