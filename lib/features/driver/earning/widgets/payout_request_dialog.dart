import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';

class PayoutRequestDialog extends StatelessWidget {
  final EarningsSummary? summary;
  final PayoutInfo? payoutInfo;

  const PayoutRequestDialog({
    super.key,
    required this.summary,
    required this.payoutInfo,
  });

  static Future<bool?> show(
    BuildContext context, {
    required EarningsSummary? summary,
    required PayoutInfo? payoutInfo,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => PayoutRequestDialog(
        summary: summary,
        payoutInfo: payoutInfo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final method = payoutInfo?.preferredMethod ?? 'mobile_money';

    return AlertDialog(
      title: Text(
        'Request Payout',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: isSmallScreen ? 16 : 18,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount: ${summary?.availableEarningsDisplay ?? '0 CFA'}',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Method: ${method == 'mobile_money' ? 'Mobile Money' : 'Bank Transfer'}',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 12 : 13,
              color: AppColors.midGray,
            ),
          ),
          if (payoutInfo?.mobileMoneyNumber != null)
            Text(
              'Account: ${payoutInfo!.mobileMoneyNumber}',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 12 : 13,
                color: AppColors.midGray,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: AppColors.midGray),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
          ),
          child: Text(
            'Confirm',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
