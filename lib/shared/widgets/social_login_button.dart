import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class SocialLoginButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;

  const SocialLoginButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }
}

class BrandedSocialRow extends StatelessWidget {
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  const BrandedSocialRow({super.key, required this.onGoogle, required this.onApple});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SocialLoginButton(icon: const FaIcon(FontAwesomeIcons.google, color: Color(0xFFDB4437), size: 22), onPressed: onGoogle),
        const SizedBox(width: 16),
        SocialLoginButton(icon: const FaIcon(FontAwesomeIcons.apple, color: Colors.black, size: 22), onPressed: onApple),
      ],
    );
  }
}


