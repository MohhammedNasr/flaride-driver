import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class DriverBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const DriverBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryOrange,
        unselectedItemColor: AppColors.midGray,
        backgroundColor: AppColors.white,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 10 : 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 10 : 12,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: isSmallScreen ? 20 : 24),
            activeIcon: Icon(Icons.home, size: isSmallScreen ? 20 : 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined, size: isSmallScreen ? 20 : 24),
            activeIcon: Icon(Icons.receipt_long, size: isSmallScreen ? 20 : 24),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined, size: isSmallScreen ? 20 : 24),
            activeIcon: Icon(Icons.account_balance_wallet, size: isSmallScreen ? 20 : 24),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: isSmallScreen ? 20 : 24),
            activeIcon: Icon(Icons.person, size: isSmallScreen ? 20 : 24),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
