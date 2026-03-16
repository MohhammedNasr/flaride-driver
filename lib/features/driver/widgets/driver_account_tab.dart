import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/core/services/auth_provider.dart';
import 'package:flaride_driver/core/utils/responsive_utils.dart';
import 'package:flaride_driver/shared/widgets/profile_avatar.dart';
import 'package:flaride_driver/shared/widgets/profile_menu_item.dart';
import 'package:flaride_driver/shared/widgets/profile_section_container.dart';
import 'package:flaride_driver/features/driver/profile/screens/personal_info_screen.dart';
import 'package:flaride_driver/features/driver/profile/screens/vehicle_info_screen.dart';
import 'package:flaride_driver/features/driver/profile/screens/documents_screen.dart';
import 'package:flaride_driver/features/driver/profile/screens/payment_settings_screen.dart';
import 'package:flaride_driver/features/driver/profile/screens/settings_screen.dart';
import 'package:flaride_driver/features/driver/profile/screens/help_support_screen.dart';
import 'package:flaride_driver/features/driver/profile/screens/ratings_reviews_screen.dart';
import 'package:flaride_driver/app/app.dart' show signOutAndNavigateToLogin;

class DriverAccountTab extends StatelessWidget {
  final VoidCallback onLocationTap;

  const DriverAccountTab({
    super.key,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<DriverProvider, AuthProvider>(
      builder: (context, driverProvider, authProvider, child) {
        final driver = driverProvider.driver;

        return Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            padding: context.responsivePadding(
              mobile: const EdgeInsets.all(16),
              tablet: const EdgeInsets.all(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    height: context.responsiveValue(mobile: 8, tablet: 12)),
                Center(
                  child: Column(
                    children: [
                      ProfileAvatar(
                        imageUrl: driver?.profilePhoto,
                        name: driver?.name ?? 'Driver',
                        isVerified: driver?.isVerified ?? false,
                        size: context.scaleSize(100),
                      ),
                      SizedBox(
                          height:
                              context.responsiveValue(mobile: 16, tablet: 20)),
                      Text(
                        driver?.name ?? 'Driver',
                        style: GoogleFonts.poppins(
                          fontSize: context.scaleFontSize(20),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(
                          height:
                              context.responsiveValue(mobile: 4, tablet: 6)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            driver?.vehicleDescription ?? 'Vehicle',
                            style: GoogleFonts.poppins(
                              fontSize: context.scaleFontSize(12),
                              color: AppColors.midGray,
                            ),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Container(
                            width: 2,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.midGray,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            driver?.vehicleLicensePlate ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: context.scaleFontSize(12),
                              color: AppColors.midGray,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                          height:
                              context.responsiveValue(mobile: 12, tablet: 16)),
                      // Ratings display
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RatingsReviewsScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: AppColors.primaryOrange,
                                size: context.scaleFontSize(18),
                              ),
                              SizedBox(width: 4),
                              Text(
                                (driver?.averageRating ?? 0.0).toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: context.scaleFontSize(14),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '(${driver?.totalRatings ?? 0} reviews)',
                                style: GoogleFonts.poppins(
                                  fontSize: context.scaleFontSize(12),
                                  color: AppColors.midGray,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                color: AppColors.midGray,
                                size: context.scaleFontSize(16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                    height: context.responsiveValue(mobile: 32, tablet: 40)),
                ProfileSectionContainer(
                  children: [
                    ProfileMenuItem(
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
                      ),
                    ),
                    const Divider(
                        height: 1, thickness: 1, color: AppColors.dividerGray),
                    ProfileMenuItem(
                      icon: Icons.directions_car_outlined,
                      title: 'Vehicle Information',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VehicleInfoScreen()),
                      ),
                    ),
                    const Divider(
                        height: 1, thickness: 1, color: AppColors.dividerGray),
                    ProfileMenuItem(
                      icon: Icons.star_outline_rounded,
                      title: 'Ratings & Reviews',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RatingsReviewsScreen()),
                      ),
                    ),
                    const Divider(
                        height: 1, thickness: 1, color: AppColors.dividerGray),
                    ProfileMenuItem(
                      icon: Icons.description_outlined,
                      title: 'Documents Section',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                      ),
                    ),
                    const Divider(
                        height: 1, thickness: 1, color: AppColors.dividerGray),
                    ProfileMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Payment Settings',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PaymentSettingsScreen()),
                      ),
                    ),
                    const Divider(
                        height: 1, thickness: 1, color: AppColors.dividerGray),
                    ProfileMenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverSettingsScreen()),
                      ),
                    ),
                    const Divider(
                        height: 1, thickness: 1, color: AppColors.dividerGray),
                    ProfileMenuItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                    height: context.responsiveValue(mobile: 20, tablet: 40)),
                Align(
                  alignment: AlignmentGeometry.bottomCenter,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        driverProvider.clear();
                        await signOutAndNavigateToLogin(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical:
                              10,
                          horizontal:
                             12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: context.scaleFontSize(20),
                            ),
                            SizedBox(
                                width: context.responsiveValue(
                                    mobile: 12, tablet: 16)),
                            Text(
                              'Sign Out',
                              style: GoogleFonts.poppins(
                                fontSize: context.scaleFontSize(16),
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: context.scaleFontSize(24),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                    height: context.responsiveValue(mobile: 16, tablet: 24)),
              ],
            ),
          ),
        );
      },
    );
  }
}
