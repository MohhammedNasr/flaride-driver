import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class CancelParcelDialog extends StatefulWidget {
  final Function(String reason) onCancel;
  final VoidCallback onKeep;

  const CancelParcelDialog({super.key, required this.onCancel, required this.onKeep});

  @override
  State<CancelParcelDialog> createState() => _CancelParcelDialogState();
}

class _CancelParcelDialogState extends State<CancelParcelDialog> {
  String? _selectedReason;

  final List<String> _reasons = [
    "Passenger didn't show up",
    'Too much luggage',
    'Vehicle issue',
    'Wrong address',
    'Safety concern',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cancel Trip',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.darkGray),
          ),
          const SizedBox(height: 8),
          Text(
            'Please select a reason for cancelling this trip. This helps us improve the service.',
            style: TextStyle(fontSize: 14, color: AppColors.midGray, height: 1.4),
          ),
          const SizedBox(height: 20),
          ..._reasons.map((reason) => _buildReasonTile(reason)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onKeep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.primaryOrange, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Keep trip',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryOrange),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedReason == null
                      ? null
                      : () => widget.onCancel(_selectedReason!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    disabledBackgroundColor: AppColors.lightGray,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Confirm',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _selectedReason == null ? AppColors.midGray : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonTile(String reason) {
    final isSelected = _selectedReason == reason;
    return InkWell(
      onTap: () => setState(() => _selectedReason = reason),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.lightGray, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reason,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.darkGray),
              ),
            ),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryOrange : AppColors.midGray,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
