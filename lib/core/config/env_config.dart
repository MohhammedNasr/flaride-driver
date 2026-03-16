
class EnvConfig {
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyBlLb3x5TXDNL2WE2PlT7BJGOFBhg-JM3o',
  );

  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String _restaurantApiBaseUrl = String.fromEnvironment(
    'RESTAURANT_API_BASE_URL',
    defaultValue: 'https://flaride.vercel.app',
  );

  // Getters
  static String get googleMapsApiKey => _googleMapsApiKey;
  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;
  static String get restaurantApiBaseUrl => _restaurantApiBaseUrl;

  // Validation
  static bool get isGoogleMapsConfigured => 
      _googleMapsApiKey.isNotEmpty && _googleMapsApiKey != 'your_google_maps_api_key_here';
  
  static bool get isSupabaseConfigured => 
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

  // Environment detection
  static bool get isProduction => 
      const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development') == 'production';
  
  static bool get isDevelopment => !isProduction;
}
