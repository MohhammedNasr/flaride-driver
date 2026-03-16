import 'package:flutter/material.dart';
import 'package:flaride_driver/core/services/auth_provider.dart';
import 'package:flaride_driver/features/auth/screens/login_screen.dart';
import 'package:flaride_driver/features/driver/driver_home_page.dart';
import 'package:flaride_driver/features/driver/driver_set_password_screen.dart';

class AuthNavigationHelper {
  static void navigateBasedOnAuthState(
    BuildContext context,
    AuthProvider authProvider, {
    bool replace = true,
  }) {
    if (!authProvider.isSignedIn) {
      _navigate(context, DriverLoginScreen.routeName, replace: replace);
      return;
    }

    // Driver app - only handle driver navigation
    if (authProvider.mustChangePassword) {
      _navigate(context, DriverSetPasswordScreen.routeName, replace: replace);
    } else {
      _navigate(context, DriverHomePage.routeName, replace: replace);
    }
  }

  static void _navigate(BuildContext context, String routeName, {required bool replace}) {
    if (replace) {
      Navigator.of(context).pushReplacementNamed(routeName);
    } else {
      Navigator.of(context).pushNamed(routeName);
    }
  }
}
