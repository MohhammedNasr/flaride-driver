import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/models/trip.dart';
import 'package:flaride_driver/core/services/dispatch_service.dart';
import 'package:flaride_driver/core/services/directions_service.dart';
import 'package:flaride_driver/features/driver/trips/customer_rating_screen.dart';

class ActiveRideScreen extends StatefulWidget {
  final DriverTrip initialTrip;
  const ActiveRideScreen({super.key, required this.initialTrip});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  final DispatchService _dispatchService = DispatchService();
  late DriverTrip _trip;
  Timer? _pollTimer;
  Timer? _waitTimer;
  bool _isActioning = false;
  DateTime? _arrivalTime;
  int _callsMade = 0;
  int _smsSent = 0;
  int _waitSeconds = 0;

  // Map state
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _mapReady = false;
  LatLng? _driverLocation;
  StreamSubscription<Position>? _locationSub;

  @override
  void initState() {
    super.initState();
    _trip = widget.initialTrip;
    _startPolling();
    _setupMap();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _waitTimer?.cancel();
    _locationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Google Maps Navigation Launch ──────────────────────────────────

  Future<void> _launchNavigation() async {
    final double destLat;
    final double destLng;

    if (_trip.isInProgress) {
      destLat = _trip.dropoffLat;
      destLng = _trip.dropoffLng;
    } else {
      destLat = _trip.pickupLat;
      destLng = _trip.pickupLng;
    }

    final googleUrl = Uri.parse(
      'google.navigation:q=$destLat,$destLng&mode=d',
    );
    final webUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving',
    );

    try {
      if (Platform.isAndroid && await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl);
      } else if (Platform.isIOS) {
        final iosUrl = Uri.parse(
          'comgooglemaps://?daddr=$destLat,$destLng&directionsmode=driving',
        );
        if (await canLaunchUrl(iosUrl)) {
          await launchUrl(iosUrl);
        } else {
          final appleUrl = Uri.parse(
            'https://maps.apple.com/?daddr=$destLat,$destLng&dirflg=d',
          );
          await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
        }
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Navigation launch error: $e');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _startLocationStream() {
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 30,
      ),
    ).listen((pos) {
      _driverLocation = LatLng(pos.latitude, pos.longitude);
      if (_trip.isEnRoute || _trip.isInProgress) _refreshRoute();
    });
  }

  Future<void> _refreshRoute() async {
    final pickup = LatLng(_trip.pickupLat, _trip.pickupLng);
    final dropoff = LatLng(_trip.dropoffLat, _trip.dropoffLng);
    final drv = _driverLocation;

    // Determine origin/destination based on status
    final LatLng origin = drv ?? pickup;
    final LatLng dest = _trip.isInProgress ? dropoff : pickup;

    final dirs = await DirectionsService.getDirections(
      origin: origin,
      destination: dest,
    );
    if (dirs != null && dirs.isOk && mounted) {
      final r = dirs.firstRoute;
      if (r != null) {
        final pts = r.overviewPolyline.decodedPoints;
        setState(() {
          _polylines = {
            // Border / outline polyline (darker blue, wider)
            Polyline(
              polylineId: const PolylineId('route_border'),
              color: const Color(0xFF1A73E8),
              width: 8,
              points: pts,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            ),
            // Main route polyline (Google Maps blue)
            Polyline(
              polylineId: const PolylineId('route'),
              color: const Color(0xFF4285F4),
              width: 5,
              points: pts,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            ),
          };
          _updateMarkers();
        });
        _fitMapBounds();
      }
    }
  }

  void _updateMarkers() {
    final pickup = LatLng(_trip.pickupLat, _trip.pickupLng);
    final dropoff = LatLng(_trip.dropoffLat, _trip.dropoffLng);
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickup,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
        infoWindow: const InfoWindow(title: 'Pickup'),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: dropoff,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
        infoWindow: const InfoWindow(title: 'Drop-off'),
      ),
    };
  }

  void _setupMap() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _driverLocation = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}

    _startLocationStream();
    _updateMarkers();
    await _refreshRoute();
    if (mounted) setState(() => _mapReady = true);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitMapBounds();
  }

  void _fitMapBounds() {
    if (_mapController == null) return;
    final pickup = LatLng(_trip.pickupLat, _trip.pickupLng);
    final dropoff = LatLng(_trip.dropoffLat, _trip.dropoffLng);

    final pts = <LatLng>[pickup, dropoff];
    if (_driverLocation != null) pts.add(_driverLocation!);

    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final response = await _dispatchService.getCurrentTrip();
      if (response.hasActiveTrip && response.trip != null && mounted) {
        final oldStatus = _trip.status;
        setState(() => _trip = response.trip!);
        if (_trip.isCompleted) {
          _pollTimer?.cancel();
          _waitTimer?.cancel();
          _locationSub?.cancel();
          _navigateToRating();
          return;
        }
        if (_trip.status != oldStatus) {
          _refreshRoute();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_trip.isCompleted) return _buildCompletedScreen();

    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen map
          _mapReady
              ? GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_trip.pickupLat, _trip.pickupLng),
                    zoom: 14,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 56,
                    bottom: 240,
                  ),
                )
              : Container(
                  color: AppColors.lightGray,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryOrange),
                  ),
                ),

          // Top status header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildStatusHeader(),
          ),

          // Right-side FABs (my-location + navigate)
          Positioned(
            right: 16,
            bottom: 250 + bottomPad,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _circleFab(
                  icon: Icons.my_location,
                  color: AppColors.white,
                  iconColor: AppColors.darkGray,
                  onTap: () {
                    if (_driverLocation != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_driverLocation!, 16),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _circleFab(
                  icon: Icons.navigation_rounded,
                  color: AppColors.primaryGreen,
                  iconColor: Colors.white,
                  size: 56,
                  onTap: _launchNavigation,
                ),
              ],
            ),
          ),

          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _circleFab({
    required IconData icon,
    required Color color,
    required Color iconColor,
    double size = 46,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.48),
      ),
    );
  }

  Color get _statusColor {
    if (_trip.isEnRoute) return AppColors.primaryOrange;
    if (_trip.isWaiting) return AppColors.darkOrange;
    if (_trip.isInProgress) return AppColors.primaryGreen;
    return AppColors.primaryOrange;
  }

  String get _statusTitle {
    if (_trip.isEnRoute) return 'En Route to Pickup';
    if (_trip.isWaiting) return 'Waiting for Passenger';
    if (_trip.isInProgress) return 'Trip in Progress';
    return 'Trip';
  }

  String get _statusSubtitle {
    if (_trip.isEnRoute) return _trip.pickupAddress ?? 'Navigating to passenger';
    if (_trip.isWaiting) return 'Passenger notified';
    if (_trip.isInProgress) return _trip.dropoffAddress ?? 'Navigating to destination';
    return '';
  }

  Widget _buildStatusHeader() {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(4, topPad, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_statusColor, _statusColor, _statusColor.withAlpha(0)],
          stops: const [0.0, 0.75, 1.0],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_statusTitle, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(_statusSubtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (_trip.isPhoneBooking)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('Phone', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    switch (_trip.status) {
      case 'driver_arriving':
        return _buildEnRoutePanel();
      case 'arrived_at_pickup':
        return _buildWaitingPanel();
      case 'in_progress':
        return _buildInProgressPanel();
      default:
        return _buildEnRoutePanel();
    }
  }

  // ── En Route to Pickup ─────────────────────────────────────────────

  Widget _buildEnRoutePanel() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad + 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dividerGray, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          _compactPassengerRow(),
          const SizedBox(height: 12),
          _tripInfoBar(),
          const SizedBox(height: 14),
          _primaryButton(label: 'I HAVE ARRIVED', color: AppColors.primaryOrange, onPressed: _markArrived),
          const SizedBox(height: 6),
          _cancelButton(),
        ],
      ),
    );
  }

  // ── Waiting at Pickup ──────────────────────────────────────────────

  Widget _buildWaitingPanel() {
    _arrivalTime ??= DateTime.now();
    if (_waitTimer == null) {
      _waitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _waitSeconds = DateTime.now().difference(_arrivalTime!).inSeconds);
      });
    }

    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad + 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dividerGray, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 10),
          // Passenger + wait timer row
          Row(
            children: [
              Expanded(child: _compactPassengerRow()),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.darkOrange.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: AppColors.darkOrange, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${(_waitSeconds ~/ 60)}:${(_waitSeconds % 60).toString().padLeft(2, '0')}',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkOrange),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Contact row
          Row(
            children: [
              _compactActionChip(Icons.phone, 'Call', _callsMade, () => setState(() => _callsMade++)),
              const SizedBox(width: 8),
              _compactActionChip(Icons.sms, 'SMS', _smsSent, () => setState(() => _smsSent++)),
              const Spacer(),
              if (_waitSeconds >= 300)
                TextButton(
                  onPressed: _isActioning ? null : _reportNoShow,
                  child: Text('No-Show', style: GoogleFonts.poppins(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _primaryButton(label: 'START RIDE', color: AppColors.primaryGreen, onPressed: _startRide),
          const SizedBox(height: 6),
          _cancelButton(),
        ],
      ),
    );
  }

  Widget _compactActionChip(IconData icon, String label, int count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryOrange),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text('$count', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
            ],
          ],
        ),
      ),
    );
  }

  // ── In Progress ────────────────────────────────────────────────────

  Widget _buildInProgressPanel() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad + 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dividerGray, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          _compactPassengerRow(),
          const SizedBox(height: 12),
          _tripInfoBar(),
          const SizedBox(height: 14),
          _primaryButton(label: 'COMPLETE RIDE', color: AppColors.primaryGreen, onPressed: _completeRide),
        ],
      ),
    );
  }

  // ── Completed ──────────────────────────────────────────────────────

  Widget _buildCompletedScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 72),
              const SizedBox(height: 16),
              Text('Trip Completed!', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 8),
              Text(
                _trip.displayFareCFA,
                style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.primaryOrange),
              ),
              Text(
                _trip.paymentMethod == 'cash' ? 'Collect cash payment' : 'Card payment',
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.midGray),
              ),
              const Spacer(flex: 3),
              _primaryButton(
                label: 'Rate Passenger',
                color: AppColors.primaryOrange,
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CustomerRatingScreen(
                      tripId: _trip.id,
                      passengerName: _trip.passenger?.firstName ?? _trip.passengerName ?? 'Passenger',
                      fare: _trip.displayFareCFA,
                      paymentMethod: _trip.paymentMethod ?? 'cash',
                    )),
                  );
                  if (mounted) Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Skip', style: GoogleFonts.poppins(color: AppColors.midGray, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────

  Future<void> _markArrived() async {
    if (_isActioning) return;
    setState(() => _isActioning = true);
    final result = await _dispatchService.markArrived(_trip.id);
    if (mounted) {
      setState(() => _isActioning = false);
      if (result.success) {
        _arrivalTime = DateTime.now();
      } else {
        _showError(result.errorMessage ?? 'Error');
      }
    }
  }

  Future<void> _startRide() async {
    if (_isActioning) return;
    setState(() => _isActioning = true);
    final result = await _dispatchService.startRide(_trip.id);
    if (mounted) {
      setState(() => _isActioning = false);
      if (!result.success) _showError(result.errorMessage ?? 'Error');
    }
  }

  Future<void> _completeRide() async {
    if (_isActioning) return;
    setState(() => _isActioning = true);
    final result = await _dispatchService.completeRide(_trip.id);
    if (mounted) {
      setState(() => _isActioning = false);
      if (result.success) {
        _pollTimer?.cancel();
        _waitTimer?.cancel();
        _navigateToRating();
      } else {
        // If already completed, just go to rating screen
        final errMsg = result.errorMessage ?? 'Error';
        if (errMsg.toLowerCase().contains('completed') || errMsg.toLowerCase().contains('status')) {
          _pollTimer?.cancel();
          _waitTimer?.cancel();
          _navigateToRating();
        } else {
          _showError(errMsg);
        }
      }
    }
  }

  void _navigateToRating() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CustomerRatingScreen(
        tripId: _trip.id,
        passengerName: _trip.passenger?.firstName ?? _trip.passengerName ?? 'Passenger',
        fare: _trip.displayFareCFA,
        paymentMethod: _trip.paymentMethod ?? 'cash',
      )),
    );
  }

  Future<void> _reportNoShow() async {
    if (_isActioning || _arrivalTime == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Report No-Show?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'The passenger will be charged a no-show fee. Make sure you have called and sent an SMS.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.midGray))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Confirm', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActioning = true);
    final waitDuration = DateTime.now().difference(_arrivalTime!).inSeconds;

    final result = await _dispatchService.reportNoShow(
      tripId: _trip.id,
      waitStartedAt: _arrivalTime!,
      callsMade: _callsMade,
      smsSent: _smsSent,
      waitDurationSec: waitDuration,
    );

    if (mounted) {
      setState(() => _isActioning = false);
      if (result.success) {
        Navigator.of(context).pop();
      } else {
        _showError(result.errorMessage ?? 'Conditions not met');
      }
    }
  }

  Future<void> _cancelTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Trip?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Cancelling will affect your reliability score and reward points.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('No', style: GoogleFonts.poppins(color: AppColors.midGray))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Yes, Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActioning = true);
    final result = await _dispatchService.cancelRide(_trip.id);
    if (mounted) {
      setState(() => _isActioning = false);
      if (result.success) {
        Navigator.of(context).pop();
      } else {
        _showError(result.errorMessage ?? 'Error');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.poppins()), backgroundColor: Colors.red),
    );
  }

  // ── Shared Widgets ─────────────────────────────────────────────────

  Widget _compactPassengerRow() {
    final passenger = _trip.passenger;
    final name = passenger?.firstName ?? _trip.passengerName ?? 'Passenger';
    final rating = (passenger?.rating ?? 5.0).toStringAsFixed(1);
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryOrange.withAlpha(50),
          backgroundImage: passenger?.photoUrl != null ? NetworkImage(passenger!.photoUrl!) : null,
          child: passenger?.photoUrl == null
              ? Text(name[0], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primaryOrange))
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 13),
                  const SizedBox(width: 2),
                  Text(rating, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.midGray)),
                  if (_trip.paymentMethod == 'cash') ...[
                    const SizedBox(width: 8),
                    Text('Cash', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.midGray)),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (_trip.isPhoneBooking && _trip.passengerPhone != null)
          IconButton(
            icon: const Icon(Icons.phone, color: AppColors.primaryGreen, size: 20),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _tripInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _infoChip(Icons.route, '${_trip.estimatedDistanceKm?.toStringAsFixed(1) ?? "--"} km', 'Distance'),
          Container(width: 1, height: 28, color: AppColors.dividerGray),
          _infoChip(Icons.timer_outlined, '${_trip.estimatedDurationMin?.toStringAsFixed(0) ?? "--"} min', 'Duration'),
          Container(width: 1, height: 28, color: AppColors.dividerGray),
          _infoChip(Icons.payments_outlined, _trip.displayFareCFA, 'Fare'),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryOrange),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.midGray)),
      ],
    );
  }

  Widget _primaryButton({required String label, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isActioning ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          disabledBackgroundColor: color.withAlpha(128),
        ),
        child: _isActioning
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _cancelButton() {
    return Center(
      child: TextButton(
        onPressed: _isActioning ? null : _cancelTrip,
        child: Text('Cancel Trip', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
