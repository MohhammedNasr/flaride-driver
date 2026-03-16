import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/features/driver/driver_home_page.dart';
import 'package:flaride_driver/shared/widgets/app_toast.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final OrderDetails order;

  const ActiveDeliveryScreen({
    super.key,
    required this.order,
  });

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> with WidgetsBindingObserver {
  final DriverService _driverService = DriverService();
  
  // Status
  bool _isPickingUp = false;
  
  // Track checked items
  final Set<String> _checkedItems = {};
  
  // Polling
  Timer? _pollTimer;
  late OrderDetails _currentOrder;
  static const Duration _pollInterval = Duration(seconds: 15);
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }
  
  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause polling when app is in background for battery optimization
    if (state == AppLifecycleState.paused) {
      _stopPolling();
    } else if (state == AppLifecycleState.resumed) {
      _startPolling();
      _refreshOrderStatus(); // Immediate refresh when coming back
    }
  }
  
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refreshOrderStatus());
  }
  
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
  
  Future<void> _refreshOrderStatus() async {
    if (_isPolling || !mounted) return;
    
    _isPolling = true;
    try {
      final response = await _driverService.getOrderDetails(_currentOrder.id);
      
      if (response.success && response.order != null && mounted) {
        final newOrder = response.order!;
        
        // Check if status changed
        if (newOrder.status != _currentOrder.status) {
          debugPrint('Order status changed: ${_currentOrder.status} -> ${newOrder.status}');
          
          // Handle status transitions
          if (newOrder.status == 'picked_up') {
            // Navigate to delivery phase
            _stopPolling();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DeliveryPhaseScreen(order: newOrder),
              ),
            );
            return;
          } else if (newOrder.status == 'cancelled') {
            // Order was cancelled
            _stopPolling();
            if (mounted) {
              AppToast.error(context, 'Order has been cancelled');
              Navigator.of(context).pushNamedAndRemoveUntil(
                DriverHomePage.routeName,
                (route) => false,
              );
            }
            return;
          }
        }
        
        // Update order data (even if status same, other fields might change)
        setState(() {
          _currentOrder = newOrder;
        });
      }
    } catch (e) {
      debugPrint('Polling error: $e');
    } finally {
      _isPolling = false;
    }
  }

  void _openNavigation() async {
    final restaurant = _currentOrder.restaurant;
    if (restaurant?.latitude == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${restaurant!.latitude},${restaurant.longitude}&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _callRestaurant() async {
    final phone = _currentOrder.restaurant?.phone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  bool get _canPickup => _currentOrder.status == 'ready_for_pickup';

  Future<void> _markAsPickedUp() async {
    // Only allow pickup when order is ready
    if (!_canPickup) {
      AppToast.info(context, 'Order is still being prepared. Please wait.');
      return;
    }
    
    setState(() => _isPickingUp = true);

    final response = await _driverService.updateOrderStatus(
      _currentOrder.id,
      'picked_up',
    );

    if (mounted) {
      setState(() => _isPickingUp = false);

      if (response.success) {
        // Navigate to delivery phase
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryPhaseScreen(order: _currentOrder),
          ),
        );
      } else {
        AppToast.error(context, response.message ?? 'Failed to update status');
      }
    }
  }

  Widget _buildRestaurantLogo(String? logoUrl, {double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: AppColors.dividerGray, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null && logoUrl.isNotEmpty
          ? Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.restaurant,
                size: size * 0.5,
                color: AppColors.primaryOrange,
              ),
            )
          : Icon(
              Icons.restaurant,
              size: size * 0.5,
              color: AppColors.primaryOrange,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = _currentOrder.restaurant;
    
    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder (map disabled temporarily)
          Container(
            color: const Color(0xFF1a1a2e),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Navigation Mode',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _openNavigation,
                    icon: const Icon(Icons.navigation, color: AppColors.primaryOrange),
                    label: Text(
                      'Open in Google Maps',
                      style: GoogleFonts.poppins(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.store, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Going to Pickup',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.25,
            maxChildSize: 0.75,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Restaurant info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildRestaurantLogo(restaurant?.logoUrl, size: 48),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PICKUP FROM',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryOrange,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    restaurant?.name ?? 'Restaurant',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (restaurant?.address != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: AppColors.midGray),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  restaurant!.address!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.midGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openNavigation,
                                icon: const Icon(Icons.navigation, size: 18),
                                label: const Text('Navigate'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryOrange,
                                  side: const BorderSide(color: AppColors.primaryOrange),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _callRestaurant,
                                icon: const Icon(Icons.call, size: 18),
                                label: const Text('Call'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryGreen,
                                  side: const BorderSide(color: AppColors.primaryGreen),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Order items section
                  Row(
                    children: [
                      Text(
                        'Items to Pickup',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_currentOrder.itemsCount} items',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Items list
                  ..._currentOrder.items.map((item) => _buildItemRow(item)),
                  
                  const SizedBox(height: 20),
                  
                  // Order number
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt, size: 18, color: AppColors.midGray),
                        const SizedBox(width: 8),
                        Text(
                          'Order #${_currentOrder.orderNumber}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Order Status Banner (when still preparing)
                  if (!_canPickup)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Order is being prepared. You\'ll be able to pick up once ready.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Picked Up button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isPickingUp || !_canPickup) ? null : _markAsPickedUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canPickup ? AppColors.primaryGreen : AppColors.midGray,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: AppColors.lightGray,
                        disabledForegroundColor: AppColors.midGray,
                      ),
                      child: _isPickingUp
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_canPickup ? Icons.check_circle : Icons.hourglass_empty, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  _canPickup ? 'Picked Up' : 'Waiting for Order...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    final isChecked = _checkedItems.contains(item.id);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isChecked) {
            _checkedItems.remove(item.id);
          } else {
            _checkedItems.add(item.id);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isChecked ? AppColors.primaryGreen.withValues(alpha: 0.05) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked ? AppColors.primaryGreen : AppColors.dividerGray,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isChecked 
                    ? AppColors.primaryGreen.withValues(alpha: 0.1)
                    : AppColors.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${item.quantity}x',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isChecked ? AppColors.primaryGreen : AppColors.primaryOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isChecked ? AppColors.primaryGreen : AppColors.darkGray,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (item.specialInstructions != null && item.specialInstructions!.isNotEmpty)
                    Text(
                      item.specialInstructions!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.midGray,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              isChecked ? Icons.check_box : Icons.check_box_outline_blank,
              color: isChecked ? AppColors.primaryGreen : AppColors.midGray,
            ),
          ],
        ),
      ),
    );
  }
}

// Delivery Phase Screen (after pickup)
class DeliveryPhaseScreen extends StatefulWidget {
  final OrderDetails order;

  const DeliveryPhaseScreen({
    super.key,
    required this.order,
  });

  @override
  State<DeliveryPhaseScreen> createState() => _DeliveryPhaseScreenState();
}

class _DeliveryPhaseScreenState extends State<DeliveryPhaseScreen> with WidgetsBindingObserver {
  final DriverService _driverService = DriverService();
  
  // Status
  bool _isDelivering = false;
  
  // Polling
  Timer? _pollTimer;
  late OrderDetails _currentOrder;
  static const Duration _pollInterval = Duration(seconds: 15);
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopPolling();
    } else if (state == AppLifecycleState.resumed) {
      _startPolling();
      _refreshOrderStatus();
    }
  }
  
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refreshOrderStatus());
  }
  
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
  
  Future<void> _refreshOrderStatus() async {
    if (_isPolling || !mounted) return;
    
    _isPolling = true;
    try {
      final response = await _driverService.getOrderDetails(_currentOrder.id);
      
      if (response.success && response.order != null && mounted) {
        final newOrder = response.order!;
        
        if (newOrder.status != _currentOrder.status) {
          debugPrint('Delivery status changed: ${_currentOrder.status} -> ${newOrder.status}');
          
          if (newOrder.status == 'delivered') {
            _stopPolling();
            _showDeliveryCompleteDialog();
            return;
          } else if (newOrder.status == 'cancelled') {
            _stopPolling();
            if (mounted) {
              AppToast.error(context, 'Order has been cancelled');
              Navigator.of(context).pushNamedAndRemoveUntil(
                DriverHomePage.routeName,
                (route) => false,
              );
            }
            return;
          }
        }
        
        setState(() {
          _currentOrder = newOrder;
        });
      }
    } catch (e) {
      debugPrint('Polling error: $e');
    } finally {
      _isPolling = false;
    }
  }

  void _openNavigation() async {
    final delivery = _currentOrder.delivery;
    final lat = delivery?.latitude;
    final lng = delivery?.longitude;
    if (lat == null || lng == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _callCustomer() async {
    final phone = _currentOrder.customer?.phone ?? _currentOrder.delivery?.phone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _markAsDelivered() async {
    setState(() => _isDelivering = true);

    final response = await _driverService.updateOrderStatus(
      _currentOrder.id,
      'delivered',
    );

    if (mounted) {
      setState(() => _isDelivering = false);

      if (response.success) {
        // Show success and go back to home
        _showDeliveryCompleteDialog();
      } else {
        AppToast.error(context, response.message ?? 'Failed to update status');
      }
    }
  }

  void _showDeliveryCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.primaryGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delivery Complete!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You earned ${_currentOrder.estimatedEarnings}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Great job! Ready for the next one?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.midGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    // Navigate to driver home and clear the stack
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const DriverHomePage(),
                      ),
                      (route) => false, // Remove all routes
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = _currentOrder.customer;
    final delivery = _currentOrder.delivery;

    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder (map disabled temporarily)
          Container(
            color: const Color(0xFF1a1a2e),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Delivery Mode',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _openNavigation,
                    icon: const Icon(Icons.navigation, color: AppColors.primaryGreen),
                    label: Text(
                      'Open in Google Maps',
                      style: GoogleFonts.poppins(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delivery_dining, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Delivering',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.2,
            maxChildSize: 0.6,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Customer info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DELIVER TO',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGreen,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    customer?.name ?? 'Customer',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (delivery?.address != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: AppColors.midGray),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  delivery!.address!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.midGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (delivery?.instructions != null && delivery!.instructions!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    delivery.instructions ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.darkGray,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openNavigation,
                                icon: const Icon(Icons.navigation, size: 18),
                                label: const Text('Navigate'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryGreen,
                                  side: const BorderSide(color: AppColors.primaryGreen),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _callCustomer,
                                icon: const Icon(Icons.call, size: 18),
                                label: const Text('Call'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryOrange,
                                  side: const BorderSide(color: AppColors.primaryOrange),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isDelivering ? null : _markAsDelivered,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isDelivering
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'Delivered',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
