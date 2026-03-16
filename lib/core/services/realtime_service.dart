import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Realtime service for ride-hailing using Supabase Broadcast channels.
///
/// Channels:
///   driver-offers:<driver_id> — new ride offers pushed from backend
///   trip:<trip_id>            — trip status + driver location updates
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeChannel? _offerChannel;
  RealtimeChannel? _tripChannel;

  String? _currentDriverId;
  String? _currentTripId;
  int _offerErrorCount = 0;
  int _tripErrorCount = 0;
  static const int _maxRetries = 3;

  // ── Stream controllers ─────────────────────────────────────────────

  final _newOfferController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripUpdateController = StreamController<Map<String, dynamic>>.broadcast();

  /// Emits when backend sends a new ride offer to this driver
  Stream<Map<String, dynamic>> get onNewOffer => _newOfferController.stream;

  /// Emits when trip status changes (accepted, arrived, in_progress, completed, cancelled)
  Stream<Map<String, dynamic>> get onTripUpdate => _tripUpdateController.stream;

  // ── Offer channel ──────────────────────────────────────────────────

  /// Subscribe to ride offers for this driver.
  /// Call once when driver goes online.
  void subscribeToOffers(String driverId) {
    if (_currentDriverId == driverId && _offerChannel != null) return;

    unsubscribeOffers();
    _currentDriverId = driverId;

    final channelName = 'driver-offers:$driverId';
    _offerChannel = _supabase.channel(channelName);

    _offerChannel!
        .onBroadcast(
          event: 'new_offer',
          callback: (payload) {
            debugPrint('Realtime: new offer → $payload');
            _newOfferController.add(Map<String, dynamic>.from(payload));
          },
        )
        .subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        _offerErrorCount++;
        debugPrint('Realtime offer channel ($channelName): $status (attempt $_offerErrorCount/$_maxRetries)');
        if (_offerErrorCount >= _maxRetries) {
          debugPrint('Realtime offers: max retries reached, unsubscribing. Polling continues as fallback.');
          unsubscribeOffers();
          _currentDriverId = driverId;
        }
      } else if (status == RealtimeSubscribeStatus.subscribed) {
        _offerErrorCount = 0;
        debugPrint('Realtime offer channel ($channelName): subscribed');
      }
    });
  }

  void unsubscribeOffers() {
    if (_offerChannel != null) {
      _supabase.removeChannel(_offerChannel!);
      _offerChannel = null;
    }
  }

  // ── Trip channel ───────────────────────────────────────────────────

  /// Subscribe to updates for a specific trip (status changes).
  /// Call when driver accepts an offer / has active trip.
  void subscribeToTrip(String tripId) {
    if (_currentTripId == tripId && _tripChannel != null) return;

    unsubscribeTrip();
    _currentTripId = tripId;

    final channelName = 'trip:$tripId';
    _tripChannel = _supabase.channel(channelName);

    _tripChannel!
        .onBroadcast(
          event: 'trip_update',
          callback: (payload) {
            debugPrint('Realtime: trip update → $payload');
            _tripUpdateController.add(Map<String, dynamic>.from(payload));
          },
        )
        .subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        _tripErrorCount++;
        debugPrint('Realtime trip channel ($channelName): $status (attempt $_tripErrorCount/$_maxRetries)');
        if (_tripErrorCount >= _maxRetries) {
          debugPrint('Realtime trip: max retries reached, unsubscribing. Polling continues as fallback.');
          unsubscribeTrip();
          _currentTripId = tripId;
        }
      } else if (status == RealtimeSubscribeStatus.subscribed) {
        _tripErrorCount = 0;
        debugPrint('Realtime trip channel ($channelName): subscribed');
      }
    });
  }

  void unsubscribeTrip() {
    if (_tripChannel != null) {
      _supabase.removeChannel(_tripChannel!);
      _tripChannel = null;
      _currentTripId = null;
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────

  void dispose() {
    unsubscribeOffers();
    unsubscribeTrip();
    _newOfferController.close();
    _tripUpdateController.close();
    _currentDriverId = null;
    debugPrint('RealtimeService: disposed');
  }

  void pause() {
    unsubscribeOffers();
    unsubscribeTrip();
    debugPrint('RealtimeService: paused');
  }

  Future<void> resume() async {
    if (_currentDriverId != null) subscribeToOffers(_currentDriverId!);
    if (_currentTripId != null) subscribeToTrip(_currentTripId!);
    debugPrint('RealtimeService: resumed');
  }
}
