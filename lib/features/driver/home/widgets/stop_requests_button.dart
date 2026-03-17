import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/stop_requests_service.dart';
import 'package:flaride_driver/shared/widgets/app_toast.dart';

class StopRequestsButton extends StatefulWidget {
  final VoidCallback? onStatusChanged;

  const StopRequestsButton({
    super.key,
    this.onStatusChanged,
  });

  @override
  State<StopRequestsButton> createState() => _StopRequestsButtonState();
}

class _StopRequestsButtonState extends State<StopRequestsButton> {
  final StopRequestsService _service = StopRequestsService();
  bool _isStoppped = false;
  bool _loading = false;
  DateTime? _autoResumeAt;
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _service.getStatus();
      if (mounted) {
        setState(() {
          _isStoppped = status.stopNewRequests;
          _autoResumeAt = status.autoResumeRequestsAt;
          if (_autoResumeAt != null) {
            _startTimer();
          }
        });
      }
    } catch (e) {
      // Silently fail on initial load
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _updateSecondsRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateSecondsRemaining();
    });
  }

  void _updateSecondsRemaining() {
    if (_autoResumeAt == null) {
      _timer?.cancel();
      return;
    }
    final diff = _autoResumeAt!.difference(DateTime.now());
    if (diff.inSeconds <= 0) {
      _timer?.cancel();
      setState(() {
        _isStoppped = false;
        _autoResumeAt = null;
        _secondsRemaining = 0;
      });
      widget.onStatusChanged?.call();
    } else {
      setState(() {
        _secondsRemaining = diff.inSeconds;
      });
    }
  }

  Future<void> _toggleStopRequests() async {
    if (_loading) return;

    HapticFeedback.mediumImpact();

    if (_isStoppped) {
      // Resume requests immediately
      await _resumeRequests();
    } else {
      // Show dialog to stop requests
      _showStopRequestsDialog();
    }
  }

  Future<void> _resumeRequests() async {
    setState(() => _loading = true);
    try {
      await _service.resumeRequests();
      _timer?.cancel();
      setState(() {
        _isStoppped = false;
        _autoResumeAt = null;
        _secondsRemaining = 0;
      });
      widget.onStatusChanged?.call();
      if (mounted) {
        AppToast.success(context, 'You are now accepting new requests');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showStopRequestsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StopRequestsBottomSheet(
        onConfirm: (autoResumeMinutes) async {
          Navigator.pop(context);
          await _stopRequests(autoResumeMinutes);
        },
      ),
    );
  }

  Future<void> _stopRequests(int? autoResumeMinutes) async {
    setState(() => _loading = true);
    try {
      final status = await _service.stopRequests(
        autoResumeMinutes: autoResumeMinutes,
      );
      setState(() {
        _isStoppped = true;
        _autoResumeAt = status.autoResumeRequestsAt;
        if (_autoResumeAt != null) {
          _startTimer();
        }
      });
      widget.onStatusChanged?.call();
      if (mounted) {
        AppToast.warning(context, autoResumeMinutes != null
            ? 'Paused for $autoResumeMinutes minutes'
            : 'New requests paused');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    if (min > 0) {
      return '$min:${sec.toString().padLeft(2, '0')}';
    }
    return '0:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleStopRequests,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isStoppped ? Colors.red : Colors.white,
              border: Border.all(
                color: _isStoppped ? Colors.red : Colors.red.shade200,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isStoppped ? Colors.red : Colors.grey).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Icon(
                    _isStoppped ? Icons.play_arrow_rounded : Icons.pan_tool_rounded,
                    size: 32,
                    color: _isStoppped ? Colors.white : Colors.red,
                  ),
          ),
          const SizedBox(height: 6),
          // Label
          Text(
            _isStoppped
                ? (_secondsRemaining > 0 ? _formatTime(_secondsRemaining) : 'RESUME')
                : 'STOP NEW REQUESTS',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _isStoppped ? Colors.red : Colors.red.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StopRequestsBottomSheet extends StatefulWidget {
  final Function(int?) onConfirm;

  const _StopRequestsBottomSheet({required this.onConfirm});

  @override
  State<_StopRequestsBottomSheet> createState() => _StopRequestsBottomSheetState();
}

class _StopRequestsBottomSheetState extends State<_StopRequestsBottomSheet> {
  int? _selectedMinutes;

  final List<Map<String, dynamic>> _options = [
    {'label': '15 minutes', 'value': 15},
    {'label': '30 minutes', 'value': 30},
    {'label': '1 hour', 'value': 60},
    {'label': '2 hours', 'value': 120},
    {'label': 'Until I resume', 'value': null},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade50,
                ),
                child: Icon(
                  Icons.pan_tool_rounded,
                  size: 40,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'Stop New Requests',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You won\'t receive new delivery requests.\nYour current deliveries will not be affected.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              // Duration options
              Text(
                'Pause for:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _options.map((option) {
                  final isSelected = _selectedMinutes == option['value'];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMinutes = option['value']);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.red : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        option['label'],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onConfirm(_selectedMinutes),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Stop Requests',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact version for bottom navigation bar
class StopRequestsCompactButton extends StatefulWidget {
  final VoidCallback? onStatusChanged;

  const StopRequestsCompactButton({
    super.key,
    this.onStatusChanged,
  });

  @override
  State<StopRequestsCompactButton> createState() => _StopRequestsCompactButtonState();
}

class _StopRequestsCompactButtonState extends State<StopRequestsCompactButton> {
  final StopRequestsService _service = StopRequestsService();
  bool _isStopped = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _service.getStatus();
      if (mounted) {
        setState(() => _isStopped = status.stopNewRequests);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        // Show full stop requests button in a bottom sheet
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StopRequestsButton(
                  onStatusChanged: () {
                    _loadStatus();
                    widget.onStatusChanged?.call();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
      icon: Icon(
        _isStopped ? Icons.play_circle_outline : Icons.pan_tool_outlined,
        color: _isStopped ? Colors.green : Colors.red.shade400,
        size: 28,
      ),
      tooltip: _isStopped ? 'Resume requests' : 'Stop new requests',
    );
  }
}
