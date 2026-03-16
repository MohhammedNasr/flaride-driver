import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flaride_driver/core/models/trip.dart';
import 'package:flaride_driver/core/services/dispatch_service.dart';
import 'package:flaride_driver/core/services/realtime_service.dart';

enum DriverRideState {
  idle,
  hasOffer,
  enRouteToPickup,
  waitingAtPickup,
  inProgress,
  completed,
}

class DriverRideProvider extends ChangeNotifier {
  final DispatchService _dispatchService = DispatchService();
  final RealtimeService _realtime = RealtimeService();

  // ── State ──────────────────────────────────────────────────────────
  DriverRideState _state = DriverRideState.idle;
  RideOffer? _currentOffer;
  DriverTrip? _activeTrip;
  bool _hasPreAssigned = false;
  String? _preAssignedTripId;
  Timer? _offerPollTimer;
  Timer? _tripPollTimer;
  StreamSubscription? _offerRealtimeSub;
  StreamSubscription? _tripRealtimeSub;
  String? _driverId;

  // ── Getters ────────────────────────────────────────────────────────
  DriverRideState get state => _state;
  RideOffer? get currentOffer => _currentOffer;
  DriverTrip? get activeTrip => _activeTrip;
  bool get hasPreAssigned => _hasPreAssigned;
  bool get hasOffer => _currentOffer != null;
  bool get hasActiveTrip => _activeTrip != null;

  // ── 1. Start Polling for Offers (when driver is online & idle) ─────

