import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/core/providers/ride_provider.dart';
import 'package:flaride_driver/features/driver/rides/ride_driver_apply_screen.dart';

class TripsTabScreen extends StatefulWidget {
  final VoidCallback onToggleOnline;
  const TripsTabScreen({super.key, required this.onToggleOnline});
  @override
  State<TripsTabScreen> createState() => _TripsTabScreenState();
}

class _TripsTabScreenState extends State<TripsTabScreen> {
  GoogleMapController? _mapController;
  LatLng _pos = const LatLng(5.36, -4.008);

  @override
  void initState() { super.initState(); _loadLoc(); }

  @override
  void dispose() { _mapController?.dispose(); super.dispose(); }

  Future<void> _loadLoc() async {
    try {
      final p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) await Geolocator.requestPermission();
      final loc = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) { setState(() => _pos = LatLng(loc.latitude, loc.longitude)); _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_pos, 15)); }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DriverProvider, DriverRideProvider>(builder: (ctx, dp, rp, _) {
      final driver = dp.driver;

      // Non-ride driver: show apply or pending state
      if (driver != null && !driver.isRideDriver) {
        if (driver.rideApplicationStatus == 'pending_review') {
          return _pendingReview();
        }
        return _applyPrompt(context);
      }

      final on = dp.isOnline;
      return Stack(fit: StackFit.expand, children: [
        GoogleMap(onMapCreated: (c) { _mapController = c; c.animateCamera(CameraUpdate.newLatLngZoom(_pos, 15)); }, initialCameraPosition: CameraPosition(target: _pos, zoom: 15), myLocationEnabled: true, myLocationButtonEnabled: false, zoomControlsEnabled: false, compassEnabled: false, mapToolbarEnabled: false),
        if (!on) _offline(),
        if (on && rp.state == DriverRideState.idle) _searching(),
        Positioned(bottom: 32, left: 0, right: 0, child: Center(child: _goBtn(on))),
      ]);
    });
  }

  Widget _applyPrompt(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_car, size: 40, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 24),
              Text('Start Earning with Rides', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Apply to become a ride driver and earn more by transporting passengers in your area.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RideDriverApplyScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Apply Now', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pendingReview() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hourglass_top, size: 40, color: Colors.amber.shade700),
              ),
              const SizedBox(height: 24),
              Text('Application Under Review', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Your ride driver application is being reviewed. This typically takes 24-48 hours. We\'ll notify you once approved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _offline() => Positioned.fill(child: Container(color: Colors.black54, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.wifi_off_rounded, size: 56, color: Colors.white70), const SizedBox(height: 12), Text("You're Offline", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)), const SizedBox(height: 4), Text('Go online to receive trip requests', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70))])));

  Widget _searching() => Positioned(top: 16, left: 20, right: 20, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]), child: Row(children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen)), const SizedBox(width: 12), Text('Looking for trip requests...', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkGray))])));

  Widget _goBtn(bool on) => GestureDetector(onTap: widget.onToggleOnline, child: Container(width: 160, height: 56, decoration: BoxDecoration(color: on ? Colors.red.shade600 : AppColors.primaryGreen, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: (on ? Colors.red : AppColors.primaryGreen).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]), child: Center(child: Text(on ? 'GO OFFLINE' : 'GO ONLINE', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)))));
}
