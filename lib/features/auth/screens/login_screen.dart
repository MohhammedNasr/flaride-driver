import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/auth_provider.dart';
import 'package:flaride_driver/core/services/biometric_service.dart';
import 'package:flaride_driver/core/services/secure_storage_service.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/features/driver/driver_home_page.dart';
import 'package:flaride_driver/features/driver/driver_set_password_screen.dart';
import 'package:flaride_driver/features/auth/screens/forgot_password_screen.dart';
import 'package:flaride_driver/features/apply/driver_apply_onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverLoginScreen extends StatefulWidget {
  static const String routeName = '/driver-login';
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final BiometricService _biometricService = BiometricService();
  final SecureStorageService _secureStorage = SecureStorageService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  bool _canUseBiometrics = false;
  bool _hasSavedCredentials = false;
  String _biometricTypeName = 'Biometrics';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final isSupported = await _biometricService.isDeviceSupported();
    final canCheck = await _biometricService.canCheckBiometrics();
    final isEnabled = await _biometricService.isBiometricEnabled();
    final savedEmail = await _secureStorage.getUserEmail();
    final savedToken = await _secureStorage.getToken();
    final biometricName = await _biometricService.getBiometricTypeName();
    
    if (mounted) {
      setState(() {
        _canUseBiometrics = isSupported && canCheck && isEnabled;
        _hasSavedCredentials = savedEmail != null && savedToken != null;
        _biometricTypeName = biometricName;
      });
      
      // Auto-trigger biometric login if available
      if (_canUseBiometrics && _hasSavedCredentials) {
        _handleBiometricLogin();
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to sign in to FlaRide Driver',
      );

      if (!authenticated) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Validate the stored token
      final token = await _secureStorage.getToken();
      final role = await _secureStorage.getUserRole();

      if (token == null || role != 'driver') {
        setState(() {
          _error = 'Please sign in with your email and password first.';
          _isLoading = false;
        });
        return;
      }

      // Check driver status and navigate
      if (!mounted) return;
      
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      final isDriver = await driverProvider.checkDriverStatus();

      if (!mounted) return;

      if (isDriver) {
        // Check if driver must change temp password after biometric login
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.mustChangePassword) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DriverSetPasswordScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DriverHomePage()),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _error = 'Session expired. Please sign in again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Biometric authentication failed. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        identifier: email,
        password: password,
      );

      if (!mounted) return;

      if (authProvider.isSignedIn) {
        // Check if user is a driver
        final prefs = await SharedPreferences.getInstance();
        final userRole = prefs.getString('user_role');

        if (userRole != 'driver') {
          setState(() {
            _error = 'This app is for delivery partners only. Please use the customer app.';
            _isLoading = false;
          });
          // Clear auth state
          await authProvider.logout();
          return;
        }

        // Check driver status
        final driverProvider = Provider.of<DriverProvider>(context, listen: false);
        final isDriver = await driverProvider.checkDriverStatus();

        if (!mounted) return;

        if (isDriver) {
          // Check if driver is active
          final driver = driverProvider.driver;
          if (driver != null && driver.isActive == false) {
            setState(() {
              _error = 'Your driver account is inactive. Please contact support to reactivate your account.';
              _isLoading = false;
            });
            await authProvider.logout();
            return;
          }
          
          // Check if driver must change temp password
          if (authProvider.mustChangePassword) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DriverSetPasswordScreen()),
              (route) => false,
            );
            return;
          }
          
          // Enable biometrics for future logins if available
          final isSupported = await _biometricService.isDeviceSupported();
          final canCheck = await _biometricService.canCheckBiometrics();
          if (isSupported && canCheck) {
            await _biometricService.setBiometricEnabled(true);
          }
          
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DriverHomePage()),
            (route) => false,
          );
        } else {
          setState(() {
            _error = 'Your driver account is not yet approved. Please wait for approval or contact support.';
            _isLoading = false;
          });
          await authProvider.logout();
        }
      } else {
        setState(() {
          _error = authProvider.error ?? 'Login failed. Please check your credentials.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: size.height * 0.08),
                        // Logo
                        Center(
                          child: Image.asset(
                            'assets/app_icon.png',
                            width: 100,
                            height: 100,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Welcome text
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.midGray.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Email field
                        _buildTextField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          hint: 'Email',
                          icon: CupertinoIcons.mail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 16),
                        // Password field
                        _buildTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          hint: 'Password',
                          icon: CupertinoIcons.lock,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 16),
                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                            ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Error message
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Sign in button
                        _buildPrimaryButton(
                          label: 'Sign in',
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                        ),
                        // Biometric login
                        if (_canUseBiometrics && _hasSavedCredentials) ...[
                          const SizedBox(height: 20),
                          Center(
                            child: GestureDetector(
                              onTap: _isLoading ? null : _handleBiometricLogin,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.lightGray, width: 2),
                                ),
                                child: Icon(
                                  _biometricTypeName == 'Face ID'
                                      ? CupertinoIcons.person_crop_circle
                                      : Icons.fingerprint,
                                  size: 32,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
                        // Apply to become a driver
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'New to FlaRide? ',
                              style: TextStyle(
                                color: AppColors.midGray.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const DriverApplyOnboardingScreen()),
                              ),
                              child: const Text(
                                'Apply now',
                                style: TextStyle(
                                  color: AppColors.primaryOrange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword && _obscurePassword,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontSize: 16, color: AppColors.darkGray),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.midGray.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: AppColors.midGray, size: 20),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                    color: AppColors.midGray,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: isLoading ? AppColors.primaryOrange.withOpacity(0.7) : AppColors.primaryOrange,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
