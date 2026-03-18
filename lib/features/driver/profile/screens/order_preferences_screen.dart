import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/shared/widgets/app_toast.dart';

class OrderPreferencesScreen extends StatefulWidget {
  const OrderPreferencesScreen({super.key});

  @override
  State<OrderPreferencesScreen> createState() => _OrderPreferencesScreenState();
}

class _OrderPreferencesScreenState extends State<OrderPreferencesScreen> {
  late bool _acceptsFoodDelivery;
  late bool _acceptsRideRequests;
  late bool _acceptsParcelDelivery;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final driver = context.read<DriverProvider>().driver;
    _acceptsFoodDelivery = driver?.acceptsFoodDelivery ?? true;
    _acceptsRideRequests = driver?.acceptsRideRequests ?? false;
    _acceptsParcelDelivery = driver?.acceptsParcelDelivery ?? true;
  }

  void _checkChanges() {
    final driver = context.read<DriverProvider>().driver;
    setState(() {
      _hasChanges = _acceptsFoodDelivery != (driver?.acceptsFoodDelivery ?? true) ||
          _acceptsRideRequests != (driver?.acceptsRideRequests ?? false) ||
          _acceptsParcelDelivery != (driver?.acceptsParcelDelivery ?? true);
    });
  }

  bool get _hasAtLeastOneSelected =>
      _acceptsFoodDelivery || _acceptsRideRequests || _acceptsParcelDelivery;

  Future<void> _savePreferences() async {
    if (!_hasAtLeastOneSelected) {
      AppToast.error(context, 'You must accept at least one order type');
      return;
    }

    setState(() => _isSaving = true);

    final driverProvider = context.read<DriverProvider>();
    final success = await driverProvider.updateOrderPreferences(
      acceptsFoodDelivery: _acceptsFoodDelivery,
      acceptsRideRequests: _acceptsRideRequests,
      acceptsParcelDelivery: _acceptsParcelDelivery,
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      _hasChanges = false;
      AppToast.success(context, 'Order preferences updated');
      Navigator.pop(context);
    } else if (mounted) {
      AppToast.error(
          context, driverProvider.error ?? 'Failed to update preferences');
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverProvider>().driver;
    final isRideDriver = driver?.isRideDriver ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Order Preferences',
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
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryOrange.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.primaryOrange, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Choose which types of orders you want to receive. You must have at least one type enabled.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.darkGray,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Order Types',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 12),

            // Order type cards
            _buildOrderTypeCard(
              icon: Icons.restaurant_outlined,
              title: 'Food Delivery',
              subtitle:
                  'Receive food delivery orders from restaurants near you',
              color: Colors.orange,
              value: _acceptsFoodDelivery,
              onChanged: (val) {
                setState(() => _acceptsFoodDelivery = val);
                _checkChanges();
              },
            ),
            const SizedBox(height: 12),

            _buildOrderTypeCard(
              icon: Icons.local_shipping_outlined,
              title: 'Package Delivery',
              subtitle:
                  'Receive parcel and package delivery orders',
              color: Colors.blue,
              value: _acceptsParcelDelivery,
              onChanged: (val) {
                setState(() => _acceptsParcelDelivery = val);
                _checkChanges();
              },
            ),
            const SizedBox(height: 12),

            _buildOrderTypeCard(
              icon: Icons.directions_car_outlined,
              title: 'Ride Requests',
              subtitle: isRideDriver
                  ? 'Receive ride-hailing requests from passengers'
                  : 'Requires ride driver approval. Apply in your dashboard.',
              color: Colors.green,
              value: _acceptsRideRequests,
              enabled: isRideDriver,
              onChanged: isRideDriver
                  ? (val) {
                      setState(() => _acceptsRideRequests = val);
                      _checkChanges();
                    }
                  : null,
            ),

            if (!_hasAtLeastOneSelected) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You must enable at least one order type to receive orders.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    _hasChanges && _hasAtLeastOneSelected && !_isSaving
                        ? _savePreferences
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  disabledBackgroundColor: AppColors.lightGray,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Save Preferences',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool value,
    bool enabled = true,
    ValueChanged<bool>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value && enabled
              ? color.withOpacity(0.4)
              : AppColors.dividerGray,
          width: value && enabled ? 1.5 : 1,
        ),
      ),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: value && enabled
                      ? color.withOpacity(0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: value && enabled ? color : AppColors.midGray,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: enabled ? AppColors.darkGray : AppColors.midGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.midGray,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
