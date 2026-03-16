import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/shared/widgets/app_toast.dart';

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  double _maxDeliveryDistance = 15.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final driver = context.read<DriverProvider>().driver;
    if (driver != null) {
      _maxDeliveryDistance = driver.maxDeliveryDistanceKm;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notifications Section
            _buildSectionHeader('Notifications'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Receive order and delivery updates',
                icon: Icons.notifications_outlined,
                value: _pushNotifications,
                onChanged: (value) => setState(() => _pushNotifications = value),
              ),
              const Divider(height: 1, color: AppColors.dividerGray),
              _buildSwitchTile(
                title: 'Email Notifications',
                subtitle: 'Receive earnings and reports via email',
                icon: Icons.email_outlined,
                value: _emailNotifications,
                onChanged: (value) => setState(() => _emailNotifications = value),
              ),
              const Divider(height: 1, color: AppColors.dividerGray),
              _buildSwitchTile(
                title: 'SMS Notifications',
                subtitle: 'Receive important alerts via SMS',
                icon: Icons.sms_outlined,
                value: _smsNotifications,
                onChanged: (value) => setState(() => _smsNotifications = value),
              ),
            ]),
            const SizedBox(height: 24),

            // Sound & Vibration
            _buildSectionHeader('Sound & Vibration'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSwitchTile(
                title: 'Sound',
                subtitle: 'Play sound for new orders',
                icon: Icons.volume_up_outlined,
                value: _soundEnabled,
                onChanged: (value) => setState(() => _soundEnabled = value),
              ),
              const Divider(height: 1, color: AppColors.dividerGray),
              _buildSwitchTile(
                title: 'Vibration',
                subtitle: 'Vibrate for new orders',
                icon: Icons.vibration,
                value: _vibrationEnabled,
                onChanged: (value) => setState(() => _vibrationEnabled = value),
              ),
            ]),
            const SizedBox(height: 24),

            // Delivery Preferences
            _buildSectionHeader('Delivery Preferences'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: AppColors.midGray),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Maximum Delivery Distance',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.darkGray,
                                ),
                              ),
                              Text(
                                'Only show orders within this distance',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.midGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_maxDeliveryDistance.toInt()} km',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _maxDeliveryDistance,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      activeColor: AppColors.primaryOrange,
                      inactiveColor: AppColors.lightGray,
                      onChanged: (value) => setState(() => _maxDeliveryDistance = value),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('5 km', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.midGray)),
                        Text('50 km', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.midGray)),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // App Settings
            _buildSectionHeader('App Settings'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildNavigationTile(
                title: 'Language',
                subtitle: 'English',
                icon: Icons.language,
                onTap: () {
                  AppToast.info(context, 'Language settings coming soon');
                },
              ),
              const Divider(height: 1, color: AppColors.dividerGray),
              _buildNavigationTile(
                title: 'Privacy Policy',
                icon: Icons.privacy_tip_outlined,
                onTap: () {},
              ),
              const Divider(height: 1, color: AppColors.dividerGray),
              _buildNavigationTile(
                title: 'Terms of Service',
                icon: Icons.description_outlined,
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),

            // App Version
            Center(
              child: Text(
                'FlaRide Driver v1.0.0',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.midGray,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.darkGray,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerGray),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.midGray),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkGray,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.midGray,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.midGray),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGray,
                ),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.midGray,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.midGray),
          ],
        ),
      ),
    );
  }
}
