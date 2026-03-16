import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/services/customer_wait_service.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class CustomerWaitTimerWidget extends StatefulWidget {
  final String orderId;
  final String authToken;
  final String orderStatus;
  final VoidCallback? onStatusChanged;

  const CustomerWaitTimerWidget({
    super.key,
    required this.orderId,
    required this.authToken,
    required this.orderStatus,
    this.onStatusChanged,
  });

  @override
  State<CustomerWaitTimerWidget> createState() => _CustomerWaitTimerWidgetState();
}

class _CustomerWaitTimerWidgetState extends State<CustomerWaitTimerWidget> {
  WaitStatus? _waitStatus;
  bool _loading = false;
  bool _actionLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (_shouldShowWaitTimer) {
      _loadWaitStatus();
      _startRefreshTimer();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  bool get _shouldShowWaitTimer {
    return widget.orderStatus == 'arrived_at_customer' ||
           widget.orderStatus == 'out_for_delivery' ||
           widget.orderStatus == 'picked_up';
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _shouldShowWaitTimer) {
        _loadWaitStatus();
      }
    });
  }

  Future<void> _loadWaitStatus() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final status = await CustomerWaitService.getWaitStatus(
        widget.orderId,
        widget.authToken,
      );
      if (mounted) {
        setState(() {
          _waitStatus = status;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleAction(String action) async {
    setState(() => _actionLoading = true);

    WaitActionResult result;
    switch (action) {
      case 'arrived':
        result = await CustomerWaitService.markArrived(
          widget.orderId,
          widget.authToken,
        );
        break;
      case 'contact':
        result = await CustomerWaitService.logContactAttempt(
          widget.orderId,
          widget.authToken,
        );
        break;
      case 'not_found':
        final confirmed = await _showConfirmDialog(
          'Mark Customer Not Found?',
          'This will end the delivery attempt and charge a wait fee of ${_waitStatus?.waitFeeDisplay ?? "0 CFA"}.',
        );
        if (!confirmed) {
          setState(() => _actionLoading = false);
          return;
        }
        result = await CustomerWaitService.markCustomerNotFound(
          widget.orderId,
          widget.authToken,
        );
        break;
      case 'resolved':
        result = await CustomerWaitService.markCustomerResolved(
          widget.orderId,
          widget.authToken,
        );
        break;
      default:
        setState(() => _actionLoading = false);
        return;
    }

    setState(() => _actionLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppColors.primaryGreen : Colors.red,
        ),
      );

      if (result.success) {
        _loadWaitStatus();
        widget.onStatusChanged?.call();
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Confirm', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowWaitTimer) return const SizedBox.shrink();

    if (_loading && _waitStatus == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_waitStatus == null || !_waitStatus!.isWaiting) {
      // Show "Mark Arrived" button if not yet arrived
      if (widget.orderStatus == 'out_for_delivery' || widget.orderStatus == 'picked_up') {
        return _buildArrivedButton();
      }
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getBorderColor(), width: 2),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getHeaderColor(),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(
                  _waitStatus!.isInFreePeriod ? Icons.timer : Icons.timer_off,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Wait Timer',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _getStatusText(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Timer display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_waitStatus!.waitMinutes} min',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getHeaderColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Progress bar
                _buildProgressBar(),
                const SizedBox(height: 16),

                // Fee info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      'Free Wait',
                      '${_waitStatus!.freeWaitMinutes} min',
                      Icons.access_time,
                    ),
                    _buildInfoItem(
                      'Wait Fee',
                      _waitStatus!.waitFeeDisplay,
                      Icons.attach_money,
                    ),
                    _buildInfoItem(
                      'Contacts',
                      '${_waitStatus!.contactAttempts}/${_waitStatus!.maxContactAttempts}',
                      Icons.phone,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrivedButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _actionLoading ? null : () => _handleAction('arrived'),
        icon: _actionLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.location_on),
        label: Text(
          'I\'ve Arrived at Customer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _waitStatus!.waitMinutes / _waitStatus!.maxWaitMinutes;
    final freeProgress = _waitStatus!.freeWaitMinutes / _waitStatus!.maxWaitMinutes;

    return Column(
      children: [
        Stack(
          children: [
            // Background
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Free zone indicator
            FractionallySizedBox(
              widthFactor: freeProgress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Progress
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: _getProgressColor(),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
            Text('${_waitStatus!.freeWaitMinutes} min (free)',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.green)),
            Text('${_waitStatus!.maxWaitMinutes} min (max)',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Contact customer button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _actionLoading ? null : () => _handleAction('contact'),
            icon: const Icon(Icons.phone),
            label: Text(
              'Log Contact Attempt (${_waitStatus!.contactAttempts}/${_waitStatus!.maxContactAttempts})',
              style: GoogleFonts.poppins(),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.primaryOrange),
              foregroundColor: AppColors.primaryOrange,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Customer found / not found buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _actionLoading ? null : () => _handleAction('resolved'),
                icon: const Icon(Icons.check_circle, size: 18),
                label: Text('Customer Found', style: GoogleFonts.poppins(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_actionLoading || !_waitStatus!.canMarkNotFound)
                    ? null
                    : () => _handleAction('not_found'),
                icon: const Icon(Icons.cancel, size: 18),
                label: Text(
                  _waitStatus!.canMarkNotFound
                      ? 'Not Found'
                      : '${_waitStatus!.minutesUntilNotFound}m left',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getBackgroundColor() {
    if (_waitStatus!.isInFreePeriod) return Colors.green[50]!;
    if (_waitStatus!.canMarkNotFound) return Colors.red[50]!;
    return Colors.orange[50]!;
  }

  Color _getBorderColor() {
    if (_waitStatus!.isInFreePeriod) return Colors.green;
    if (_waitStatus!.canMarkNotFound) return Colors.red;
    return Colors.orange;
  }

  Color _getHeaderColor() {
    if (_waitStatus!.isInFreePeriod) return Colors.green;
    if (_waitStatus!.canMarkNotFound) return Colors.red;
    return Colors.orange;
  }

  Color _getProgressColor() {
    if (_waitStatus!.isInFreePeriod) return Colors.green;
    if (_waitStatus!.canMarkNotFound) return Colors.red;
    return Colors.orange;
  }

  String _getStatusText() {
    if (_waitStatus!.isInFreePeriod) {
      return '${_waitStatus!.remainingFreeMinutes} min free remaining';
    }
    if (_waitStatus!.canMarkNotFound) {
      return 'Can mark as Customer Not Found';
    }
    return 'Charging ${_waitStatus!.feePerMinuteDisplay}';
  }
}
