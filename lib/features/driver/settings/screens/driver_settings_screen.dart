import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/biometric_service.dart';
import 'package:flaride_driver/core/services/voice_service.dart';
import 'package:flaride_driver/core/theme/theme_provider.dart';
import 'package:flaride_driver/core/utils/haptic_utils.dart';
import 'package:flaride_driver/core/config/api_config.dart';
import 'package:flaride_driver/core/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();
  final VoiceService _voiceService = VoiceService();

  bool _isLoading = true;
  
  // Settings
  bool _autoAcceptOrders = false;
  bool _biometricEnabled = false;
  bool _voiceAnnouncementsEnabled = true;
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  double _maxDeliveryDistance = 15.0;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      // Load local settings
      final prefs = await SharedPreferences.getInstance();
      _voiceAnnouncementsEnabled = prefs.getBool('voice_announcements') ?? true;
      _biometricEnabled = await _biometricService.isBiometricEnabled();
      _biometricAvailable = await _biometricService.isDeviceSupported() && 
                            await _biometricService.canCheckBiometrics();

      // Load server settings
      final token = await _authService.getToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.apiBaseUrl}/api/drivers/me'),
          headers: ApiConfig.getAuthHeaders(token),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['data'] as Map<String, dynamic>?;
          if (data != null) {
            setState(() {
              _autoAcceptOrders = data['auto_accept_orders'] ?? false;
              _pushNotificationsEnabled = data['push_notifications'] ?? true;
              _emailNotificationsEnabled = data['email_notifications'] ?? true;
              _maxDeliveryDistance = (data['max_delivery_distance_km'] ?? 15.0).toDouble();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateServerSetting(String key, dynamic value) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      await http.put(
        Uri.parse('${ApiConfig.apiBaseUrl}/api/drivers/me'),
        headers: ApiConfig.getAuthHeaders(token),
        body: jsonEncode({key: value}),
      );
    } catch (e) {
      debugPrint('Error updating setting: $e');
    }
  }

  Future<void> _updateLocalSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection(
                  title: 'Order Preferences',
                  children: [
                    _buildSwitchTile(
                      icon: Icons.flash_on,
                      iconColor: AppColors.primaryOrange,
                      title: 'Auto-Accept Orders',
                      subtitle: 'Automatically accept new orders when online',
                      value: _autoAcceptOrders,
                      onChanged: (value) {
                        HapticUtils.lightImpact();
                        setState(() => _autoAcceptOrders = value);
                        _updateServerSetting('auto_accept_orders', value);
                      },
                    ),
                    _buildSliderTile(
                      icon: Icons.location_on,
                      iconColor: AppColors.primaryGreen,
                      title: 'Max Delivery Distance',
                      subtitle: '${_maxDeliveryDistance.toInt()} km',
                      value: _maxDeliveryDistance,
                      min: 5,
                      max: 30,
                      onChanged: (value) {
                        setState(() => _maxDeliveryDistance = value);
                      },
                      onChangeEnd: (value) {
                        HapticUtils.lightImpact();
                        _updateServerSetting('max_delivery_distance_km', value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Notifications',
                  children: [
                    _buildSwitchTile(
                      icon: Icons.notifications,
                      iconColor: Colors.blue,
                      title: 'Push Notifications',
                      subtitle: 'Receive push notifications for orders',
                      value: _pushNotificationsEnabled,
                      onChanged: (value) {
                        HapticUtils.lightImpact();
                        setState(() => _pushNotificationsEnabled = value);
                        _updateServerSetting('push_notifications', value);
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.email,
                      iconColor: Colors.purple,
                      title: 'Email Notifications',
                      subtitle: 'Receive email updates and summaries',
                      value: _emailNotificationsEnabled,
                      onChanged: (value) {
                        HapticUtils.lightImpact();
                        setState(() => _emailNotificationsEnabled = value);
                        _updateServerSetting('email_notifications', value);
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.volume_up,
                      iconColor: Colors.teal,
                      title: 'Voice Announcements',
                      subtitle: 'Hear voice announcements for new orders',
                      value: _voiceAnnouncementsEnabled,
                      onChanged: (value) {
                        HapticUtils.lightImpact();
                        setState(() => _voiceAnnouncementsEnabled = value);
                        _voiceService.setEnabled(value);
                        _updateLocalSetting('voice_announcements', value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Security',
                  children: [
                    if (_biometricAvailable)
                      _buildSwitchTile(
                        icon: Icons.fingerprint,
                        iconColor: Colors.indigo,
                        title: 'Biometric Login',
                        subtitle: 'Use Face ID or Fingerprint to sign in',
                        value: _biometricEnabled,
                        onChanged: (value) async {
                          HapticUtils.lightImpact();
                          await _biometricService.setBiometricEnabled(value);
                          setState(() => _biometricEnabled = value);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Appearance',
                  children: [
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return _buildSwitchTile(
                          icon: Icons.dark_mode,
                          iconColor: Colors.blueGrey,
                          title: 'Dark Mode',
                          subtitle: 'Use dark theme',
                          value: themeProvider.isDarkMode,
                          onChanged: (value) {
                            HapticUtils.lightImpact();
                            themeProvider.toggleTheme();
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.midGray,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.darkGray,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.midGray,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkGray,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.midGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: iconColor,
              inactiveTrackColor: iconColor.withOpacity(0.2),
              thumbColor: iconColor,
              overlayColor: iconColor.withOpacity(0.1),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}
