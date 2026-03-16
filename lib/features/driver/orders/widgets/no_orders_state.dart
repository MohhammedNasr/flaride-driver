import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/constants/app_assets.dart';

class NoOrdersState extends StatelessWidget {
  final bool isOnline;
  const NoOrdersState({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            SvgPicture.asset(
              AppAssets.noAvailableOrders,
              width: isSmallScreen ? 160 : 200,
              height: isSmallScreen ? 160 : 200,
            ),
            SizedBox(height: isSmallScreen ? 12 : 24),
            Text(
              isOnline ? 'No orders at the moment.' : "You are offline.",
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.darkGray,
                ),
                children: [
                  if (!isOnline) ...[
                    const TextSpan(text: "Tap "),
                    TextSpan(
                      text: "Go Online",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const TextSpan(text: " to start accepting deliveries"),
                  ] else ...[
                    const TextSpan(
                        text: "Stay online to receive incoming orders"),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
