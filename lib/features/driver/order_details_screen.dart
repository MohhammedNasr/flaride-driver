import 'package:flaride_driver/features/driver/active_delivery_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/core/services/order_acceptance_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  final AvailableOrder? preloadedOrder; // Optional preloaded data for faster display

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    this.preloadedOrder,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final DriverService _driverService = DriverService();
  final OrderAcceptanceService _acceptanceService = OrderAcceptanceService();
  OrderDetails? _order;
  bool _isLoading = true;
  bool _isAccepting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _driverService.getOrderDetails(widget.orderId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.order != null) {
          _order = response.order;
        } else {
          _error = response.message ?? 'Failed to load order details';
        }
      });
    }
  }

  Future<void> _acceptOrder() async {
    if (_order == null) return;

    await _acceptanceService.acceptOrder(
      context: context,
      orderId: _order!.id,
      onAcceptingStateChanged: () {
        if (mounted) {
          setState(() => _isAccepting = !_isAccepting);
        }
      },
    );
  }

  /// Check if cuisine type contains valid readable text (not garbage characters)
  bool _isValidCuisineType(String text) {
    // Check if the text contains mostly alphanumeric characters and common punctuation
    // Reject if it's mostly special characters like \, ", [, ], etc.
    final alphanumericCount = text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').length;
    final totalLength = text.length;
    
    // If less than 50% of characters are alphanumeric/spaces, it's likely garbage
    if (totalLength == 0) return false;
    if (alphanumericCount / totalLength < 0.5) return false;
    
    // Also check for common garbage patterns
    if (text.contains('\\') || text.contains('["') || text.contains('"]')) {
      return false;
    }
    
    return true;
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

  void _callPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openMaps(double? lat, double? lng, String? label) async {
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.midGray),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Order not found',
            style: GoogleFonts.poppins(color: AppColors.midGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOrderDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderContent() {
    final order = _order!;
    
    return CustomScrollView(
      slivers: [
        // App Bar with earnings highlight
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.primaryGreen.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '#${order.orderNumber}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (order.timeSinceReady != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    order.timeSinceReady!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your Earnings',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        order.estimatedEarnings,
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Distance Summary Card
              _buildDistanceSummaryCard(order),
              const SizedBox(height: 16),

              // Restaurant Card
              _buildRestaurantCard(order),
              const SizedBox(height: 16),

              // Customer & Delivery Card
              _buildCustomerCard(order),
              const SizedBox(height: 16),

              // Order Items Card
              _buildItemsCard(order),
              const SizedBox(height: 16),

              // Payment Summary Card
              _buildPaymentCard(order),
              const SizedBox(height: 100), // Space for bottom button
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceSummaryCard(OrderDetails order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDistanceItem(
              icon: Icons.store,
              label: 'Pickup',
              value: order.pickupDistanceKm != null ? '${order.pickupDistanceKm} km' : '--',
              color: AppColors.primaryOrange,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: AppColors.dividerGray,
          ),
          Expanded(
            child: _buildDistanceItem(
              icon: Icons.delivery_dining,
              label: 'Delivery',
              value: order.deliveryDistanceKm != null ? '${order.deliveryDistanceKm} km' : '--',
              color: AppColors.primaryGreen,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: AppColors.dividerGray,
          ),
          Expanded(
            child: _buildDistanceItem(
              icon: Icons.route,
              label: 'Total',
              value: order.totalDistanceKm != null ? '${order.totalDistanceKm} km' : '--',
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGray,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.midGray,
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantCard(OrderDetails order) {
    final restaurant = order.restaurant;
    if (restaurant == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildRestaurantLogo(restaurant.logoUrl, size: 56),
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
                      restaurant.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray,
                      ),
                    ),
                    if (restaurant.cuisineType != null && 
                        restaurant.cuisineType!.isNotEmpty &&
                        _isValidCuisineType(restaurant.cuisineType!))
                      Text(
                        restaurant.cuisineType!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.midGray,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (restaurant.address != null)
            _buildInfoRow(
              Icons.location_on_outlined,
              restaurant.address!,
              onTap: () => _openMaps(restaurant.latitude, restaurant.longitude, restaurant.name),
            ),
          if (restaurant.phone != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.phone_outlined,
              restaurant.phone!,
              onTap: () => _callPhone(restaurant.phone),
              actionIcon: Icons.call,
              actionColor: AppColors.primaryGreen,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerCard(OrderDetails order) {
    final customer = order.customer;
    final delivery = order.delivery;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: AppColors.primaryGreen),
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
          const SizedBox(height: 16),
          if (delivery?.address != null)
            _buildInfoRow(
              Icons.location_on_outlined,
              delivery!.address!,
              onTap: () => _openMaps(delivery.latitude, delivery.longitude, 'Delivery'),
            ),
          if (delivery?.apartment != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.apartment_outlined, 'Apt: ${delivery!.apartment}'),
          ],
          if (customer?.phone != null || delivery?.phone != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.phone_outlined,
              customer?.phone ?? delivery?.phone ?? '',
              onTap: () => _callPhone(customer?.phone ?? delivery?.phone),
              actionIcon: Icons.call,
              actionColor: AppColors.primaryGreen,
            ),
          ],
          if (delivery?.instructions != null && delivery!.instructions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      delivery.instructions ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {VoidCallback? onTap, IconData? actionIcon, Color? actionColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.midGray),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
            ),
            if (actionIcon != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (actionColor ?? AppColors.primaryOrange).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(actionIcon, size: 18, color: actionColor ?? AppColors.primaryOrange),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(OrderDetails order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Order Items',
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
                  '${order.itemsCount} items',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...order.items.map((item) => _buildItemRow(item)),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${item.quantity}x',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryOrange,
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
                    color: AppColors.darkGray,
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
          Text(
            item.totalPriceDisplay,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(OrderDetails order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Subtotal', order.subtotalDisplay),
          _buildPriceRow('Delivery Fee', order.deliveryFeeDisplay),
          _buildPriceRow('Service Fee', order.serviceFeeDisplay),
          if (order.tipAmount > 0)
            _buildPriceRow('Tip', order.tipAmountDisplay),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
              Text(
                order.totalAmountDisplay,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.attach_money, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Your Earnings: ${order.estimatedEarnings}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          if (order.paymentMethod != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  order.paymentMethod == 'cash' ? Icons.money : Icons.credit_card,
                  size: 18,
                  color: AppColors.midGray,
                ),
                const SizedBox(width: 8),
                Text(
                  order.paymentMethod == 'cash' ? 'Cash on Delivery' : 'Paid Online',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.midGray,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.midGray,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : _error != null
              ? _buildErrorState()
              : _order != null
                  ? _buildOrderContent()
                  : _buildErrorState(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget? _buildBottomBar() {
    if (_order == null) return null;
    
    // Case 1: Order is available for pickup - show Accept button
    if (_order!.isAvailable) {
      return _buildAcceptButton();
    }
    
    // Case 2: This is MY order - show Continue Delivery button
    if (_order!.isMyOrder) {
      return _buildContinueDeliveryButton();
    }
    
    // Case 3: Assigned to another driver - show warning
    if (_order!.alreadyAssigned) {
      return _buildAlreadyTakenBanner();
    }
    
    return null;
  }

  Widget _buildAcceptButton() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isAccepting ? null : _acceptOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isAccepting
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
                        'Accept Order',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueDeliveryButton() {
    final status = _order!.status;
    final isDeliveryPhase = ['picked_up', 'on_the_way', 'arrived'].contains(status);
    final buttonText = isDeliveryPhase ? 'Continue to Delivery' : 'Continue to Pickup';
    final buttonColor = isDeliveryPhase ? AppColors.primaryGreen : AppColors.primaryOrange;
    final buttonIcon = isDeliveryPhase ? Icons.local_shipping : Icons.store;
    
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => isDeliveryPhase 
                      ? DeliveryPhaseScreen(order: _order!)
                      : ActiveDeliveryScreen(order: _order!),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(buttonIcon, size: 24),
                const SizedBox(width: 12),
                Text(
                  buttonText,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlreadyTakenBanner() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Order already taken by another driver',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
