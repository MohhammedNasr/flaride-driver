// Models for parcel orders as seen by the driver app.

class ParcelSecurityRequirements {
  final bool requirePickupPhoto;
  final bool requireDropoffPhoto;
  final bool requireDropoffOtp;
  final int minPickupPhotos;
  final int minDropoffPhotos;
  final String pickupPhotoInstructions;
  final String dropoffPhotoInstructions;

  const ParcelSecurityRequirements({
    this.requirePickupPhoto = true,
    this.requireDropoffPhoto = true,
    this.requireDropoffOtp = false,
    this.minPickupPhotos = 1,
    this.minDropoffPhotos = 1,
    this.pickupPhotoInstructions =
        'Take a clear pickup photo showing the full parcel, visible hand-off context, good lighting, and no blur.',
    this.dropoffPhotoInstructions =
        'Take a clear drop-off photo showing the delivered parcel at destination (or with recipient), visible surroundings, and no blur.',
  });

  factory ParcelSecurityRequirements.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ParcelSecurityRequirements();
    return ParcelSecurityRequirements(
      requirePickupPhoto: json['require_pickup_photo'] != false,
      requireDropoffPhoto: json['require_dropoff_photo'] != false,
      requireDropoffOtp: json['require_dropoff_otp'] == true,
      minPickupPhotos:
          ((json['min_pickup_photos'] as num?)?.toInt() ?? 1).clamp(1, 10),
      minDropoffPhotos:
          ((json['min_dropoff_photos'] as num?)?.toInt() ?? 1).clamp(1, 10),
      pickupPhotoInstructions: json['pickup_photo_instructions']?.toString() ??
          json['pickup_photo_instructions_en']?.toString() ??
          const ParcelSecurityRequirements().pickupPhotoInstructions,
      dropoffPhotoInstructions:
          json['dropoff_photo_instructions']?.toString() ??
              json['dropoff_photo_instructions_en']?.toString() ??
              const ParcelSecurityRequirements().dropoffPhotoInstructions,
    );
  }
}

class AvailableParcelOrder {
  final String id;
  final String orderType; // always 'parcel_delivery'
  final String status;
  final DateTime? createdAt;
  final String packageSize;
  final String? packageDescription;
  final int quantity;
  final bool isFragile;
  final String deliverySpeed;
  final int totalAmount;
  final String totalAmountDisplay;
  final String estimatedEarnings;
  final String currencyCode;
  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String? pickupContactName;
  final String? pickupContactPhone;
  final String? dropoffAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? dropoffContactName;
  final String? dropoffContactPhone;
  final String? pickupDistanceKm;
  final String? deliveryDistanceKm;
  final double? distanceKm;
  final int? estimatedDurationMin;
  final String? customerName;
  final ParcelCategory? category;
  final String? paymentMethod;
  final double tipAmount;
  final String? specialInstructions;
  final List<String> packagePhotos;
  final ParcelSecurityRequirements securityRequirements;

  AvailableParcelOrder({
    required this.id,
    this.orderType = 'parcel_delivery',
    required this.status,
    this.createdAt,
    required this.packageSize,
    this.packageDescription,
    this.quantity = 1,
    this.isFragile = false,
    this.deliverySpeed = 'standard',
    required this.totalAmount,
    required this.totalAmountDisplay,
    required this.estimatedEarnings,
    this.currencyCode = 'XOF',
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.pickupContactName,
    this.pickupContactPhone,
    this.dropoffAddress,
    this.dropoffLat,
    this.dropoffLng,
    this.dropoffContactName,
    this.dropoffContactPhone,
    this.pickupDistanceKm,
    this.deliveryDistanceKm,
    this.distanceKm,
    this.estimatedDurationMin,
    this.customerName,
    this.category,
    this.paymentMethod,
    this.tipAmount = 0,
    this.specialInstructions,
    this.packagePhotos = const [],
    this.securityRequirements = const ParcelSecurityRequirements(),
  });

