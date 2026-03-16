import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';

class HomeOrderCard extends StatelessWidget {
  final AvailableOrder order;
  final int secondsRemaining;
  final VoidCallback onDecline;
  final VoidCallback onAccept;
  final VoidCallback? onClose;

  const HomeOrderCard({
    super.key,
    required this.order,
    required this.secondsRemaining,
    required this.onDecline,
    required this.onAccept,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final totalDistance = _getTotalDistance();
    final estimatedTime = _getEstimatedTime();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEarningsSection(),
                  const SizedBox(height: 12),
                  _buildTimeDistanceRow(estimatedTime, totalDistance),
                  const SizedBox(height: 16),
                  _buildLocationTimeline(),
                  const SizedBox(height: 16),
                  _buildCountdownSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.restaurant,
                  color: AppColors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Delivery',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: Icon(
                Icons.close,
                color: AppColors.midGray,
                size: 24,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildEarningsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.estimatedEarnings,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGray,
          ),
        ),
        Text(
          'including estimated tip',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.midGray,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDistanceRow(String time, String distance) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          color: AppColors.midGray,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          '$time ($distance) total',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.darkGray,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationTimeline() {
    return Column(
      children: [
        _buildLocationRow(
          icon: Icons.circle,
          iconColor: AppColors.darkGray,
          iconSize: 10,
          title: order.restaurant?.name ?? 'Restaurant',
          subtitle: order.restaurant?.address ?? '',
          isPickup: true,
        ),
        _buildTimelineLine(),
        _buildLocationRow(
          icon: Icons.circle_outlined,
          iconColor: AppColors.midGray,
          iconSize: 10,
          title: order.deliveryAddress ?? 'Destination',
          subtitle: '',
          isPickup: false,
        ),
      ],
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required double iconSize,
    required String title,
    required String subtitle,
    required bool isPickup,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: iconSize,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.midGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: Container(
              width: 2,
              height: 24,
              color: AppColors.lightGray,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownSection() {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final progress = secondsRemaining / 38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Respond in ',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.midGray,
                  ),
                ),
                Text(
                  timeString,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
            Text(
              '${secondsRemaining}s left',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.midGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.lightGray,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onDecline,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.lightGray, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Decline',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Accept Order',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEstimatedTime() {
    final pickupDistance = double.tryParse(order.pickupDistanceKm ?? '0') ?? 0;
    final deliveryDistance = double.tryParse(order.deliveryDistanceKm ?? '0') ?? 0;
    final totalDistance = pickupDistance + deliveryDistance;
    final estimatedMinutes = (totalDistance * 3).round();
    return '$estimatedMinutes min';
  }

  String _getTotalDistance() {
    final pickupDistance = double.tryParse(order.pickupDistanceKm ?? '0') ?? 0;
    final deliveryDistance = double.tryParse(order.deliveryDistanceKm ?? '0') ?? 0;
    final totalDistance = pickupDistance + deliveryDistance;
    return '${totalDistance.toStringAsFixed(1)} km';
  }
}
