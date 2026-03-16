import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flaride_driver/core/config/api_config.dart';

class CountryCityService {
  static final CountryCityService _instance = CountryCityService._internal();
  factory CountryCityService() => _instance;
  CountryCityService._internal();

  // Cache
  List<Country>? _countriesCache;
  Map<String, List<City>> _citiesCache = {};

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Get all active countries
  Future<List<Country>> getCountries({String? serviceType, bool refresh = false}) async {
    if (_countriesCache != null && !refresh) {
      return _filterByService(_countriesCache!, serviceType);
    }

    try {
      String url = '${ApiConfig.baseUrl}/api/countries';
      if (serviceType != null) {
        url += '?service=$serviceType';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _countriesCache = (data['countries'] as List)
              .map((c) => Country.fromJson(c))
              .toList();
          return _filterByService(_countriesCache!, serviceType);
        }
      }
      throw Exception('Failed to load countries');
    } catch (e) {
      throw Exception('Error loading countries: $e');
    }
  }

  List<Country> _filterByService(List<Country> countries, String? serviceType) {
    if (serviceType == null) return countries;
    return countries.where((c) {
      switch (serviceType) {
        case 'rides':
          return c.isActiveForRides;
        case 'delivery':
          return c.isActiveForDelivery;
        case 'restaurants':
          return c.isActiveForRestaurants;
        default:
          return c.isActive;
      }
    }).toList();
  }

  /// Get cities for a country
  Future<List<City>> getCities(String countryId, {String? serviceType, bool refresh = false}) async {
    final cacheKey = '$countryId-$serviceType';
    if (_citiesCache.containsKey(cacheKey) && !refresh) {
      return _citiesCache[cacheKey]!;
    }

    try {
      String url = '${ApiConfig.baseUrl}/api/countries/$countryId/cities';
      if (serviceType != null) {
        url += '?service=$serviceType';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final cities = (data['cities'] as List)
              .map((c) => City.fromJson(c))
              .toList();
          _citiesCache[cacheKey] = cities;
          return cities;
        }
      }
      throw Exception('Failed to load cities');
    } catch (e) {
      throw Exception('Error loading cities: $e');
    }
  }

  /// Save user's selected country and city
  Future<void> saveSelectedLocation(String countryId, String cityId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_country_id', countryId);
    await prefs.setString('selected_city_id', cityId);
  }

  /// Get saved location
  Future<Map<String, String?>> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'country_id': prefs.getString('selected_country_id'),
      'city_id': prefs.getString('selected_city_id'),
    };
  }

  /// Update user profile with country/city
  Future<bool> updateUserLocation(String countryId, String cityId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/driver/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'country_id': countryId,
          'city_id': cityId,
        }),
      );

      if (response.statusCode == 200) {
        await saveSelectedLocation(countryId, cityId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clear cache
  void clearCache() {
    _countriesCache = null;
    _citiesCache.clear();
  }
}

class Country {
  final String id;
  final String name;
  final String isoCode;
  final String currencyCode;
  final String currencySymbol;
  final String? phoneCode;
  final String? flagEmoji;
  final bool isActive;
  final bool isActiveForRides;
  final bool isActiveForDelivery;
  final bool isActiveForRestaurants;
  final String defaultLanguage;
  final String timezone;

  Country({
    required this.id,
    required this.name,
    required this.isoCode,
    required this.currencyCode,
    this.currencySymbol = '',
    this.phoneCode,
    this.flagEmoji,
    this.isActive = false,
    this.isActiveForRides = false,
    this.isActiveForDelivery = false,
    this.isActiveForRestaurants = false,
    this.defaultLanguage = 'fr',
    this.timezone = 'Africa/Abidjan',
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isoCode: json['iso_code'] ?? '',
      currencyCode: json['currency_code'] ?? 'XOF',
      currencySymbol: json['currency_symbol'] ?? '',
      phoneCode: json['phone_code'],
      flagEmoji: json['flag_emoji'],
      isActive: json['is_active'] ?? false,
      isActiveForRides: json['is_active_for_rides'] ?? false,
      isActiveForDelivery: json['is_active_for_delivery'] ?? false,
      isActiveForRestaurants: json['is_active_for_restaurants'] ?? false,
      defaultLanguage: json['default_language'] ?? 'fr',
      timezone: json['timezone'] ?? 'Africa/Abidjan',
    );
  }

  String get displayName => flagEmoji != null ? '$flagEmoji $name' : name;
}

class City {
  final String id;
  final String name;
  final String? nameLocal;
  final String countryId;
  final String? countryName;
  final String? countryCode;
  final String? currencyCode;
  final double? latitude;
  final double? longitude;
  final double radiusKm;
  final bool isActive;
  final bool isActiveForRides;
  final bool isActiveForDelivery;
  final bool isActiveForRestaurants;
  final String? timezone;

  City({
    required this.id,
    required this.name,
    this.nameLocal,
    required this.countryId,
    this.countryName,
    this.countryCode,
    this.currencyCode,
    this.latitude,
    this.longitude,
    this.radiusKm = 50,
    this.isActive = false,
    this.isActiveForRides = false,
    this.isActiveForDelivery = false,
    this.isActiveForRestaurants = false,
    this.timezone,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameLocal: json['name_local'],
      countryId: json['country_id'] ?? '',
      countryName: json['country_name'],
      countryCode: json['country_code'],
      currencyCode: json['currency_code'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      radiusKm: (json['radius_km'] ?? 50).toDouble(),
      isActive: json['is_active'] ?? false,
      isActiveForRides: json['is_active_for_rides'] ?? false,
      isActiveForDelivery: json['is_active_for_delivery'] ?? false,
      isActiveForRestaurants: json['is_active_for_restaurants'] ?? false,
      timezone: json['timezone'],
    );
  }
}