  factory AvailableParcelOrder.fromJson(Map<String, dynamic> json) {
    return AvailableParcelOrder(
      id: json['id'] ?? '',
      orderType: json['order_type'] ?? 'parcel_delivery',
      status: json['status'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      packageSize: json['package_size'] ?? 'Package',
      packageDescription: json['package_description'],
      quantity: json['quantity'] ?? 1,
      isFragile: json['is_fragile'] ?? false,
      deliverySpeed: json['delivery_speed'] ?? 'standard',
      totalAmount: json['total_amount'] ?? 0,
      totalAmountDisplay: json['total_amount_display'] ?? 'XOF0',
      estimatedEarnings: json['estimated_earnings'] ?? 'XOF0',
      currencyCode: json['currency_code'] ?? 'XOF',
      pickupAddress: json['pickup_address'],
      pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
      pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
      pickupContactName: json['pickup_contact_name'],
      pickupContactPhone: json['pickup_contact_phone'],
      dropoffAddress: json['dropoff_address'],
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble(),
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble(),
      dropoffContactName: json['dropoff_contact_name'],
      dropoffContactPhone: json['dropoff_contact_phone'],
      pickupDistanceKm: json['pickup_distance_km']?.toString(),
      deliveryDistanceKm: json['delivery_distance_km']?.toString(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      estimatedDurationMin: json['estimated_duration_min'],
      customerName: json['customer_name'],
      category: json['category'] != null
          ? ParcelCategory.fromJson(json['category'])
          : null,
      paymentMethod: json['payment_method'],
      tipAmount: (json['tip_amount'] as num?)?.toDouble() ?? 0,
      specialInstructions: json['special_instructions'],
      packagePhotos: (json['package_photos'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      securityRequirements: ParcelSecurityRequirements.fromJson(
          json['security_requirements'] as Map<String, dynamic>?),
    );
  }

  bool get isActive => [
        'driver_assigned',
        'driver_en_route_pickup',
        'at_pickup',
        'picked_up',
        'in_transit',
        'at_dropoff',
      ].contains(status);
}

class ParcelCategory {
  final String? id;
  final String name;
  final String? nameFr;
  final String? icon;
  final double? minWeight;
  final double? maxWeight;

  ParcelCategory({
    this.id,
    required this.name,
    this.nameFr,
    this.icon,
    this.minWeight,
    this.maxWeight,
  });

  factory ParcelCategory.fromJson(Map<String, dynamic> json) {
    return ParcelCategory(
      id: json['id'],
      name: json['name'] ?? json['display_name_en'] ?? '',
      nameFr: json['name_fr'] ?? json['display_name_fr'],
      icon: json['icon'] ?? json['icon_name'],
      minWeight: (json['min_weight'] as num?)?.toDouble() ??
          (json['min_weight_kg'] as num?)?.toDouble(),
      maxWeight: (json['max_weight'] as num?)?.toDouble() ??
          (json['max_weight_kg'] as num?)?.toDouble(),
    );
  }
}

/// Full parcel order details (after driver accepts)
class ActiveParcelOrder {
  final String id;
  final String status;
  final DateTime? createdAt;
  final String packageSize;
  final String? packageDescription;
  final int quantity;
  final bool isFragile;
  final String deliverySpeed;
  final int totalAmount;
  final String currencyCode;
  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String? pickupContactName;
  final String? pickupContactPhone;
  final String? dropoffAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? dropoffContactName;
  final String? dropoffContactPhone;
  final double? distanceKm;
  final int? estimatedDurationMin;
  final String? paymentMethod;
  final double tipAmount;
  final String? specialInstructions;
  final List<String> packagePhotos;
  final ParcelCustomerInfo? customer;
  final ParcelCategory? category;
  // Timestamps
  final DateTime? driverAssignedAt;
  final DateTime? driverEnRouteAt;
  final DateTime? arrivedPickupAt;
  final DateTime? pickedUpAt;
  final DateTime? inTransitAt;
  final DateTime? arrivedDropoffAt;
  final DateTime? deliveredAt;
  // Fare breakdown
  final int baseFare;
  final int distanceFare;
  final int extrasFare;
  final int speedSurcharge;
  final int subtotal;
  final int promoDiscount;
  final ParcelSecurityRequirements securityRequirements;
  final String? pickupProofPhoto;
  final String? pickupProofMimeType;
  final int? pickupProofSizeBytes;
  final DateTime? pickupProofTakenAt;
  final double? pickupProofTakenLat;
  final double? pickupProofTakenLng;
  final String? dropoffProofPhoto;
  final String? dropoffProofMimeType;
  final int? dropoffProofSizeBytes;
  final DateTime? dropoffProofTakenAt;
  final double? dropoffProofTakenLat;
  final double? dropoffProofTakenLng;

  ActiveParcelOrder({
    required this.id,
    required this.status,
    this.createdAt,
    required this.packageSize,
    this.packageDescription,
    this.quantity = 1,
    this.isFragile = false,
    this.deliverySpeed = 'standard',
    required this.totalAmount,
    this.currencyCode = 'XOF',
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.pickupContactName,
    this.pickupContactPhone,
    this.dropoffAddress,
    this.dropoffLat,
    this.dropoffLng,
    this.dropoffContactName,
    this.dropoffContactPhone,
    this.distanceKm,
    this.estimatedDurationMin,
    this.paymentMethod,
    this.tipAmount = 0,
    this.specialInstructions,
    this.packagePhotos = const [],
    this.customer,
    this.category,
    this.driverAssignedAt,
    this.driverEnRouteAt,
    this.arrivedPickupAt,
    this.pickedUpAt,
    this.inTransitAt,
    this.arrivedDropoffAt,
    this.deliveredAt,
    this.baseFare = 0,
    this.distanceFare = 0,
    this.extrasFare = 0,
    this.speedSurcharge = 0,
    this.subtotal = 0,
    this.promoDiscount = 0,
    this.securityRequirements = const ParcelSecurityRequirements(),
    this.pickupProofPhoto,
    this.pickupProofMimeType,
    this.pickupProofSizeBytes,
    this.pickupProofTakenAt,
    this.pickupProofTakenLat,
    this.pickupProofTakenLng,
    this.dropoffProofPhoto,
    this.dropoffProofMimeType,
    this.dropoffProofSizeBytes,
    this.dropoffProofTakenAt,
    this.dropoffProofTakenLat,
    this.dropoffProofTakenLng,
  });

  factory ActiveParcelOrder.fromJson(Map<String, dynamic> json) {
    return ActiveParcelOrder(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      packageSize: json['package_size'] ??
          json['parcel_categories']?['display_name_en'] ??
          'Package',
      packageDescription: json['package_description'],
      quantity: json['quantity'] ?? 1,
      isFragile: json['is_fragile'] ?? false,
      deliverySpeed: json['delivery_speed'] ?? 'standard',
      totalAmount: json['total_amount'] ?? 0,
      currencyCode: json['currency_code'] ?? 'XOF',
      pickupAddress: json['pickup_address'],
      pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
      pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
      pickupContactName: json['pickup_contact_name'],
      pickupContactPhone: json['pickup_contact_phone'],
      dropoffAddress: json['dropoff_address'],
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble(),
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble(),
      dropoffContactName: json['dropoff_contact_name'],
      dropoffContactPhone: json['dropoff_contact_phone'],
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      estimatedDurationMin: json['estimated_duration_min'],
      paymentMethod: json['payment_method'],
      tipAmount: (json['tip_amount'] as num?)?.toDouble() ?? 0,
      specialInstructions: json['special_instructions'],
      packagePhotos: (json['package_photos'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      customer: json['customer'] != null
          ? ParcelCustomerInfo.fromJson(json['customer'])
          : null,
      category: json['parcel_categories'] != null
          ? ParcelCategory.fromJson(json['parcel_categories'])
          : (json['category'] != null
              ? ParcelCategory.fromJson(json['category'])
              : null),
      driverAssignedAt: json['driver_assigned_at'] != null
          ? DateTime.tryParse(json['driver_assigned_at'])
          : null,
      driverEnRouteAt: json['driver_en_route_at'] != null
          ? DateTime.tryParse(json['driver_en_route_at'])
          : null,
      arrivedPickupAt: json['arrived_pickup_at'] != null
          ? DateTime.tryParse(json['arrived_pickup_at'])
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.tryParse(json['picked_up_at'])
          : null,
      inTransitAt: json['in_transit_at'] != null
          ? DateTime.tryParse(json['in_transit_at'])
          : null,
      arrivedDropoffAt: json['arrived_dropoff_at'] != null
          ? DateTime.tryParse(json['arrived_dropoff_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'])
          : null,
      baseFare: json['base_fare'] ?? 0,
      distanceFare: json['distance_fare'] ?? 0,
      extrasFare: json['extras_fare'] ?? 0,
      speedSurcharge: json['speed_surcharge'] ?? 0,
      subtotal: json['subtotal'] ?? 0,
      promoDiscount: json['promo_discount'] ?? 0,
      securityRequirements: ParcelSecurityRequirements.fromJson(
          json['security_requirements'] as Map<String, dynamic>?),
      pickupProofPhoto: json['pickup_proof_photo'],
      pickupProofMimeType: json['pickup_proof_mime_type'],
      pickupProofSizeBytes: (json['pickup_proof_size_bytes'] as num?)?.toInt(),
      pickupProofTakenAt: json['pickup_proof_taken_at'] != null
          ? DateTime.tryParse(json['pickup_proof_taken_at'])
          : null,
      pickupProofTakenLat: (json['pickup_proof_taken_lat'] as num?)?.toDouble(),
      pickupProofTakenLng: (json['pickup_proof_taken_lng'] as num?)?.toDouble(),
      dropoffProofPhoto: json['dropoff_proof_photo'],
      dropoffProofMimeType: json['dropoff_proof_mime_type'],
      dropoffProofSizeBytes:
          (json['dropoff_proof_size_bytes'] as num?)?.toInt(),
      dropoffProofTakenAt: json['dropoff_proof_taken_at'] != null
          ? DateTime.tryParse(json['dropoff_proof_taken_at'])
          : null,
      dropoffProofTakenLat:
          (json['dropoff_proof_taken_lat'] as num?)?.toDouble(),
      dropoffProofTakenLng:
          (json['dropoff_proof_taken_lng'] as num?)?.toDouble(),
    );
  }

  bool get isActive => [
        'driver_assigned',
        'driver_en_route_pickup',
        'at_pickup',
        'picked_up',
        'in_transit',
        'at_dropoff',
      ].contains(status);

  bool get canCancel => [
        'driver_assigned',
        'driver_en_route_pickup',
        'at_pickup',
      ].contains(status);

  String get driverEarningsDisplay {
    final earnings = (totalAmount * 0.8).round();
    return '$earnings $currencyCode';
  }

  bool get hasPickupProof => (pickupProofPhoto ?? '').isNotEmpty;
  bool get hasDropoffProof => (dropoffProofPhoto ?? '').isNotEmpty;
}

class ParcelCustomerInfo {
  final String? id;
  final String? name;
  final String? phone;
  final String? profilePicture;

  ParcelCustomerInfo({this.id, this.name, this.phone, this.profilePicture});

  factory ParcelCustomerInfo.fromJson(Map<String, dynamic> json) {
    return ParcelCustomerInfo(
      id: json['id'],
      name: json['name'] ?? json['full_name'] ?? json['fullname'],
      phone: json['phone'] ?? json['phone_number'],
      profilePicture: json['profile_picture'] ??
          json['profile_image_url'] ??
          json['profile_picture_url'],
    );
  }
}
