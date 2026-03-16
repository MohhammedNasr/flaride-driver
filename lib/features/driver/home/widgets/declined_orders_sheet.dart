import 'package:flutter/material.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class DeclinedOrdersSheet extends StatelessWidget {
  final List<AvailableOrder> declinedOrders;
  final Function(String) onRestore;

  const DeclinedOrdersSheet({
    super.key,
    required this.declinedOrders,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppColors.darkGray),
                const SizedBox(width: 12),
                Text(
                  'Declined Orders (${declinedOrders.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
                const Spacer(),
                if (declinedOrders.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Content
          if (declinedOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_return_outlined,
                    size: 48,
                    color: AppColors.lightGray,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No declined orders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.midGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Declined orders available for restoration\nwill appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.midGray,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: declinedOrders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final order = declinedOrders[index];
                  return _buildOrderRow(context, order);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(BuildContext context, AvailableOrder order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGray),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.lightGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.store, color: AppColors.darkGray, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.restaurant?.name ?? 'Restaurant',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.estimatedEarnings} • ${order.pickupDistanceKm ?? "0"} km',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.midGray,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onRestore(order.id);
              if (declinedOrders.length <= 1) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primaryOrange,
              elevation: 0,
              side: const BorderSide(color: AppColors.primaryOrange),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}
