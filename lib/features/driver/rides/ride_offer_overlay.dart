import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/models/trip.dart';
import 'package:flaride_driver/core/providers/ride_provider.dart';
import 'package:flaride_driver/core/services/dispatch_service.dart';

class RideOfferOverlay extends StatefulWidget {
  final RideOffer offer;
  final VoidCallback onAccepted;
  final VoidCallback onRejected;
  final VoidCallback onExpired;

  const RideOfferOverlay({
    super.key,
    required this.offer,
    required this.onAccepted,
    required this.onRejected,
    required this.onExpired,
  });

  @override
  State<RideOfferOverlay> createState() => _RideOfferOverlayState();
}

class _RideOfferOverlayState extends State<RideOfferOverlay> with SingleTickerProviderStateMixin {
  late Timer _countdownTimer;
  late Duration _remaining;
  bool _isResponding = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _remaining = widget.offer.timeRemaining;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remaining = widget.offer.timeRemaining;
        if (_remaining.inSeconds <= 0) {
          _countdownTimer.cancel();
          widget.onExpired();
        }
      });
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final progress = _remaining.inSeconds / 30; // 30s total

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Timer bar
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      color: _remaining.inSeconds <= 10 ? Colors.red : AppColors.primaryOrange,
                      backgroundColor: AppColors.lightGray,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (_, child) => Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.15),
                                child: child,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.directions_car, color: AppColors.primaryOrange, size: 28),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('New Trip Request', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                                      if (offer.isPhoneBooking) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.accentPurple.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                          child: Text('📞 Phone', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accentPurple)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    offer.rideCategory.toUpperCase(),
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.midGray),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_remaining.inSeconds}s',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: _remaining.inSeconds <= 10 ? Colors.red : AppColors.primaryOrange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Fare + Stats
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(icon: Icons.payments_outlined, value: offer.displayFare, label: 'Fare'),
                              Container(width: 1, height: 36, color: AppColors.dividerGray),
                              _StatItem(icon: Icons.route, value: offer.displayDistance, label: 'Distance'),
                              Container(width: 1, height: 36, color: AppColors.dividerGray),
                              _StatItem(icon: Icons.timer_outlined, value: offer.displayEta, label: 'ETA'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Pickup & Dropoff
                        _LocationRow(
                          icon: Icons.radio_button_checked,
                          iconColor: AppColors.primaryGreen,
                          address: offer.pickup.address ?? 'Pickup',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 11),
                          child: Container(width: 2, height: 20, color: AppColors.dividerGray),
                        ),
                        _LocationRow(
                          icon: Icons.location_on,
                          iconColor: AppColors.primaryOrange,
                          address: offer.dropoff.address ?? 'Destination',
                        ),
                        const SizedBox(height: 8),

                        // Passenger rating
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 16, color: AppColors.midGray),
                            const SizedBox(width: 4),
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              offer.passengerRating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkGray),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.lightGray,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                offer.paymentMethod == 'cash' ? '💵 Cash' : '💳 Card',
                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (offer.isPreAssignment) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.lightGreenBadge, borderRadius: BorderRadius.circular(6)),
                                child: Text('Pre-assigned', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Accept / Reject buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 54,
                                child: OutlinedButton(
                                  onPressed: _isResponding ? null : () => _respond('reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red, width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Icon(Icons.close, size: 28),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isResponding ? null : () => _respond('accept'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.5),
                                  ),
                                  child: _isResponding
                                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text('ACCEPT', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _respond(String action) async {
    if (_isResponding) return;
    setState(() => _isResponding = true);

    final rideProvider = context.read<DriverRideProvider>();
    final OfferActionResult result;

    if (action == 'accept') {
      result = await rideProvider.acceptOffer();
    } else {
      result = await rideProvider.rejectOffer();
    }

    if (!mounted) return;

    if (result.success) {
      if (action == 'accept') {
        widget.onAccepted();
      } else {
        widget.onRejected();
      }
    } else {
      setState(() => _isResponding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Error', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
      );
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryOrange),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.midGray)),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String address;
  const _LocationRow({required this.icon, required this.iconColor, required this.address});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(address, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkGray), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
