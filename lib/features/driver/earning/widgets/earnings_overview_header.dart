import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/services/driver_service.dart';

class EarningsOverviewHeader extends StatelessWidget {
  final EarningsSummary? summary;
  final PayoutInfo? payoutInfo;
  final bool isSmallScreen;
  final VoidCallback? onRequestPayout;

  const EarningsOverviewHeader({
    super.key,
    required this.summary,
    required this.payoutInfo,
    required this.isSmallScreen,
    this.onRequestPayout,
  });

  @override
  Widget build(BuildContext context) {
    final canRequestPayout = payoutInfo?.canRequestPayout ?? false;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkOrange, AppColors.midOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              'Earning overview',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Available Balance (main focus)
          Text(
            'Available to withdraw',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary?.availableEarningsDisplay ?? '0 CFA',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 28 : 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Total earnings (smaller)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem(
                label: 'Total',
                value: summary?.totalEarningsDisplay ?? '0 CFA',
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildStatItem(
                label: 'Pending',
                value: summary?.pendingEarningsDisplay ?? '0 CFA',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Request Payout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canRequestPayout ? onRequestPayout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryOrange,
                disabledBackgroundColor: Colors.white.withOpacity(0.5),
                disabledForegroundColor: AppColors.midGray,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                canRequestPayout 
                    ? 'Request Payout' 
                    : 'Min ${payoutInfo?.minimumPayoutDisplay ?? '1,000 CFA'} to withdraw',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 11 : 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
