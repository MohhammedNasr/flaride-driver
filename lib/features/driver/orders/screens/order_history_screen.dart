import 'package:flaride_driver/features/driver/orders/widgets/order_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/shared/widgets/app_toast.dart';
import 'package:flaride_driver/features/driver/orders/widgets/order_history_tab_bar.dart';
import 'package:flaride_driver/features/driver/shared/widgets/order_history_shimmer.dart';
import 'package:flaride_driver/features/driver/orders/widgets/order_details_bottom_sheet.dart';
import 'package:flaride_driver/features/driver/active_delivery_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  final DriverService _driverService = DriverService();
  late TabController _tabController;

  List<HistoryOrder> _allOrders = [];
  List<HistoryOrder> _activeOrders = [];
  List<HistoryOrder> _completedOrders = [];
  List<HistoryOrder> _cancelledOrders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrderHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _driverService.getOrderHistory();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success) {
          _allOrders = response.orders;
          _activeOrders = _allOrders.where((o) => o.isActive).toList();
          _completedOrders = _allOrders.where((o) => o.isCompleted).toList();
          _cancelledOrders = _allOrders.where((o) => o.isCancelled).toList();
        } else {
          _error = response.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final padding = isSmallScreen ? 16.0 : 20.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: Align(
            alignment: AlignmentGeometry.topLeft,
            child: Text(
              'Order History',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
          ),
        ),
        OrderHistoryTabBar(
          controller: _tabController,
          activeCount: _activeOrders.length,
          completedCount: _completedOrders.length,
          cancelledCount: _cancelledOrders.length,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const OrderHistoryShimmer()
              : _error != null
                  ? _buildErrorState(isSmallScreen)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        OrderListView(
                          orders: _activeOrders,
                          emptyMessage: 'No active orders',
                          onRefresh: _loadOrderHistory,
                          onOrderTap: _showOrderDetails,
                        ),
                        OrderListView(
                          orders: _completedOrders,
                          emptyMessage: 'No completed orders yet',
                          onRefresh: _loadOrderHistory,
                          onOrderTap: _showOrderDetails,
                        ),
                        OrderListView(
                          orders: _cancelledOrders,
                          emptyMessage: 'No cancelled orders',
                          onRefresh: _loadOrderHistory,
                          onOrderTap: _showOrderDetails,
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: isSmallScreen ? 40 : 48,
            color: AppColors.midGray,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Failed to load orders',
            style: TextStyle(
              color: AppColors.midGray,
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrderHistory,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(HistoryOrder order) async {
    // For active orders, navigate to ActiveDeliveryScreen
    if (order.isActive) {
      await _navigateToActiveDelivery(order);
    } else {
      // For completed/cancelled orders, show bottom sheet
      final screenWidth = MediaQuery.of(context).size.width;
      final isSmallScreen = screenWidth < 360;
      
      showOrderDetailsBottomSheet(
        context: context,
        order: order,
        isSmallScreen: isSmallScreen,
      );
    }
  }

  Future<void> _navigateToActiveDelivery(HistoryOrder order) async {
    // Fetch full order details for the active delivery screen
    final response = await _driverService.getOrderDetails(order.id);
    
    if (response.success && response.order != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveDeliveryScreen(order: response.order!),
        ),
      );
      
      // Refresh order history after returning
      if (mounted) {
        _loadOrderHistory();
      }
    } else if (mounted) {
      AppToast.error(context, response.message ?? 'Failed to load order details');
    }
  }
}
