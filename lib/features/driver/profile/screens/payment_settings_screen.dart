import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/shared/widgets/app_toast.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final DriverService _driverService = DriverService();
  
  String _selectedMethod = 'mobile_money';
  String? _selectedProvider;
  final _accountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankBranchController = TextEditingController();
  
  bool _isEditing = false;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _mobileMoneyProviders = [
    {'id': 'orange_money', 'name': 'Orange Money', 'color': Color(0xFFFF7900)},
    {'id': 'mtn_money', 'name': 'MTN Mobile Money', 'color': Color(0xFFFFCC00)},
    {'id': 'moov_money', 'name': 'Moov Money', 'color': Color(0xFF0099CC)},
    {'id': 'wave', 'name': 'Wave', 'color': Color(0xFF00D9A3)},
  ];

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  void _loadPaymentData() {
    final driver = context.read<DriverProvider>().driver;
    if (driver != null) {
      if (driver.mobileMoneyNumber != null) {
        _selectedMethod = 'mobile_money';
        _selectedProvider = driver.mobileMoneyProvider;
      } else if (driver.bankAccountNumber != null) {
        _selectedMethod = 'bank_transfer';
        _bankNameController.text = driver.bankName ?? '';
      }
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _bankNameController.dispose();
    _bankBranchController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMethod == 'mobile_money' && _selectedProvider == null) {
      AppToast.warning(context, 'Please select a mobile money provider');
      return;
    }

    setState(() => _isSaving = true);

    final success = await _driverService.updatePaymentSettings(
      preferredMethod: _selectedMethod,
      mobileMoneyNumber: _selectedMethod == 'mobile_money' ? _accountController.text.trim() : null,
      mobileMoneyProvider: _selectedMethod == 'mobile_money' ? _selectedProvider : null,
      bankAccount: _selectedMethod == 'bank_transfer' ? _accountController.text.trim() : null,
      bankName: _selectedMethod == 'bank_transfer' ? _bankNameController.text.trim() : null,
      bankBranch: _selectedMethod == 'bank_transfer' ? _bankBranchController.text.trim() : null,
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      await context.read<DriverProvider>().refreshProfile();
      setState(() => _isEditing = false);
      AppToast.success(context, 'Payment settings updated successfully');
    } else if (mounted) {
      AppToast.error(context, 'Failed to update payment settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Payment Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: Text(
                'Edit',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Consumer<DriverProvider>(
        builder: (context, driverProvider, child) {
          final driver = driverProvider.driver;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: AppColors.primaryGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Set up your payout method to receive earnings from completed deliveries.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Payout Info
                  if (!_isEditing && driver != null) ...[
                    _buildCurrentPayoutInfo(driver),
                    const SizedBox(height: 24),
                  ],

                  // Payment Method Selection (when editing)
                  if (_isEditing) ...[
                    Text(
                      'Payment Method',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMethodOption(
                            id: 'mobile_money',
                            label: 'Mobile Money',
                            icon: Icons.phone_android,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMethodOption(
                            id: 'bank_transfer',
                            label: 'Bank Transfer',
                            icon: Icons.account_balance,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Mobile Money Fields
                    if (_selectedMethod == 'mobile_money') ...[
                      Text(
                        'Select Provider',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _mobileMoneyProviders.map((provider) {
                          final isSelected = _selectedProvider == provider['id'];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedProvider = provider['id']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (provider['color'] as Color).withOpacity(0.15)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? provider['color'] as Color : AppColors.lightGray,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                provider['name'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? provider['color'] as Color : AppColors.darkGray,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _accountController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter phone number',
                          prefixIcon: const Icon(Icons.phone, color: AppColors.midGray),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.lightGray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.lightGray),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryOrange),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          if (value.length < 8) {
                            return 'Invalid phone number';
                          }
                          return null;
                        },
                      ),
                    ],

                    // Bank Transfer Fields
                    if (_selectedMethod == 'bank_transfer') ...[
                      TextFormField(
                        controller: _bankNameController,
                        decoration: InputDecoration(
                          labelText: 'Bank Name',
                          hintText: 'Enter bank name',
                          prefixIcon: const Icon(Icons.account_balance, color: AppColors.midGray),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.lightGray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.lightGray),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryOrange),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bank name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bankBranchController,
                        decoration: InputDecoration(
                          labelText: 'Branch (Optional)',
                          hintText: 'Enter branch name',
                          prefixIcon: const Icon(Icons.location_on, color: AppColors.midGray),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.lightGray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.lightGray),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryOrange),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _accountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Account Number',
                          hintText: 'Enter account number',
                          prefixIcon: const Icon(Icons.credit_card, color: AppColors.midGray),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.lightGray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.lightGray),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryOrange),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Account number is required';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _loadPaymentData();
                              setState(() => _isEditing = false);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.midGray),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: AppColors.darkGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Save',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentPayoutInfo(driver) {
    final hasMobileMoney = driver.mobileMoneyNumber != null;
    final hasBank = driver.bankAccountNumber != null;
    final hasPaymentMethod = hasMobileMoney || hasBank;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Payout Method',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          if (!hasPaymentMethod)
            Center(
              child: Column(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.midGray),
                  const SizedBox(height: 8),
                  Text(
                    'No payment method set up',
                    style: GoogleFonts.poppins(
                      color: AppColors.midGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _isEditing = true),
                    child: Text(
                      'Add Payment Method',
                      style: GoogleFonts.poppins(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (hasMobileMoney) ...[
              _buildPaymentMethodRow(
                icon: Icons.phone_android,
                title: 'Mobile Money',
                subtitle: '${driver.mobileMoneyProvider ?? ''} - ${driver.mobileMoneyNumber}',
                color: AppColors.primaryOrange,
              ),
            ],
            if (hasBank) ...[
              if (hasMobileMoney) const SizedBox(height: 12),
              _buildPaymentMethodRow(
                icon: Icons.account_balance,
                title: 'Bank Account',
                subtitle: '${driver.bankName ?? ''} - ${driver.bankAccountNumber}',
                color: Colors.blue,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
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
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.midGray,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20),
      ],
    );
  }

  Widget _buildMethodOption({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == id;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedMethod = id;
        _accountController.clear();
      }),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.lightGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primaryOrange : AppColors.midGray,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primaryOrange : AppColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
