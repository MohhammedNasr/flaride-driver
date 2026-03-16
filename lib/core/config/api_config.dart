import 'package:flaride_driver/core/config/environment.dart';

class ApiConfig {
  static String get baseUrl => EnvironmentConfig.restaurantApiBaseUrl;
  static String get apiBaseUrl => '$baseUrl/api';
  
  // API Endpoints
  static String get restaurantsEndpoint => '$apiBaseUrl/restaurants';
  static String get restaurantCategoriesEndpoint => '$apiBaseUrl/restaurant-categories';
  static String get menuItemsEndpoint => '$apiBaseUrl/menu-items';
  static String get menuCategoriesEndpoint => '$apiBaseUrl/menu-categories';
  static String get ordersEndpoint => '$apiBaseUrl/orders';
  static String get authEndpoint => '$apiBaseUrl/auth';
  static String get homepageConfigEndpoint => '$apiBaseUrl/homepage';
  
  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}