import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/core/services/order_acceptance_service.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/features/driver/home/widgets/map_order_card.dart';
import 'package:flaride_driver/features/driver/home/widgets/empty_orders_state.dart';
import 'package:flaride_driver/features/driver/home/widgets/bottom_sheet_handle.dart';

class AvailableOrdersBottomSheet extends StatefulWidget {
  final List<AvailableOrder> orders;
  final Function(AvailableOrder) onOrderTap;
  final Function(AvailableOrder)? onCardTap;

  const AvailableOrdersBottomSheet({
    super.key,
    required this.orders,
    required this.onOrderTap,
    this.onCardTap,
  });

  @override
  State<AvailableOrdersBottomSheet> createState() => _AvailableOrdersBottomSheetState();
}

class _AvailableOrdersBottomSheetState extends State<AvailableOrdersBottomSheet> {
  final DraggableScrollableController _controller = DraggableScrollableController();
  final OrderAcceptanceService _acceptanceService = OrderAcceptanceService();
  bool _isAccepting = false;
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _acceptOrder(AvailableOrder order) async {
    await _acceptanceService.acceptOrder(
      context: context,
      orderId: order.id,
      onAcceptingStateChanged: () {
        if (mounted) {
          setState(() => _isAccepting = !_isAccepting);
        }
      },
      onSuccess: () async {
        // Update driver provider to refresh available orders
        final driverProvider = Provider.of<DriverProvider>(context, listen: false);
        await driverProvider.fetchAvailableOrders();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.4, 0.85],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              const BottomSheetHandle(),
              Expanded(
                child: widget.orders.isEmpty
                    ? const EmptyOrdersState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: widget.orders.length,
                        itemBuilder: (context, index) {
                          final order = widget.orders[index];
                          return MapOrderCard(
                            order: order,
                            onDecline: () {
                              // Handle decline
                            },
                            onAccept: _isAccepting ? () {} : () {
                              _acceptOrder(order);
                            },
                            onCardTap: widget.onCardTap != null
                                ? () => widget.onCardTap!(order)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
