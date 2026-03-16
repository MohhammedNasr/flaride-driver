import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/features/apply/driver_application_form_screen.dart';

class DriverApplyOnboardingScreen extends StatefulWidget {
  const DriverApplyOnboardingScreen({super.key});

  @override
  State<DriverApplyOnboardingScreen> createState() => _DriverApplyOnboardingScreenState();
}

class _DriverApplyOnboardingScreenState extends State<DriverApplyOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      icon: CupertinoIcons.clock,
      title: 'Set Your Own Hours',
      description: 'Work whenever you want. Be your own boss and choose the hours that suit your lifestyle.',
      color: AppColors.primaryOrange,
    ),
    OnboardingItem(
      icon: CupertinoIcons.money_dollar_circle,
      title: 'Earn On Your Terms',
      description: 'Competitive pay per delivery, plus tips and bonuses. Weekly payouts to your mobile money.',
      color: AppColors.primaryGreen,
    ),
    OnboardingItem(
      icon: CupertinoIcons.shield_fill,
      title: 'Safety First',
      description: '24/7 support, insurance coverage, and GPS tracking to keep you safe on every delivery.',
      color: const Color(0xFF2196F3),
    ),
    OnboardingItem(
      icon: CupertinoIcons.rocket,
      title: 'Easy to Get Started',
      description: 'Quick sign-up process. Just provide your info, upload documents, and start earning!',
      color: const Color(0xFF9C27B0),
    ),
  ];

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToForm();
    }
  }

  void _navigateToForm() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const DriverApplicationFormScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_currentPage < _items.length - 1)
            TextButton(
              onPressed: _navigateToForm,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.midGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _buildPage(_items[index]);
                },
              ),
            ),
            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primaryOrange
                          : AppColors.lightGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Main button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _items.length - 1
                            ? 'Start Application'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info text
                  Text(
                    'By continuing, you agree to our Terms of Service',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.midGray.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 70,
              color: item.color,
            ),
          ),
          const SizedBox(height: 48),
          // Title
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.midGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
