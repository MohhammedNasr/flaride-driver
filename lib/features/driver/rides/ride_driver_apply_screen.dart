import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/core/config/environment.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Screen for delivery drivers to apply as ride drivers from within the app.
/// Also used as the initial onboarding for new ride driver applicants.
class RideDriverApplyScreen extends StatefulWidget {
  const RideDriverApplyScreen({super.key});

  @override
  State<RideDriverApplyScreen> createState() => _RideDriverApplyScreenState();
}

class _RideDriverApplyScreenState extends State<RideDriverApplyScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  String? _error;
  bool _submitted = false;

  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _plateController = TextEditingController();
  final _seatsController = TextEditingController(text: '4');
  final _licenseController = TextEditingController();

  String _bodyType = 'sedan';
  String _transmission = 'manual';
  bool _hasAc = true;
  String _preferredCategory = 'economy';

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    _seatsController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate
    if (_makeController.text.isEmpty || _modelController.text.isEmpty || _plateController.text.isEmpty) {
      setState(() => _error = 'Please fill in all required fields');
      return;
    }

    setState(() { _isSubmitting = true; _error = null; });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final baseUrl = EnvironmentConfig.restaurantApiBaseUrl;

      final response = await http.post(
        Uri.parse('$baseUrl/api/driver/rides/apply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'vehicle_make': _makeController.text.trim(),
          'vehicle_model': _modelController.text.trim(),
          'vehicle_year': int.tryParse(_yearController.text) ?? 0,
          'vehicle_color': _colorController.text.trim(),
          'vehicle_license_plate': _plateController.text.trim().toUpperCase(),
          'vehicle_body_type': _bodyType,
          'vehicle_seats': int.tryParse(_seatsController.text) ?? 4,
          'vehicle_has_ac': _hasAc,
          'vehicle_transmission': _transmission,
          'preferred_category': _preferredCategory,
          'driver_license_number': _licenseController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _submitted = true);
        // Refresh driver profile to get updated application status
        if (mounted) {
          context.read<DriverProvider>().checkDriverStatus();
        }
      } else {
        setState(() => _error = data['error'] ?? 'Submission error');
      }
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Become a Ride Driver', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          // Step indicator
          _buildStepIndicator(),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _currentStep == 0 ? _buildVehicleStep() : _buildLicenseStep(),
            ),
          ),
          // Error
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: GoogleFonts.poppins(fontSize: 13, color: Colors.red.shade700))),
                  ],
                ),
              ),
            ),
          // Navigation
          _buildNavigation(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(
        children: List.generate(2, (i) {
          final isActive = i <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryGreen : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: i < _currentStep
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text('${i + 1}', style: GoogleFonts.poppins(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
                if (i < 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep > 0 ? AppColors.primaryGreen : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVehicleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vehicle Information', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Describe the vehicle you will use for trips', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        _buildTextField('Make *', _makeController, 'e.g. Toyota'),
        _buildTextField('Model *', _modelController, 'e.g. Corolla'),
        Row(children: [
          Expanded(child: _buildTextField('Year', _yearController, '2020', isNumber: true)),
          const SizedBox(width: 12),
          Expanded(child: _buildTextField('Color', _colorController, 'White')),
        ]),
        _buildTextField('License Plate *', _plateController, 'AB-1234-CI'),
        Row(children: [
          Expanded(child: _buildTextField('Seats', _seatsController, '4', isNumber: true)),
          const SizedBox(width: 12),
          Expanded(child: _buildDropdown('Body Type', _bodyType, {'sedan': 'Sedan', 'suv': 'SUV', 'hatchback': 'Hatchback', 'minivan': 'Minivan'}, (v) => setState(() => _bodyType = v))),
        ]),
        Row(children: [
          Expanded(child: _buildDropdown('Transmission', _transmission, {'manual': 'Manual', 'automatic': 'Automatic'}, (v) => setState(() => _transmission = v))),
          const SizedBox(width: 12),
          Expanded(child: _buildDropdown('Air Conditioning', _hasAc ? 'true' : 'false', {'true': 'Yes', 'false': 'No'}, (v) => setState(() => _hasAc = v == 'true'))),
        ]),
        const SizedBox(height: 16),
        Text('Preferred Category', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        _buildCategorySelector(),
      ],
    );
  }

  Widget _buildLicenseStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('License & Documents', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Your driver license information', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        _buildTextField('License Number', _licenseController, 'DL-XXXXXX'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You can upload photos of your documents (license, ID, vehicle registration, insurance) after signing up from the Documents section of your profile.',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        _buildSummaryCard(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow('Vehicle', '${_makeController.text} ${_modelController.text} ${_yearController.text}'),
          _summaryRow('Plate', _plateController.text.toUpperCase()),
          _summaryRow('Color', _colorController.text.isNotEmpty ? _colorController.text : '-'),
          _summaryRow('Category', _preferredCategory == 'economy' ? 'Economy' : _preferredCategory == 'comfort' ? 'Comfort' : 'Comfort+'),
          _summaryRow('License', _licenseController.text.isNotEmpty ? _licenseController.text : '-'),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final cats = [
      {'id': 'economy', 'name': 'Economy', 'desc': 'Affordable rides', 'icon': Icons.directions_car},
      {'id': 'comfort', 'name': 'Comfort', 'desc': 'Spacious vehicles + AC', 'icon': Icons.airline_seat_recline_extra},
      {'id': 'comfort_plus', 'name': 'Comfort+', 'desc': 'Premium vehicles', 'icon': Icons.star},
    ];
    return Column(
      children: cats.map((cat) {
        final selected = _preferredCategory == cat['id'];
        return GestureDetector(
          onTap: () => setState(() => _preferredCategory = cat['id'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryGreen.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? AppColors.primaryGreen : Colors.grey.shade200, width: selected ? 2 : 1),
            ),
            child: Row(
              children: [
                Icon(cat['icon'] as IconData, color: selected ? AppColors.primaryGreen : Colors.grey, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat['name'] as String, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? AppColors.primaryGreen : AppColors.textPrimary)),
                      Text(cat['desc'] as String, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 24),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, Map<String, String> options, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => onChanged(v!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() { _currentStep--; _error = null; }),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Back', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () {
                  if (_currentStep < 1) {
                    if (_makeController.text.isEmpty || _modelController.text.isEmpty || _plateController.text.isEmpty) {
                      setState(() => _error = 'Make, model, and license plate are required');
                      return;
                    }
                    setState(() { _currentStep++; _error = null; });
                  } else {
                    _submit();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        _currentStep < 1 ? 'Next' : 'Submit Application',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 56),
              ),
              const SizedBox(height: 24),
              Text('Application Submitted!', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Our team will review your application within 24 to 48 hours. You will receive a notification with next steps.',
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildNextSteps(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Back to Home', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextSteps() {
    final steps = [
      {'n': '1', 't': 'Review (24-48h)'},
      {'n': '2', 't': 'Vehicle Inspection'},
      {'n': '3', 't': 'Account Activation'},
      {'n': '4', 't': 'Start Driving'},
    ];
    return Column(
      children: steps.map((s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
              child: Center(child: Text(s['n']!, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
            const SizedBox(width: 12),
            Text(s['t']!, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary)),
          ],
        ),
      )).toList(),
    );
  }
}
