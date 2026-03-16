import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/shared/widgets/app_toast.dart';

class PayoutRequestScreen extends StatefulWidget {
  final EarningsSummary summary;
  final PayoutInfo payoutInfo;

  const PayoutRequestScreen({
    super.key,
    required this.summary,
    required this.payoutInfo,
  });

  @override
  State<PayoutRequestScreen> createState() => _PayoutRequestScreenState();
}

class _PayoutRequestScreenState extends State<PayoutRequestScreen> {
  final DriverService _driverService = DriverService();
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();

  String _selectedMethod = 'mobile_money';
  String? _selectedProvider;
  bool _isSubmitting = false;
  String? _error;

  final List<Map<String, dynamic>> _mobileMoneyProviders = [
    {'id': 'orange_money', 'name': 'Orange Money', 'color': Color(0xFFFF7900)},
    {'id': 'mtn_money', 'name': 'MTN Mobile Money', 'color': Color(0xFFFFCC00)},
    {'id': 'moov_money', 'name': 'Moov Money', 'color': Color(0xFF0099CC)},
    {'id': 'wave', 'name': 'Wave', 'color': Color(0xFF00D9A3)},
  ];

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.payoutInfo.preferredMethod ?? 'mobile_money';
    _selectedProvider = widget.payoutInfo.mobileMoneyProvider;
    
    if (_selectedMethod == 'mobile_money' && widget.payoutInfo.mobileMoneyNumber != null) {
      _accountController.text = widget.payoutInfo.mobileMoneyNumber!;
    } else if (_selectedMethod == 'bank_transfer' && widget.payoutInfo.bankAccount != null) {
      _accountController.text = widget.payoutInfo.bankAccount!;
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _submitPayoutRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMethod == 'mobile_money' && _selectedProvider == null) {
      setState(() => _error = 'Please select a mobile money provider');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final response = await _driverService.requestPayout(
      paymentMethod: _selectedMethod,
      paymentAccount: _accountController.text.trim(),
      paymentProvider: _selectedMethod == 'mobile_money' 
          ? _selectedProvider 
          : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (response.success) {
        AppToast.success(context, response.message ?? 'Payout request submitted!');
        Navigator.pop(context, true);
      } else {
        setState(() => _error = response.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Request Payout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Card
              _buildAmountCard(),
              const SizedBox(height: 24),

              // Payment Method Selection
              Text(
                'Payment Method',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodSelector(),
              const SizedBox(height: 24),

              // Provider/Bank Selection
              if (_selectedMethod == 'mobile_money') ...[
                Text(
                  'Select Provider',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProviderSelector(),
                const SizedBox(height: 24),
              ],

              // Account Number
              Text(
                _selectedMethod == 'mobile_money' 
                    ? 'Phone Number' 
                    : 'Bank Account Number',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountController,
                keyboardType: _selectedMethod == 'mobile_money'
                    ? TextInputType.phone
                    : TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: _selectedMethod == 'mobile_money'
                      ? 'Enter phone number'
                      : 'Enter account number',
                  prefixIcon: Icon(
                    _selectedMethod == 'mobile_money'
                        ? Icons.phone_android
                        : Icons.account_balance,
                    color: AppColors.midGray,
                  ),
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
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter account number';
                  }
                  if (_selectedMethod == 'mobile_money' && value.length < 8) {
                    return 'Invalid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPayoutRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'Submit Payout Request',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Info text
              Text(
                'Your payout request will be reviewed and processed within 24-48 hours.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.midGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, Color(0xFF2ECC71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Payout Amount',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.summary.availableEarningsDisplay ?? '0 CFA',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Available balance will be transferred',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Row(
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
    );
  }

  Widget _buildMethodOption({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = id;
          _accountController.clear();
          if (id == 'mobile_money' && widget.payoutInfo.mobileMoneyNumber != null) {
            _accountController.text = widget.payoutInfo.mobileMoneyNumber!;
          } else if (id == 'bank_transfer' && widget.payoutInfo.bankAccount != null) {
            _accountController.text = widget.payoutInfo.bankAccount!;
          }
        });
      },
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
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primaryOrange : AppColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSelector() {
    return Wrap(
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: provider['color'] as Color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.phone_android,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  provider['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? provider['color'] as Color 
                        : AppColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
