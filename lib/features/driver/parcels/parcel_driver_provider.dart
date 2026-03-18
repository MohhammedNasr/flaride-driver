import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flaride_driver/features/driver/parcels/parcel_driver_service.dart';
import 'package:flaride_driver/features/driver/parcels/parcel_order_model.dart';

class ParcelDriverProvider extends ChangeNotifier {
  final ParcelDriverService _service = ParcelDriverService();

  List<AvailableParcelOrder> _availableOrders = [];
  ActiveParcelOrder? _activeOrder;
  bool _isLoading = false;
  bool _hasInitialFetch = false;
  String? _error;
  bool _hasActiveParcelOrder = false;
  String? _activeParcelOrderId;
  Timer? _pollTimer;
  bool _isFetchingAvailableOrders = false;
  bool _isUploadingProof = false;
  String? _lastStatusRequestSignature;
  DateTime? _lastStatusRequestAt;
  DateTime? _lastAvailableOrdersFetchAt;
  static const Duration availableOrdersPollInterval = Duration(seconds: 6);
  static const Duration _minAvailableOrdersFetchGap = Duration(seconds: 3);

  // Getters
  List<AvailableParcelOrder> get availableOrders => _availableOrders;
  ActiveParcelOrder? get activeOrder => _activeOrder;
  bool get isLoading => _isLoading;
  bool get hasInitialFetch => _hasInitialFetch;
  String? get error => _error;
  bool get isUploadingProof => _isUploadingProof;
  bool get hasActiveParcelOrder {
    final status = _activeOrder?.status;
    final hasNonTerminalActiveOrder =
        _activeOrder != null && status != 'cancelled' && status != 'delivered';
    return _hasActiveParcelOrder || hasNonTerminalActiveOrder;
  }

  String? get activeParcelOrderId {
    final status = _activeOrder?.status;
    if (_activeOrder != null &&
        status != 'cancelled' &&
        status != 'delivered') {
      return _activeOrder!.id;
    }
    return _activeParcelOrderId;
  }

  /// Fetch available parcel orders
  Future<void> fetchAvailableOrders(
      {double? lat, double? lng, bool force = false}) async {
    if (_isFetchingAvailableOrders) return;
    final now = DateTime.now();
    if (!force &&
        _lastAvailableOrdersFetchAt != null &&
        now.difference(_lastAvailableOrdersFetchAt!) <
            _minAvailableOrdersFetchGap) {
      return;
    }

    _lastAvailableOrdersFetchAt = now;
    _isFetchingAvailableOrders = true;

    try {
      final response =
          await _service.getAvailableOrders(latitude: lat, longitude: lng);
      if (response.success) {
        _availableOrders = response.orders;
        _hasActiveParcelOrder = response.hasActiveParcelOrder;
        _activeParcelOrderId = response.activeParcelOrderId;
        _hasInitialFetch = true;

        // If backend reports no active order, clear stale local active state.
        if (!_hasActiveParcelOrder || _activeParcelOrderId == null) {
          _activeParcelOrderId = null;
          _activeOrder = null;
          _stopPolling();
        }

        // If backend says we have an active order, fetch its details
        if (_hasActiveParcelOrder &&
            _activeParcelOrderId != null &&
            (_activeOrder == null ||
                _activeOrder!.id != _activeParcelOrderId)) {
          await _fetchActiveOrderDetails(_activeParcelOrderId!);
        }
      }
      _error = null;
    } catch (e) {
      debugPrint('ParcelDriverProvider.fetchAvailableOrders error: $e');
      _hasInitialFetch = true;
    } finally {
      _isFetchingAvailableOrders = false;
    }
    notifyListeners();
  }

  /// Fetch active order details
  Future<void> _fetchActiveOrderDetails(String orderId) async {
    final order = await _service.getOrderDetails(orderId);
    if (order != null) {
      _activeOrder = order;
    }
  }

  /// Accept a parcel order
  Future<bool> acceptOrder(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _service.acceptOrder(orderId);
    _isLoading = false;

    if (response.success && response.order != null) {
      _activeOrder = response.order;
      _availableOrders = [];
      _hasActiveParcelOrder = true;
      _activeParcelOrderId = response.order!.id;
      _startPolling();
      notifyListeners();
      return true;
    }

    _error = response.message;
    notifyListeners();
    return false;
  }

