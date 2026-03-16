import 'package:flutter/material.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import '../orders/widgets/order_history_tab_bar.dart';
import '../shared/widgets/order_history_shimmer.dart';
import '../orders/widgets/order_error_state.dart';
import '../orders/widgets/grouped_order_list_view.dart';
import '../orders/widgets/order_history_header.dart';
import '../orders/widgets/order_details_bottom_sheet.dart';

class OrderHistoryTab extends StatefulWidget {
  const OrderHistoryTab({super.key});

  @override
  State<OrderHistoryTab> createState() => _OrderHistoryTabState();
}

class _OrderHistoryTabState extends State<OrderHistoryTab>
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
        OrderHistoryHeader(
          isSmallScreen: isSmallScreen,
          padding: padding,
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
                  ? OrderErrorState(
                      errorMessage: _error,
                      onRetry: _loadOrderHistory,
                      isSmallScreen: isSmallScreen,
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        GroupedOrderListView(
                          orders: _activeOrders,
                          emptyMessage: 'No active orders',
                          onRefresh: _loadOrderHistory,
                          onOrderTap: _showOrderDetails,
                          isSmallScreen: isSmallScreen,
                        ),
                        GroupedOrderListView(
                          orders: _completedOrders,
                          emptyMessage: 'No completed orders yet',
                          onRefresh: _loadOrderHistory,
                          onOrderTap: _showOrderDetails,
                          isSmallScreen: isSmallScreen,
                        ),
                        GroupedOrderListView(
                          orders: _cancelledOrders,
                          emptyMessage: 'No cancelled orders',
                          onRefresh: _loadOrderHistory,
                          onOrderTap: _showOrderDetails,
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                    ),
        ),
      ],
    );
  }


  void _showOrderDetails(HistoryOrder order, bool isSmallScreen) {
    showOrderDetailsBottomSheet(
      context: context,
      order: order,
      isSmallScreen: isSmallScreen,
    );
  }
}
