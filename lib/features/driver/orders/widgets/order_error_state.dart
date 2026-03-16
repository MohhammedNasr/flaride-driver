import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class OrderErrorState extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;
  final bool isSmallScreen;

  const OrderErrorState({
    super.key,
    this.errorMessage,
    required this.onRetry,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
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
            errorMessage ?? 'Failed to load orders',
            style: TextStyle(
              color: AppColors.midGray,
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
