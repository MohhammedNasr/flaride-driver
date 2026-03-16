import 'package:flutter/material.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/features/driver/home/screens/map_home_screen.dart';

class DriverHomeScreen extends StatelessWidget {
  final VoidCallback onLocationTap;
  final Function(AvailableOrder) onOrderTap;
  final VoidCallback onToggleOnline;
  final Function(String)? onActiveOrderTap;

  const DriverHomeScreen({super.key, required this.onLocationTap, required this.onOrderTap, required this.onToggleOnline, this.onActiveOrderTap});

  @override
  Widget build(BuildContext context) {
    return MapHomeScreen(
      onLocationTap: onLocationTap,
      onOrderTap: onOrderTap,
      onToggleOnline: onToggleOnline,
      onActiveOrderTap: onActiveOrderTap,
    );
  }
}
