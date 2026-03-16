class DriverTrip {
  final String id;
  final String? passengerId;
  final String? driverId;
  final String status;
  final String bookingSource;
  final String rideCategory;
  final double pickupLat;
  final double pickupLng;
  final String? pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String? dropoffAddress;
  final double? estimatedDistanceKm;
  final double? estimatedDurationMin;
  final int? estimatedFare;
  final int? actualFare;
  final String paymentMethod;
  final String currency;
  final int? pickupEtaSec;
  final DateTime? driverArrivedAt;
  final DateTime? rideStartedAt;
  final DateTime? rideCompletedAt;
  final int passengerSurcharge;
  final int totalBonus;
  final bool showPhoneBookingIcon;
  final String? passengerPhone;
  final String? passengerName;
  final TripPassenger? passenger;
  final DateTime createdAt;

  DriverTrip({
    required this.id,
    this.passengerId,
    this.driverId,
    required this.status,
    this.bookingSource = 'app',
    required this.rideCategory,
    required this.pickupLat,
    required this.pickupLng,
    this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    this.dropoffAddress,
    this.estimatedDistanceKm,
    this.estimatedDurationMin,
    this.estimatedFare,
    this.actualFare,
    this.paymentMethod = 'cash',
    this.currency = 'XOF',
    this.pickupEtaSec,
    this.driverArrivedAt,
    this.rideStartedAt,
    this.rideCompletedAt,
    this.passengerSurcharge = 0,
    this.totalBonus = 0,
    this.showPhoneBookingIcon = false,
    this.passengerPhone,
    this.passengerName,
    this.passenger,
    required this.createdAt,
  });

  factory DriverTrip.fromJson(Map<String, dynamic> json) {
    return DriverTrip(
      id: json['id'] ?? '',
      passengerId: json['passenger_id'],
      driverId: json['driver_id'],
      status: json['status'] ?? 'pending',
      bookingSource: json['booking_source'] ?? 'app',
      rideCategory: json['ride_category'] ?? 'economy',
      pickupLat: _toDouble(json['pickup_lat']),
      pickupLng: _toDouble(json['pickup_lng']),
      pickupAddress: json['pickup_address'],
      dropoffLat: _toDouble(json['dropoff_lat']),
      dropoffLng: _toDouble(json['dropoff_lng']),
      dropoffAddress: json['dropoff_address'],
      estimatedDistanceKm: _toDoubleNullable(json['estimated_distance_km']),
      estimatedDurationMin: _toDoubleNullable(json['estimated_duration_min']),
      estimatedFare: json['estimated_fare'],
      actualFare: json['actual_fare'],
      paymentMethod: json['payment_method'] ?? 'cash',
      currency: json['currency'] ?? 'XOF',
      pickupEtaSec: json['pickup_eta_sec'],
      driverArrivedAt: _parseDate(json['driver_arrived_at']),
      rideStartedAt: _parseDate(json['ride_started_at']),
      rideCompletedAt: _parseDate(json['ride_completed_at']),
      passengerSurcharge: json['passenger_surcharge'] ?? 0,
      totalBonus: json['total_bonus'] ?? 0,
      showPhoneBookingIcon: json['show_phone_booking_icon'] ?? false,
      passengerPhone: json['passenger_phone'],
      passengerName: json['passenger_name'],
      passenger: json['passenger'] != null ? TripPassenger.fromJson(json['passenger']) : null,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  bool get isPhoneBooking => bookingSource == 'admin_manual';
  bool get isEnRoute => status == 'driver_arriving';
  bool get isWaiting => status == 'arrived_at_pickup';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  int get displayFare => actualFare ?? estimatedFare ?? 0;
  String get displayFareCFA => formatCurrency(displayFare, currency);

  static String currencySymbol(String code) {
    switch (code) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'XOF': return 'FCFA';
      case 'XAF': return 'FCFA';
      case 'MAD': return 'MAD';
      case 'TND': return 'DT';
      default: return code;
    }
  }

  static String formatCurrency(int centimes, String code) {
    final sym = currencySymbol(code);
    if (code == 'XOF' || code == 'XAF') {
      return '${(centimes / 100).toStringAsFixed(0)} $sym';
    }
    return '$sym${(centimes / 100).toStringAsFixed(2)}';
  }

  static double _toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;
  static double? _toDoubleNullable(dynamic v) => v == null ? null : _toDouble(v);
  static DateTime? _parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
}

class TripPassenger {
  final String? id;
  final String firstName;
  final String? photoUrl;
  final double rating;
  final String? phone;
  final String? name;

  TripPassenger({
    this.id,
    required this.firstName,
    this.photoUrl,
    this.rating = 5.0,
    this.phone,
    this.name,
  });

  factory TripPassenger.fromJson(Map<String, dynamic> json) {
    return TripPassenger(
      id: json['id'],
      firstName: json['first_name'] ?? 'Passenger',
      photoUrl: json['photo_url'],
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      phone: json['phone'],
      name: json['name'],
    );
  }
}

class RideOffer {
  final String id;
  final String tripId;
  final DateTime expiresAt;
  final int? etaToPickupSec;
  final bool isPreAssignment;
  final OfferLocation pickup;
  final OfferLocation dropoff;
  final double? estimatedDistanceKm;
  final double? estimatedDurationMin;
  final int? estimatedFare;
  final String rideCategory;
  final String paymentMethod;
  final bool isPhoneBooking;
  final String currency;
  final double passengerRating;

  RideOffer({
    required this.id,
    required this.tripId,
    required this.expiresAt,
    this.etaToPickupSec,
    this.isPreAssignment = false,
    required this.pickup,
    required this.dropoff,
    this.estimatedDistanceKm,
    this.estimatedDurationMin,
    this.estimatedFare,
    required this.rideCategory,
    this.paymentMethod = 'cash',
    this.isPhoneBooking = false,
    this.currency = 'XOF',
    this.passengerRating = 5.0,
  });

  factory RideOffer.fromJson(Map<String, dynamic> json) {
    return RideOffer(
      id: json['id'] ?? '',
      tripId: json['trip_id'] ?? '',
      expiresAt: DateTime.tryParse(json['expires_at'] ?? '') ?? DateTime.now().add(const Duration(seconds: 30)),
      etaToPickupSec: json['eta_to_pickup_sec'],
      isPreAssignment: json['is_pre_assignment'] ?? false,
      pickup: OfferLocation.fromJson(json['pickup'] ?? {}),
      dropoff: OfferLocation.fromJson(json['dropoff'] ?? {}),
      estimatedDistanceKm: (json['estimated_distance_km'] as num?)?.toDouble(),
      estimatedDurationMin: (json['estimated_duration_min'] as num?)?.toDouble(),
      estimatedFare: json['estimated_fare'],
      rideCategory: json['ride_category'] ?? 'economy',
      paymentMethod: json['payment_method'] ?? 'cash',
      isPhoneBooking: json['is_phone_booking'] ?? false,
      currency: json['currency'] ?? 'XOF',
      passengerRating: (json['passenger_rating'] as num?)?.toDouble() ?? 5.0,
    );
  }

  String get displayFare => estimatedFare != null ? DriverTrip.formatCurrency(estimatedFare!, currency) : '--';
  String get displayEta => etaToPickupSec != null ? '${(etaToPickupSec! / 60).ceil()} min' : '--';
  String get displayDistance => estimatedDistanceKm != null ? '${estimatedDistanceKm!.toStringAsFixed(1)} km' : '--';

  Duration get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class OfferLocation {
  final double? lat;
  final double? lng;
  final String? address;

  OfferLocation({this.lat, this.lng, this.address});

  factory OfferLocation.fromJson(Map<String, dynamic> json) {
    return OfferLocation(
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      address: json['address'],
    );
  }
}

class TripCompleteResult {
  final bool success;
  final int actualFare;
  final int driverEarnings;
  final int bonusTotal;
  final List<BonusItem> bonuses;
  final String? errorMessage;
  final String currency;

  TripCompleteResult({
    required this.success,
    this.actualFare = 0,
    this.driverEarnings = 0,
    this.bonusTotal = 0,
    this.bonuses = const [],
    this.errorMessage,
    this.currency = 'XOF',
  });

  String get displayFare => DriverTrip.formatCurrency(actualFare, currency);
  String get displayEarnings => DriverTrip.formatCurrency(driverEarnings, currency);
  String get displayBonus => DriverTrip.formatCurrency(bonusTotal, currency);
}

class BonusItem {
  final String type;
  final int amount;
  final String description;

  BonusItem({required this.type, required this.amount, required this.description});

  factory BonusItem.fromJson(Map<String, dynamic> json) {
    return BonusItem(
      type: json['type'] ?? '',
      amount: json['amount'] ?? 0,
      description: json['description'] ?? '',
    );
  }

  String get displayAmount => '+${(amount / 100).toStringAsFixed(0)}';
}