  void startOfferPolling({String? driverId}) {
    stopOfferPolling();

    // Store driver ID for subsequent internal calls
    if (driverId != null) _driverId = driverId;

    // Subscribe to realtime offer channel
    if (_driverId != null) {
      _realtime.subscribeToOffers(_driverId!);
      _offerRealtimeSub?.cancel();
      _offerRealtimeSub = _realtime.onNewOffer.listen((_) {
        // Realtime ping → immediately poll for full offer data
        _pollForOffer();
      });
    }

    _pollForOffer();
    // Fallback polling at 15s (realtime is primary)
    _offerPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _pollForOffer();
    });
  }

  void stopOfferPolling() {
    _offerPollTimer?.cancel();
    _offerPollTimer = null;
    _offerRealtimeSub?.cancel();
    _offerRealtimeSub = null;
    _realtime.unsubscribeOffers();
  }

  Future<void> _pollForOffer() async {
    try {
      final response = await _dispatchService.getCurrentOffer();
      if (response.hasOffer && response.offer != null) {
        if (_currentOffer?.id != response.offer!.id) {
          _currentOffer = response.offer;
          _state = DriverRideState.hasOffer;
          notifyListeners();
        }
      } else if (_state == DriverRideState.hasOffer) {
        // Offer disappeared (expired or handled elsewhere)
        _currentOffer = null;
        _state = DriverRideState.idle;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Offer poll error: $e');
    }
  }

  // ── 2. Accept / Reject Offer ───────────────────────────────────────

  Future<OfferActionResult> acceptOffer() async {
    if (_currentOffer == null) {
      return OfferActionResult(success: false, errorMessage: 'No offer');
    }

    final result = await _dispatchService.respondToOffer(
      offerId: _currentOffer!.id,
      action: 'accept',
    );

    if (result.success) {
      stopOfferPolling();
      _currentOffer = null;
      // Start trip polling
      _startTripPolling();
    }

    return result;
  }

  Future<OfferActionResult> rejectOffer({String? reason}) async {
    if (_currentOffer == null) {
      return OfferActionResult(success: false, errorMessage: 'No offer');
    }

    final result = await _dispatchService.respondToOffer(
      offerId: _currentOffer!.id,
      action: 'reject',
      rejectionReason: reason,
    );

    if (result.success) {
      _currentOffer = null;
      _state = DriverRideState.idle;
      notifyListeners();
    }

    return result;
  }

  // ── 3. Trip Polling (silent background refresh) ────────────────────

  void _startTripPolling() {
    _stopTripPolling();

    // Subscribe to realtime trip channel
    if (_activeTrip != null) {
      _realtime.subscribeToTrip(_activeTrip!.id);
      _tripRealtimeSub?.cancel();
      _tripRealtimeSub = _realtime.onTripUpdate.listen((payload) {
        // Realtime event → immediately poll for full trip data
        _pollCurrentTrip();
      });
    }

    _pollCurrentTrip();
    // Fallback polling at 15s (realtime is primary)
    _tripPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _pollCurrentTrip();
    });
  }

  void _stopTripPolling() {
    _tripPollTimer?.cancel();
    _tripPollTimer = null;
    _tripRealtimeSub?.cancel();
    _tripRealtimeSub = null;
    _realtime.unsubscribeTrip();
  }

  Future<void> _pollCurrentTrip() async {
    try {
      final response = await _dispatchService.getCurrentTrip();

      if (response.hasActiveTrip && response.trip != null) {
        _activeTrip = response.trip;
        _hasPreAssigned = response.hasPreAssigned;
        _preAssignedTripId = response.preAssignedTripId;
        _updateStateFromTrip(response.trip!);
        notifyListeners();
      } else if (_activeTrip != null) {
        // Trip ended
        _activeTrip = null;
        _hasPreAssigned = response.hasPreAssigned;
        _preAssignedTripId = response.preAssignedTripId;
        _state = DriverRideState.idle;
        _stopTripPolling();
        startOfferPolling(); // Resume listening for new offers
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Trip poll error: $e');
    }
  }

  void _updateStateFromTrip(DriverTrip trip) {
    switch (trip.status) {
      case 'driver_arriving':
      case 'accepted':
        _state = DriverRideState.enRouteToPickup;
        break;
      case 'arrived_at_pickup':
        _state = DriverRideState.waitingAtPickup;
        break;
      case 'in_progress':
        _state = DriverRideState.inProgress;
        break;
      case 'completed':
        _state = DriverRideState.completed;
        _stopTripPolling();
        break;
      default:
        break;
    }
  }

  // ── 4. Trip Actions ────────────────────────────────────────────────

  Future<ActionResult> markArrived() async {
    if (_activeTrip == null) return ActionResult(success: false, errorMessage: 'No trip');
    return await _dispatchService.markArrived(_activeTrip!.id);
  }

  Future<ActionResult> startRide() async {
    if (_activeTrip == null) return ActionResult(success: false, errorMessage: 'No trip');
    return await _dispatchService.startRide(_activeTrip!.id);
  }

  Future<TripCompleteResult> completeRide({double? actualDistanceKm, double? actualDurationMin}) async {
    if (_activeTrip == null) return TripCompleteResult(success: false, errorMessage: 'No trip');
    final result = await _dispatchService.completeRide(
      _activeTrip!.id,
      actualDistanceKm: actualDistanceKm,
      actualDurationMin: actualDurationMin,
    );
    if (result.success) {
      _state = DriverRideState.completed;
      _stopTripPolling();
      notifyListeners();
    }
    return result;
  }

  Future<ActionResult> cancelRide({String? reason}) async {
    if (_activeTrip == null) return ActionResult(success: false, errorMessage: 'No trip');
    final result = await _dispatchService.cancelRide(_activeTrip!.id, reason: reason);
    if (result.success) {
      _activeTrip = null;
      _state = DriverRideState.idle;
      _stopTripPolling();
      startOfferPolling();
      notifyListeners();
    }
    return result;
  }

  Future<ActionResult> reportNoShow({
    required DateTime waitStartedAt,
    required int callsMade,
    required int smsSent,
    required int waitDurationSec,
  }) async {
    if (_activeTrip == null) return ActionResult(success: false, errorMessage: 'No trip');
    return await _dispatchService.reportNoShow(
      tripId: _activeTrip!.id,
      waitStartedAt: waitStartedAt,
      callsMade: callsMade,
      smsSent: smsSent,
      waitDurationSec: waitDurationSec,
    );
  }

  // ── 5. GPS Tracking ────────────────────────────────────────────────

  Future<void> sendLocation({
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
  }) async {
    await _dispatchService.sendLocation(
      tripId: _activeTrip?.id,
      latitude: latitude,
      longitude: longitude,
      speed: speed,
      heading: heading,
      accuracy: accuracy,
    );
  }

  // ── 6. Check for existing trip on app start ────────────────────────

  Future<void> checkExistingTrip() async {
    final response = await _dispatchService.getCurrentTrip();
    if (response.hasActiveTrip && response.trip != null) {
      _activeTrip = response.trip;
      _hasPreAssigned = response.hasPreAssigned;
      _preAssignedTripId = response.preAssignedTripId;
      _updateStateFromTrip(response.trip!);
      _startTripPolling();
      notifyListeners();
    } else {
      // No active trip — start listening for offers
      startOfferPolling();
    }
  }

  // ── 7. Reset ───────────────────────────────────────────────────────

  void resetToIdle() {
    _state = DriverRideState.idle;
    _activeTrip = null;
    _currentOffer = null;
    notifyListeners();
    startOfferPolling();
  }

  // ── Cleanup ────────────────────────────────────────────────────────

  @override
  void dispose() {
    stopOfferPolling();
    _stopTripPolling();
    _realtime.dispose();
    super.dispose();
  }
}
