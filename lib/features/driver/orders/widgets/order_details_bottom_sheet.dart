import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';

void showOrderDetailsBottomSheet({
  required BuildContext context,
  required HistoryOrder order,
  required bool isSmallScreen,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _OrderDetailsBottomSheet(
      order: order,
      isSmallScreen: isSmallScreen,
    ),
  );
}

class _OrderDetailsBottomSheet extends StatelessWidget {
  final HistoryOrder order;
  final bool isSmallScreen;

  const _OrderDetailsBottomSheet({
    required this.order,
    required this.isSmallScreen,
  });

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.midGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 8 : 12),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 10 : 12,
                          vertical: isSmallScreen ? 5 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: _parseColor(order.statusColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          order.statusDisplay,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: _parseColor(order.statusColor),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '#${order.orderNumber}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  Text(
                    'Restaurant: ${order.restaurant?.name ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGray,
                    ),
                  ),
                  if (order.restaurant?.address != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      order.restaurant!.address!,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: AppColors.midGray,
                      ),
                    ),
                  ],
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Text(
                    'Customer: ${order.customer?.name ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGray,
                    ),
                  ),
                  if (order.deliveryAddress != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      order.deliveryAddress!,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: AppColors.midGray,
                      ),
                    ),
                  ],
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Earnings',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        Text(
                          order.driverEarningsDisplay,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
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
