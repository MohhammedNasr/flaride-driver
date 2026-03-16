import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flaride_driver/app/app.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flaride_driver/core/config/environment.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flaride_driver/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.background,
    ),
  );
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
  }

  // Print configuration in debug mode
  EnvironmentConfig.printConfiguration();

  // Validate configuration
  final configErrors = EnvironmentConfig.validateConfiguration();
  if (configErrors.isNotEmpty) {
    debugPrint('Configuration errors:');
    for (final error in configErrors) {
      debugPrint('- $error');
    }
  }

  // Initialize Supabase with environment variables
  await Supabase.initialize(
    url: EnvironmentConfig.supabaseUrl,
    anonKey: EnvironmentConfig.supabaseAnonKey,
  );

  // Initialize Firebase (requires google-services.json / GoogleService-Info.plist)
  try {
    await Firebase.initializeApp();
    // Initialize push notifications
    await NotificationService().initialize();
    debugPrint('Firebase and notifications initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
    // App continues without Firebase if not configured
  }

  runApp(const FlaRideDriverApp());
}
