import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/features/driver/earning/widgets/earnings_overview_header.dart';
import 'package:flaride_driver/features/driver/earning/widgets/earnings_stat_card.dart';
import 'package:flaride_driver/features/driver/earning/widgets/weekly_earnings_chart.dart';
import 'package:flaride_driver/features/driver/earning/widgets/payout_card.dart';
import 'package:flaride_driver/features/driver/earning/widgets/error_view.dart';
import 'package:flaride_driver/features/driver/earning/screens/payout_request_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final DriverService _driverService = DriverService();
  
  EarningsSummary? _summary;
  PayoutInfo? _payoutInfo;
  List<Earning> _earnings = [];
  List<PayoutHistory> _payouts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final earningsResponse = await _driverService.getEarnings();
    final payoutsResponse = await _driverService.getPayoutHistory();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (earningsResponse.success) {
          _summary = earningsResponse.summary;
          _payoutInfo = earningsResponse.payoutInfo;
          _earnings = earningsResponse.earnings;
        } else {
          _error = earningsResponse.message;
        }
        if (payoutsResponse.success) {
          _payouts = payoutsResponse.payouts;
        }
      });
    }
  }

  void _navigateToPayoutRequest() async {
    if (_summary == null || _payoutInfo == null) return;
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PayoutRequestScreen(
          summary: _summary!,
          payoutInfo: _payoutInfo!,
        ),
      ),
    );

    if (result == true) {
      _loadEarnings();
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final padding = isSmallScreen ? 16.0 : 20.0;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (_error != null) {
      return ErrorView(
        errorMessage: _error!,
        onRetry: _loadEarnings,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEarnings,
      color: AppColors.primaryOrange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            EarningsOverviewHeader(
              summary: _summary,
              payoutInfo: _payoutInfo,
              isSmallScreen: isSmallScreen,
              onRequestPayout: _navigateToPayoutRequest,
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            Row(
              children: [
                Expanded(
                  child: EarningsStatCard(
                    label: 'Pending',
                    value: _summary?.pendingEarningsDisplay ?? '0 XOF',
                    icon: Icons.hourglass_empty_rounded,
                    iconColor: AppColors.primaryOrange,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EarningsStatCard(
                    label: 'Total paid',
                    value: _summary?.paidEarningsDisplay ?? '0 XOF',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.primaryOrange,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: EarningsStatCard(
                    label: 'Today',
                    value: _summary?.todayEarningsDisplay ?? '0 CFA',
                    icon: Icons.calendar_today_outlined,
                    iconColor: AppColors.primaryOrange,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EarningsStatCard(
                    label: 'Deliveries',
                    value: '${_summary?.totalDeliveries ?? 0}',
                    icon: Icons.shopping_bag_outlined,
                    iconColor: AppColors.primaryOrange,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tips and bonuses row
            Row(
              children: [
                Expanded(
                  child: EarningsStatCard(
                    label: 'Tips',
                    value: _summary?.totalTipsDisplay ?? '0 CFA',
                    icon: Icons.volunteer_activism,
                    iconColor: AppColors.primaryGreen,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EarningsStatCard(
                    label: 'Bonuses',
                    value: _summary?.totalBonusesDisplay ?? '0 CFA',
                    icon: Icons.card_giftcard,
                    iconColor: Colors.purple,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            Text(
              'Earnings Summary Trend',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            WeeklyEarningsChart(
              earnings: _earnings,
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            if (_payouts.isNotEmpty) ...[
              Text(
                'Payout History',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 12),
              ..._payouts.take(5).map(
                (payout) => PayoutCard(
                  payout: payout,
                  isSmallScreen: isSmallScreen,
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),
            ],
            // Text(
            //   'Recent Earnings',
            //   style: TextStyle(
            //     fontSize: isSmallScreen ? 16 : 18,
            //     fontWeight: FontWeight.w600,
            //     color: AppColors.darkGray,
            //   ),
            // ),
            // const SizedBox(height: 12),
            // if (_earnings.isEmpty)
            //   EmptyEarningsPlaceholder(isSmallScreen: isSmallScreen)
            // else
            //   ..._earnings.take(10).map(
            //     (earning) => EarningCard(
            //       earning: earning,
            //       isSmallScreen: isSmallScreen,
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}
