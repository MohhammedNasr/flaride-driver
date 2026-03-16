import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class HomeOnlineToggle extends StatelessWidget {
  final bool isOnline;
  final bool isLoading;
  final VoidCallback onToggle;
  final String? profilePictureUrl;

  const HomeOnlineToggle({
    super.key,
    required this.isOnline,
    required this.isLoading,
    required this.onToggle,
    this.profilePictureUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isOnline ? AppColors.primaryGreen : AppColors.darkGray,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isOnline 
                    ? AppColors.white.withOpacity(0.2) 
                    : AppColors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                    ? Image.network(
                        profilePictureUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          color: AppColors.white,
                          size: 20,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: AppColors.white,
                        size: 20,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOnline ? "You're Online" : "You're Offline",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    isOnline ? 'Tap to go offline' : 'Tap to go online',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(
                Icons.search,
                color: AppColors.white.withOpacity(0.8),
                size: 24,
              ),
            const SizedBox(width: 12),
            Container(
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                color: isOnline 
                    ? AppColors.white.withOpacity(0.3) 
                    : AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isOnline ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
