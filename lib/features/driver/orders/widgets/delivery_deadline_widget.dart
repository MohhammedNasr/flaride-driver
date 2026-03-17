import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/delivery_deadline_service.dart';
import 'package:flaride_driver/shared/widgets/app_toast.dart';

class DeliveryDeadlineWidget extends StatefulWidget {
  final String orderId;
  final double? driverLat;
  final double? driverLng;
  final VoidCallback? onDeadlineApproaching;
  final VoidCallback? onDeadlinePassed;

  const DeliveryDeadlineWidget({
    super.key,
    required this.orderId,
    this.driverLat,
    this.driverLng,
    this.onDeadlineApproaching,
    this.onDeadlinePassed,
  });

  @override
  State<DeliveryDeadlineWidget> createState() => _DeliveryDeadlineWidgetState();
}

class _DeliveryDeadlineWidgetState extends State<DeliveryDeadlineWidget> {
  final DeliveryDeadlineService _service = DeliveryDeadlineService();
  Timer? _timer;
  DeadlineStatus? _status;
  bool _loading = true;
  bool _hasAlerted = false;
  bool _hasCriticalAlert = false;
  int _localSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _fetchDeadlineStatus();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_localSecondsRemaining > 0) {
        setState(() {
          _localSecondsRemaining--;
        });
      }
      
      // Refresh from server every 30 seconds
      if (timer.tick % 30 == 0) {
        _fetchDeadlineStatus();
      }

      // Check for alerts
      _checkAlerts();
    });
  }

  Future<void> _fetchDeadlineStatus() async {
    try {
      final status = await _service.getDeadlineStatus(
        widget.orderId,
        driverLat: widget.driverLat,
        driverLng: widget.driverLng,
      );
      
      if (mounted) {
        setState(() {
          _status = status;
          _localSecondsRemaining = status.deadline.secondsRemaining;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _checkAlerts() {
    if (_status == null) return;

    // Approaching deadline alert
    if (_status!.deadline.isApproaching && !_hasAlerted) {
      _hasAlerted = true;
      HapticFeedback.heavyImpact();
      widget.onDeadlineApproaching?.call();
    }

    // Critical/late alert
    if (_status!.deadline.isLate && !_hasCriticalAlert) {
      _hasCriticalAlert = true;
      HapticFeedback.vibrate();
      widget.onDeadlinePassed?.call();
    }
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor() {
    if (_status == null) return AppColors.primaryOrange;
    if (_status!.deadline.isLate) return Colors.red;
    if (_status!.deadline.isAtRisk) return Colors.orange;
    if (_localSecondsRemaining < 600) return Colors.amber; // Less than 10 min
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingState();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Deadline countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Deadline',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _status?.deadline.isLate == true
                            ? Icons.warning_rounded
                            : Icons.timer_outlined,
                        color: _getStatusColor(),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _status?.deadline.isLate == true
                            ? 'LATE by ${_status!.deadline.delayMinutes} min'
                            : _formatTime(_localSecondsRemaining),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          if (_status?.alerts.warningMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _getStatusColor(),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _status!.alerts.warningMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ETA breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEtaItem(
                icon: Icons.restaurant,
                label: 'Prep',
                value: _status?.eta.foodReady == true
                    ? 'Ready'
                    : '${_status?.eta.prepMinutes ?? 0} min',
                isReady: _status?.eta.foodReady == true,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              _buildEtaItem(
                icon: Icons.directions_car,
                label: 'Travel',
                value: '${_status?.eta.travelMinutes ?? 0} min',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              _buildEtaItem(
                icon: Icons.schedule,
                label: 'Total ETA',
                value: '${_status?.eta.totalMinutes ?? 0} min',
              ),
            ],
          ),

          // Notify delay button if late
          if (_status?.deadline.isLate == true) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _notifyCustomerDelay,
                icon: const Icon(Icons.notifications_active, size: 18),
                label: Text(
                  'Notify Customer of Delay',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildEtaItem({
    required IconData icon,
    required String label,
    required String value,
    bool isReady = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isReady ? Colors.green : Colors.grey[600],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isReady ? Colors.green : Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    if (_status?.deadline.isLate == true) return 'LATE';
    if (_status?.deadline.isAtRisk == true) return 'AT RISK';
    if (_localSecondsRemaining < 600) return 'HURRY';
    return 'ON TIME';
  }

  Future<void> _notifyCustomerDelay() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notify Customer?'),
        content: const Text(
          'This will send a notification to the customer about the delivery delay. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Notify'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _service.notifyDelay(widget.orderId);
      if (mounted) {
        if (success) {
          AppToast.success(context, 'Customer notified');
        } else {
          AppToast.error(context, 'Failed to notify customer');
        }
      }
    }
  }
}

/// Compact version for order cards
class DeadlineCountdownCompact extends StatefulWidget {
  final String orderId;
  final DateTime? deadline;
  final bool isAtRisk;
  final bool isLate;

  const DeadlineCountdownCompact({
    super.key,
    required this.orderId,
    this.deadline,
    this.isAtRisk = false,
    this.isLate = false,
  });

  @override
  State<DeadlineCountdownCompact> createState() => _DeadlineCountdownCompactState();
}

class _DeadlineCountdownCompactState extends State<DeadlineCountdownCompact> {
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemaining() {
    if (widget.deadline == null) return;
    final diff = widget.deadline!.difference(DateTime.now());
    _secondsRemaining = diff.inSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final isLate = _secondsRemaining < 0 || widget.isLate;
    final isAtRisk = _secondsRemaining < 900 || widget.isAtRisk; // 15 min
    
    Color color = Colors.green;
    if (isLate) color = Colors.red;
    else if (isAtRisk) color = Colors.orange;

    final minutes = (_secondsRemaining.abs() ~/ 60);
    final seconds = (_secondsRemaining.abs() % 60);
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLate ? Icons.warning_rounded : Icons.timer,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isLate ? '-$timeStr' : timeStr,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
