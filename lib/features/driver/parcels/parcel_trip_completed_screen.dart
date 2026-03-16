import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/features/driver/parcels/parcel_order_model.dart';
import 'package:flaride_driver/features/driver/parcels/parcel_driver_provider.dart';

class ParcelTripCompletedScreen extends StatefulWidget {
  final ActiveParcelOrder order;
  const ParcelTripCompletedScreen({super.key, required this.order});

  @override
  State<ParcelTripCompletedScreen> createState() => _ParcelTripCompletedScreenState();
}

class _ParcelTripCompletedScreenState extends State<ParcelTripCompletedScreen> {
  final TextEditingController _cashCollectedController = TextEditingController();
  int _cashCollected = 0;

  int get _totalFare => widget.order.totalAmount;
  String get _currency => widget.order.currencyCode;
  int get _changeDue => (_cashCollected - _totalFare).clamp(0, 999999);

  @override
  void dispose() {
    _cashCollectedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final now = order.deliveredAt ?? DateTime.now();
    final dateStr = DateFormat('EEEE, d MMM').format(now);
    final timeStr = DateFormat('h:mm a').format(now);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Checkmark icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryOrange, AppColors.primaryOrange.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 20),
              Text(
                'Trip completed',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.darkGray),
              ),
              const SizedBox(height: 6),
              Text(
                '$dateStr  $timeStr',
                style: TextStyle(fontSize: 14, color: AppColors.midGray),
              ),
              const SizedBox(height: 28),
              // Payment card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryOrange, AppColors.primaryOrange.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _paymentMethodLabel(order.paymentMethod),
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 4),
                    Text('Total fare', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7))),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalFare $_currency',
                      style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Cash collected section (only for cash payments)
              if (order.paymentMethod == 'cash' || order.paymentMethod == null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Cash collected', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lightGray),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('₣', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryOrange)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _cashCollectedController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(fontSize: 18, color: AppColors.midGray),
                          ),
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkGray),
                          onChanged: (val) {
                            setState(() {
                              _cashCollected = int.tryParse(val) ?? 0;
                            });
                          },
                        ),
                      ),
                      Text(_currency, style: TextStyle(fontSize: 14, color: AppColors.midGray)),
                    ],
                  ),
                ),
                if (_changeDue > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Change due: $_changeDue $_currency',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryOrange),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primaryOrange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Credit to Passenger Wallet',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryOrange),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Fare breakdown
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Fare Breakdown', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
              ),
              const SizedBox(height: 12),
              _fareRow('Base Fare', '${order.baseFare > 0 ? order.baseFare : 500} $_currency'),
              _fareRow('Distance (${order.distanceKm?.toStringAsFixed(1) ?? '?'} km)', '${order.distanceFare > 0 ? order.distanceFare : (_totalFare * 0.48).round()} $_currency'),
              _fareRow('Time (${order.estimatedDurationMin ?? '?'} min)', '${order.speedSurcharge > 0 ? order.speedSurcharge : (_totalFare * 0.32).round()} $_currency'),
              const SizedBox(height: 8),
              Divider(color: AppColors.lightGray),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                    Text('$_totalFare $_currency', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryOrange)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Complete trip button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Complete delivery and go back to home
                    context.read<ParcelDriverProvider>().completeDelivery();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    side: BorderSide(color: AppColors.darkGray, width: 1.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Complete trip',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkGray),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fareRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: AppColors.midGray)),
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        ],
      ),
    );
  }

  String _paymentMethodLabel(String? method) {
    switch (method) {
      case 'mobile_money': return 'Mobile Money payment';
      case 'card': return 'Card payment';
      default: return 'Cash payment';
    }
  }
}
