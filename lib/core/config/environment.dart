import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class EnvironmentConfig {
  static const Environment _environment = Environment.production;
  
  // API Keys - These should be set via environment variables or build-time configuration
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyBlLb3x5TXDNL2WE2PlT7BJGOFBhg-JM3o', // Development key
  );

  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nudsmdkbercibnnrjubm.supabase.co',
  );

  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51ZHNtZGtiZXJjaWJubnJqdWJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1NDEyNzcsImV4cCI6MjA3MzExNzI3N30.QOQDyW2bUikHJ_d9y1BIVRDtC8s_Foz9KtmKHJEa2c4',
  );

  static const String _restaurantApiBaseUrl = String.fromEnvironment(
    'RESTAURANT_API_BASE_URL',
    defaultValue: 'https://flaride.vercel.app',
  );

  // Getters
  static Environment get environment => _environment;
  static String get googleMapsApiKey => _googleMapsApiKey;
  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;
  static String get restaurantApiBaseUrl => _restaurantApiBaseUrl;

  // Environment checks
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;

  // Configuration validation
  static bool get isGoogleMapsConfigured => 
      _googleMapsApiKey.isNotEmpty && 
      _googleMapsApiKey != 'your_google_maps_api_key_here';
  
  static bool get isSupabaseConfigured => 
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

  // Debug information
  static void printConfiguration() {
    if (kDebugMode) {
      print('=== Environment Configuration ===');
      print('Environment: $_environment');
      print('Google Maps API Key: ${_googleMapsApiKey.substring(0, 10)}...');
      print('Supabase URL: $_supabaseUrl');
      print('Restaurant API URL: $_restaurantApiBaseUrl');
      print('Google Maps Configured: $isGoogleMapsConfigured');
      print('Supabase Configured: $isSupabaseConfigured');
      print('===============================');
    }
  }

  // Validation
  static List<String> validateConfiguration() {
    final List<String> errors = [];
    
    if (!isGoogleMapsConfigured) {
      errors.add('Google Maps API key is not properly configured');
    }
    
    if (isProduction && !isSupabaseConfigured) {
      errors.add('Supabase configuration is required for production');
    }
    
    return errors;
  }
}