  /// Update parcel delivery status
  Future<bool> updateStatus(String newStatus,
      {double? driverLat,
      double? driverLng,
      String? pickupProofPhoto,
      String? pickupProofMimeType,
      int? pickupProofSizeBytes,
      String? pickupProofTakenAt,
      double? pickupProofTakenLat,
      double? pickupProofTakenLng,
      String? dropoffProofPhoto,
      String? dropoffProofMimeType,
      int? dropoffProofSizeBytes,
      String? dropoffProofTakenAt,
      double? dropoffProofTakenLat,
      double? dropoffProofTakenLng,
      bool? dropoffOtpVerified,
      String? dropoffOtpCode}) async {
    if (_activeOrder == null || _isLoading) return false;
    if (_activeOrder!.status == newStatus) return true;

    final signature = '${_activeOrder!.status}->$newStatus';
    final now = DateTime.now();
    if (_lastStatusRequestSignature == signature &&
        _lastStatusRequestAt != null &&
        now.difference(_lastStatusRequestAt!) < const Duration(seconds: 2)) {
      return true;
    }
    _lastStatusRequestSignature = signature;
    _lastStatusRequestAt = now;

    _isLoading = true;
    notifyListeners();

    final response = await _service.updateStatus(
      _activeOrder!.id,
      newStatus,
      driverLat: driverLat,
      driverLng: driverLng,
      pickupProofPhoto: pickupProofPhoto,
      pickupProofMimeType: pickupProofMimeType,
      pickupProofSizeBytes: pickupProofSizeBytes,
      pickupProofTakenAt: pickupProofTakenAt,
      pickupProofTakenLat: pickupProofTakenLat,
      pickupProofTakenLng: pickupProofTakenLng,
      dropoffProofPhoto: dropoffProofPhoto,
      dropoffProofMimeType: dropoffProofMimeType,
      dropoffProofSizeBytes: dropoffProofSizeBytes,
      dropoffProofTakenAt: dropoffProofTakenAt,
      dropoffProofTakenLat: dropoffProofTakenLat,
      dropoffProofTakenLng: dropoffProofTakenLng,
      dropoffOtpVerified: dropoffOtpVerified,
      dropoffOtpCode: dropoffOtpCode,
    );

    _isLoading = false;

    if (response.success && response.order != null) {
      _activeOrder = response.order;
      final status = _activeOrder!.status;
      if (status == 'cancelled' || status == 'delivered') {
        _hasActiveParcelOrder = false;
        _activeParcelOrderId = null;
        _stopPolling();
      } else {
        _hasActiveParcelOrder = true;
        _activeParcelOrderId = _activeOrder!.id;
      }
      notifyListeners();
      return true;
    }

    _error = response.message;
    notifyListeners();
    return false;
  }

  Future<ParcelProofUploadResponse> uploadProofPhoto({
    required File file,
    required String proofType,
  }) async {
    if (_activeOrder == null) {
      return ParcelProofUploadResponse(
        success: false,
        message: 'No active parcel order',
      );
    }

    if (_isUploadingProof) {
      return ParcelProofUploadResponse(
        success: false,
        message: 'Proof upload already in progress',
      );
    }

    _isUploadingProof = true;
    notifyListeners();

    try {
      return await _service.uploadProofPhoto(
        orderId: _activeOrder!.id,
        proofType: proofType,
        file: file,
      );
    } finally {
      _isUploadingProof = false;
      notifyListeners();
    }
  }

  /// Cancel the active parcel delivery
  Future<bool> cancelDelivery({String? reason}) async {
    if (_activeOrder == null) return false;

    _isLoading = true;
    notifyListeners();

    final response =
        await _service.cancelDelivery(_activeOrder!.id, reason: reason);
    _isLoading = false;

    if (response.success) {
      _activeOrder = null;
      _hasActiveParcelOrder = false;
      _activeParcelOrderId = null;
      _stopPolling();
      notifyListeners();
      return true;
    }

    _error = response.message;
    notifyListeners();
    return false;
  }

  /// Mark delivery as complete (after delivered status)
  void completeDelivery() {
    _activeOrder = null;
    _hasActiveParcelOrder = false;
    _activeParcelOrderId = null;
    _stopPolling();
    notifyListeners();
  }

  /// Poll active order for status updates
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshActiveOrder();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _refreshActiveOrder() async {
    if (_activeOrder == null) return;
    final order = await _service.getOrderDetails(_activeOrder!.id);
    if (order != null) {
      _activeOrder = order;
      // If order was cancelled by customer, stop polling
      if (order.status == 'cancelled' || order.status == 'delivered') {
        _hasActiveParcelOrder = false;
        _activeParcelOrderId = null;
        _stopPolling();
      }
      notifyListeners();
    }
  }

  /// Check for existing active parcel order on app start
  Future<void> checkExistingOrder({double? lat, double? lng}) async {
    await fetchAvailableOrders(lat: lat, lng: lng, force: true);
    if (_hasActiveParcelOrder && _activeParcelOrderId != null) {
      await _fetchActiveOrderDetails(_activeParcelOrderId!);
      if (_activeOrder != null) {
        _startPolling();
      }
      notifyListeners();
    }
  }

  /// Clear state
  void clear() {
    _stopPolling();
    _availableOrders = [];
    _activeOrder = null;
    _hasInitialFetch = false;
    _hasActiveParcelOrder = false;
    _activeParcelOrderId = null;
    _lastAvailableOrdersFetchAt = null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
