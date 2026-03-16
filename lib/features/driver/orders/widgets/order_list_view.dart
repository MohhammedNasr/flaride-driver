import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/features/driver/orders/widgets/order_history_card.dart';
import 'package:flaride_driver/features/driver/orders/widgets/order_empty_state.dart';
import 'package:flaride_driver/features/driver/orders/widgets/order_section_header.dart';

class OrderListView extends StatelessWidget {
  final List<HistoryOrder> orders;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final Function(HistoryOrder) onOrderTap;

  const OrderListView({
    required this.orders,
    required this.emptyMessage,
    required this.onRefresh,
    required this.onOrderTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (orders.isEmpty) {
      return OrderEmptyState(message: emptyMessage);
    }

    final groupedOrders = _groupOrdersByDate(orders);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: _calculateListItemCount(groupedOrders),
        itemBuilder: (context, index) {
          return _buildListItem(groupedOrders, index, isSmallScreen);
        },
      ),
    );
  }

  Map<String, List<HistoryOrder>> _groupOrdersByDate(List<HistoryOrder> orders) {
    final Map<String, List<HistoryOrder>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final order in orders) {
      final orderDate = order.createdAt;
      if (orderDate == null) continue;

      final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
      String key;

      if (orderDay == today) {
        key = 'Today';
      } else if (orderDay == yesterday) {
        key = 'Yesterday';
      } else {
        key = 'Earlier';
      }

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(order);
    }

    return grouped;
  }

  int _calculateListItemCount(Map<String, List<HistoryOrder>> groupedOrders) {
    int count = 0;
    for (final entry in groupedOrders.entries) {
      count += 1 + entry.value.length;
    }
    return count;
  }

  Widget _buildListItem(
    Map<String, List<HistoryOrder>> groupedOrders,
    int index,
    bool isSmallScreen,
  ) {
    int currentIndex = 0;

    for (final entry in groupedOrders.entries) {
      if (currentIndex == index) {
        return OrderSectionHeader(title: entry.key);
      }
      currentIndex++;

      final ordersInSection = entry.value;
      final orderIndexInSection = index - currentIndex;

      if (orderIndexInSection >= 0 &&
          orderIndexInSection < ordersInSection.length) {
        return OrderHistoryCard(
          order: ordersInSection[orderIndexInSection],
          onTap: () => onOrderTap(ordersInSection[orderIndexInSection]),
        );
      }

      currentIndex += ordersInSection.length;
    }

    return const SizedBox.shrink();
  }
}
