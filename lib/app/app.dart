import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/theme.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/auth_provider.dart';
import 'package:flaride_driver/core/services/auth_service.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/core/providers/ride_provider.dart';
import 'package:flaride_driver/features/driver/parcels/parcel_driver_provider.dart';
import 'package:flaride_driver/features/auth/screens/login_screen.dart';
import 'package:flaride_driver/features/driver/driver_home_page.dart';
import 'package:flaride_driver/features/splash/splash_screen.dart';
import 'package:flaride_driver/features/onboarding/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global navigator key for handling navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FlaRideDriverApp extends StatelessWidget {
  const FlaRideDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(AuthService()),
        ),
        ChangeNotifierProvider(
          create: (context) => DriverProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => DriverRideProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ParcelDriverProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'FlaRide Driver',
        theme: buildFlaRideTheme(),
        navigatorKey: navigatorKey,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  static const String _onboardingKey = 'has_seen_onboarding';
  
  // App flow states
  AppFlowState _flowState = AppFlowState.splash;
  bool _isAuthenticated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _onSplashComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;
      
      if (!hasSeenOnboarding) {
        // First time user - show onboarding
        setState(() => _flowState = AppFlowState.onboarding);
        return;
      }

      // Check authentication
      await _checkAuth();
    } catch (e) {
      print('AuthWrapper: Error after splash: $e');
      setState(() {
        _error = 'Failed to initialize. Please try again.';
        _flowState = AppFlowState.error;
      });
    }
  }

  Future<void> _onOnboardingComplete() async {
    try {
      // Mark onboarding as seen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
      
      // Check authentication
      await _checkAuth();
    } catch (e) {
      print('AuthWrapper: Error after onboarding: $e');
      setState(() => _flowState = AppFlowState.login);
    }
  }

  Future<void> _checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userRole = prefs.getString('user_role');

      print('AuthWrapper: Checking session - token exists: ${token != null}, role: $userRole');

      if (token != null && token.isNotEmpty && userRole == 'driver') {
        // Validate token by checking with the server
        final authService = AuthService();
        try {
          final userResponse = await authService.getCurrentUser();
          final user = userResponse['user'] as Map<String, dynamic>?;
          
          if (user != null && user['role'] == 'driver') {
            print('AuthWrapper: Session valid, user is driver');
            
            // Initialize driver provider
            if (mounted) {
              final driverProvider = Provider.of<DriverProvider>(context, listen: false);
              await driverProvider.checkDriverStatus();
            }
            
            setState(() {
              _isAuthenticated = true;
              _flowState = AppFlowState.home;
            });
            return;
          }
        } catch (e) {
          print('AuthWrapper: Token validation failed: $e');
          // Token is invalid, clear it
          await prefs.remove('auth_token');
          await prefs.remove('user_role');
        }
      }

      // Not authenticated or token invalid
      setState(() {
        _isAuthenticated = false;
        _flowState = AppFlowState.login;
      });
    } catch (e) {
      print('AuthWrapper: Error checking auth: $e');
      setState(() => _flowState = AppFlowState.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_flowState) {
      case AppFlowState.splash:
        return SplashScreen(onComplete: _onSplashComplete);
        
      case AppFlowState.onboarding:
        return OnboardingScreen(onComplete: _onOnboardingComplete);
        
      case AppFlowState.error:
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error ?? 'An error occurred', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _flowState = AppFlowState.splash);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
        
      case AppFlowState.login:
        return const DriverLoginScreen();
        
      case AppFlowState.home:
        return const DriverHomePage();
    }
  }
}

enum AppFlowState {
  splash,
  onboarding,
  login,
  home,
  error,
}

/// Helper function to sign out and navigate to login
Future<void> signOutAndNavigateToLogin(BuildContext context) async {
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    // Navigate to login by replacing the entire navigation stack
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DriverLoginScreen()),
        (route) => false,
      );
    }
  } catch (e) {
    print('Sign out error: $e');
  }
}
