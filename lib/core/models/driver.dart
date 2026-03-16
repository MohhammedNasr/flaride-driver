class Driver {
  final String id;
  final String? userId;
  
  // User info
  final String? name;
  final String? email;
  final String? phone;
  final String? profilePhoto;
  
  // Driver status
  final bool isOnline;
  final bool isAvailable;
  final bool isActive;
  final bool isVerified;
  
  // Current order
  final String? currentOrderId;
  final bool hasActiveOrder;
  
  // Location
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationUpdate;
  
  // Vehicle info
  final String? vehicleType;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehicleLicensePlate;
  final int? vehicleYear;
  
  // License & verification
  final String? driverLicenseNumber;
  final DateTime? driverLicenseExpiry;
  final bool hasInsulatedBag;
  final bool hasSmartphone;
  
  // Document URLs
  final String? driverLicenseFrontUrl;
  final String? driverLicenseBackUrl;
  final String? nationalIdFrontUrl;
  final String? nationalIdBackUrl;
  final String? vehiclePhotoUrl;
  final String? vehicleRegistrationUrl;
  final String? vehicleInsuranceUrl;
  
  // Stats
  final double acceptanceRate;
  final double completionRate;
  final double averageRating;
  final int totalRatings;
  final int totalDeliveries;
  final int successfulDeliveries;
  
  // Earnings (in cents/smallest currency unit)
  final int totalEarnings;
  final int pendingEarnings;
  final int todayEarnings;
  final int todayDeliveries;
  final int todayOnlineMinutes;
  
  // Driver mode & ride-hailing fields
  final DriverMode driverMode;
  final String? rideCategory;          // 'economy', 'comfort', 'comfort_plus'
  final int totalRides;
  final String? rideApplicationStatus; // 'pending_review', 'approved', 'rejected'
  final bool isRideDriver;             // approved for rides
  final bool isDeliveryDriver;         // approved for delivery
  
  // Settings
  final double maxDeliveryDistanceKm;
  final String? preferredWorkAreas;
  
  // Payment info (masked)
  final String? bankName;
  final String? bankAccountNumber;
  final String? mobileMoneyProvider;
  final String? mobileMoneyNumber;
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Driver({
    required this.id,
    this.userId,
    this.name,
    this.email,
    this.phone,
    this.profilePhoto,
    this.isOnline = false,
    this.isAvailable = false,
    this.isActive = true,
    this.isVerified = false,
    this.currentOrderId,
    this.hasActiveOrder = false,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    this.vehicleType,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleLicensePlate,
    this.vehicleYear,
    this.driverLicenseNumber,
    this.driverLicenseExpiry,
    this.hasInsulatedBag = false,
    this.hasSmartphone = true,
    this.driverLicenseFrontUrl,
    this.driverLicenseBackUrl,
    this.nationalIdFrontUrl,
    this.nationalIdBackUrl,
    this.vehiclePhotoUrl,
    this.vehicleRegistrationUrl,
    this.vehicleInsuranceUrl,
    this.acceptanceRate = 100.0,
    this.completionRate = 100.0,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalDeliveries = 0,
    this.successfulDeliveries = 0,
    this.totalEarnings = 0,
    this.pendingEarnings = 0,
    this.todayEarnings = 0,
    this.todayDeliveries = 0,
    this.todayOnlineMinutes = 0,
    this.driverMode = DriverMode.delivery,
    this.rideCategory,
    this.totalRides = 0,
    this.rideApplicationStatus,
    this.isRideDriver = false,
    this.isDeliveryDriver = true,
    this.maxDeliveryDistanceKm = 15.0,
    this.preferredWorkAreas,
    this.bankName,
    this.bankAccountNumber,
    this.mobileMoneyProvider,
    this.mobileMoneyNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? '',
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profilePhoto: json['profile_photo'],
      isOnline: json['is_online'] ?? false,
      isAvailable: json['is_available'] ?? false,
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      currentOrderId: json['current_order_id'],
      hasActiveOrder: json['has_active_order'] ?? false,
      currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
      currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
      lastLocationUpdate: json['last_location_update'] != null 
          ? DateTime.tryParse(json['last_location_update']) 
          : null,
      vehicleType: json['vehicle_type'],
      vehicleBrand: json['vehicle_brand'],
      vehicleModel: json['vehicle_model'],
      vehicleColor: json['vehicle_color'],
      vehicleLicensePlate: json['vehicle_license_plate'],
      vehicleYear: json['vehicle_year'],
      driverLicenseNumber: json['driver_license_number'],
      driverLicenseExpiry: json['driver_license_expiry'] != null 
          ? DateTime.tryParse(json['driver_license_expiry']) 
          : null,
      hasInsulatedBag: json['has_insulated_bag'] ?? false,
      hasSmartphone: json['has_smartphone'] ?? true,
      driverLicenseFrontUrl: json['driver_license_front_url'],
      driverLicenseBackUrl: json['driver_license_back_url'],
      nationalIdFrontUrl: json['national_id_front_url'],
      nationalIdBackUrl: json['national_id_back_url'],
      vehiclePhotoUrl: json['vehicle_photo_url'],
      vehicleRegistrationUrl: json['vehicle_registration_url'],
      vehicleInsuranceUrl: json['vehicle_insurance_url'],
      acceptanceRate: (json['acceptance_rate'] as num?)?.toDouble() ?? 100.0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 100.0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] ?? 0,
      totalDeliveries: json['total_deliveries'] ?? 0,
      successfulDeliveries: json['successful_deliveries'] ?? 0,
      totalEarnings: json['total_earnings'] ?? 0,
      pendingEarnings: json['pending_earnings'] ?? 0,
      todayEarnings: json['today_earnings'] ?? 0,
      todayDeliveries: json['today_deliveries'] ?? 0,
      todayOnlineMinutes: json['today_online_minutes'] ?? 0,
      driverMode: _parseDriverMode(json['driver_mode']),
      rideCategory: json['ride_category'],
      totalRides: json['total_rides'] ?? 0,
      rideApplicationStatus: json['ride_application_status'],
      isRideDriver: json['is_ride_driver'] ?? false,
      isDeliveryDriver: json['is_delivery_driver'] ?? true,
      maxDeliveryDistanceKm: (json['max_delivery_distance_km'] as num?)?.toDouble() ?? 15.0,
      preferredWorkAreas: json['preferred_work_areas'],
      bankName: json['bank_name'],
      bankAccountNumber: json['bank_account_number'],
      mobileMoneyProvider: json['mobile_money_provider'],
      mobileMoneyNumber: json['mobile_money_number'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'is_online': isOnline,
      'is_available': isAvailable,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'max_delivery_distance_km': maxDeliveryDistanceKm,
    };
  }

  Driver copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? profilePhoto,
    bool? isOnline,
    bool? isAvailable,
    bool? isActive,
    bool? isVerified,
    String? currentOrderId,
    bool? hasActiveOrder,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? lastLocationUpdate,
    String? vehicleType,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleColor,
    String? vehicleLicensePlate,
    int? vehicleYear,
    String? driverLicenseNumber,
    DateTime? driverLicenseExpiry,
    bool? hasInsulatedBag,
    bool? hasSmartphone,
    String? driverLicenseFrontUrl,
    String? driverLicenseBackUrl,
    String? nationalIdFrontUrl,
    String? nationalIdBackUrl,
    String? vehiclePhotoUrl,
    String? vehicleRegistrationUrl,
    String? vehicleInsuranceUrl,
    double? acceptanceRate,
    double? completionRate,
    double? averageRating,
    int? totalRatings,
    int? totalDeliveries,
    int? successfulDeliveries,
    int? totalEarnings,
    int? pendingEarnings,
    int? todayEarnings,
    int? todayDeliveries,
    int? todayOnlineMinutes,
    DriverMode? driverMode,
    String? rideCategory,
    int? totalRides,
    String? rideApplicationStatus,
    bool? isRideDriver,
    bool? isDeliveryDriver,
    double? maxDeliveryDistanceKm,
    String? preferredWorkAreas,
    String? bankName,
    String? bankAccountNumber,
    String? mobileMoneyProvider,
    String? mobileMoneyNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      isOnline: isOnline ?? this.isOnline,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      hasActiveOrder: hasActiveOrder ?? this.hasActiveOrder,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleLicensePlate: vehicleLicensePlate ?? this.vehicleLicensePlate,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      driverLicenseNumber: driverLicenseNumber ?? this.driverLicenseNumber,
      driverLicenseExpiry: driverLicenseExpiry ?? this.driverLicenseExpiry,
      hasInsulatedBag: hasInsulatedBag ?? this.hasInsulatedBag,
      hasSmartphone: hasSmartphone ?? this.hasSmartphone,
      driverLicenseFrontUrl: driverLicenseFrontUrl ?? this.driverLicenseFrontUrl,
      driverLicenseBackUrl: driverLicenseBackUrl ?? this.driverLicenseBackUrl,
      nationalIdFrontUrl: nationalIdFrontUrl ?? this.nationalIdFrontUrl,
      nationalIdBackUrl: nationalIdBackUrl ?? this.nationalIdBackUrl,
      vehiclePhotoUrl: vehiclePhotoUrl ?? this.vehiclePhotoUrl,
      vehicleRegistrationUrl: vehicleRegistrationUrl ?? this.vehicleRegistrationUrl,
      vehicleInsuranceUrl: vehicleInsuranceUrl ?? this.vehicleInsuranceUrl,
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
      completionRate: completionRate ?? this.completionRate,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      successfulDeliveries: successfulDeliveries ?? this.successfulDeliveries,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      pendingEarnings: pendingEarnings ?? this.pendingEarnings,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayDeliveries: todayDeliveries ?? this.todayDeliveries,
      todayOnlineMinutes: todayOnlineMinutes ?? this.todayOnlineMinutes,
      driverMode: driverMode ?? this.driverMode,
      rideCategory: rideCategory ?? this.rideCategory,
      totalRides: totalRides ?? this.totalRides,
      rideApplicationStatus: rideApplicationStatus ?? this.rideApplicationStatus,
      isRideDriver: isRideDriver ?? this.isRideDriver,
      isDeliveryDriver: isDeliveryDriver ?? this.isDeliveryDriver,
      maxDeliveryDistanceKm: maxDeliveryDistanceKm ?? this.maxDeliveryDistanceKm,
      preferredWorkAreas: preferredWorkAreas ?? this.preferredWorkAreas,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      mobileMoneyProvider: mobileMoneyProvider ?? this.mobileMoneyProvider,
      mobileMoneyNumber: mobileMoneyNumber ?? this.mobileMoneyNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Display helpers
  String get totalEarningsDisplay => '${(totalEarnings / 100).toStringAsFixed(0)} CFA';
  String get pendingEarningsDisplay => '${(pendingEarnings / 100).toStringAsFixed(0)} CFA';
  String get todayEarningsDisplay => '${(todayEarnings / 100).toStringAsFixed(0)} CFA';
  
  String get vehicleDescription {
    final parts = <String>[];
    if (vehicleBrand != null) parts.add(vehicleBrand!);
    if (vehicleModel != null) parts.add(vehicleModel!);
    if (vehicleYear != null) parts.add('($vehicleYear)');
    return parts.isNotEmpty ? parts.join(' ') : vehicleType ?? 'Vehicle';
  }

  String get ratingDisplay => averageRating > 0 ? averageRating.toStringAsFixed(1) : 'New';
  
  String get onlineTimeDisplay {
    final hours = todayOnlineMinutes ~/ 60;
    final mins = todayOnlineMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  bool get canDrive => isRideDriver && isVerified && isActive;
  bool get canDeliver => isDeliveryDriver && isVerified && isActive;
  bool get isDualMode => isRideDriver && isDeliveryDriver;

  @override
  String toString() => 'Driver(id: $id, name: $name, isOnline: $isOnline, mode: $driverMode)';
}

enum DriverMode { delivery, rides }

DriverMode _parseDriverMode(String? mode) {
  switch (mode) {
    case 'rides': return DriverMode.rides;
    default: return DriverMode.delivery;
  }
}
