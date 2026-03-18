import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/config/api_config.dart';
import 'package:flaride_driver/shared/widgets/custom_text_field.dart';
import 'package:flaride_driver/shared/widgets/primary_button.dart';

class DriverApplicationFormScreen extends StatefulWidget {
  const DriverApplicationFormScreen({super.key});

  @override
  State<DriverApplicationFormScreen> createState() => _DriverApplicationFormScreenState();
}

class _DriverApplicationFormScreenState extends State<DriverApplicationFormScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isValidating = false;
  String? _submitError;
  bool _submitSuccess = false;

  // Form controllers - Personal Info
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _selectedCity;

  // Form controllers - Vehicle Info
  String? _vehicleType;
  final _vehicleBrandController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _driverLicenseController = TextEditingController();
  DateTime? _licenseExpiry;
  bool _hasSmartphone = true;
  bool _hasInsulatedBag = false;

  // Form controllers - Payment Info
  String? _mobileMoneyProvider;
  final _mobileMoneyNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();

  // Document files
  final ImagePicker _imagePicker = ImagePicker();
  File? _driverLicenseFrontFile;
  File? _driverLicenseBackFile;
  File? _nationalIdFrontFile;
  File? _nationalIdBackFile;
  File? _vehicleRegistrationFile;
  File? _insuranceCertificateFile;
  File? _vehiclePhotoFrontFile;
  File? _vehiclePhotoRearFile;
  File? _vehiclePhotoInteriorFile;
  File? _inspectionCertificateFile;

  // Agreements
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  String? _howDidYouHear;

  // Validation errors
  Map<String, String?> _errors = {};

  final List<String> _cities = [
    'Abidjan',
    'Bouaké',
    'Daloa',
    'Yamoussoukro',
    'San-Pédro',
    'Korhogo',
    'Man',
    'Divo',
    'Gagnoa',
    'Abengourou',
  ];

  final List<Map<String, String>> _vehicleTypes = [
    {'value': 'car', 'label': 'Car'},
    {'value': 'motorbike', 'label': 'Motorbike'},
    {'value': 'bicycle', 'label': 'Bicycle'},
    {'value': 'scooter', 'label': 'Scooter'},
  ];

  final List<String> _mobileMoneyProviders = [
    'Orange Money',
    'MTN Money',
    'Moov Money',
    'Wave',
  ];

  final List<Map<String, String>> _howDidYouHearOptions = [
    {'value': 'google', 'label': 'Google'},
    {'value': 'facebook', 'label': 'Facebook'},
    {'value': 'instagram', 'label': 'Instagram'},
    {'value': 'friend_referral', 'label': 'Friend Referral'},
    {'value': 'flyer', 'label': 'Flyer'},
    {'value': 'website', 'label': 'Website'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _addressController.dispose();
    _vehicleBrandController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehicleColorController.dispose();
    _licensePlateController.dispose();
    _driverLicenseController.dispose();
    _mobileMoneyNumberController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  bool _validateStep(int step) {
    final errors = <String, String?>{};

    if (step == 0) {
      // Personal Info validation
      if (_fullNameController.text.trim().isEmpty) {
        errors['fullName'] = 'Full name is required';
      }
      if (_emailController.text.trim().isEmpty) {
        errors['email'] = 'Email is required';
      } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_emailController.text)) {
        errors['email'] = 'Invalid email format';
      }
      if (_phoneController.text.trim().isEmpty) {
        errors['phone'] = 'Phone number is required';
      }
      if (_dateOfBirth == null) {
        errors['dateOfBirth'] = 'Date of birth is required';
      }
      if (_nationalIdController.text.trim().isEmpty) {
        errors['nationalId'] = 'National ID is required';
      }
      if (_selectedCity == null) {
        errors['city'] = 'City is required';
      }
    } else if (step == 1) {
      // Vehicle Info validation
      if (_vehicleType == null) {
        errors['vehicleType'] = 'Vehicle type is required';
      }
      if (_vehicleType != 'bicycle') {
        if (_licensePlateController.text.trim().isEmpty) {
          errors['licensePlate'] = 'License plate is required';
        }
        if (_driverLicenseController.text.trim().isEmpty) {
          errors['driverLicense'] = 'Driver license number is required';
        }
        if (_licenseExpiry == null) {
          errors['licenseExpiry'] = 'License expiry date is required';
        }
      }
    } else if (step == 2) {
      // Documents validation
      if (_driverLicenseFrontFile == null) {
        errors['driverLicenseFront'] = 'Driver license (front) is required';
      }
      if (_nationalIdFrontFile == null) {
        errors['nationalIdFront'] = 'National ID (front) is required';
      }
      if (_vehicleRegistrationFile == null) {
        errors['vehicleRegistration'] = 'Vehicle registration is required';
      }
      if (_insuranceCertificateFile == null) {
        errors['insuranceCertificate'] = 'Insurance certificate is required';
      }
      if (_vehiclePhotoFrontFile == null) {
        errors['vehiclePhotoFront'] = 'Vehicle photo (front) is required';
      }
      if (_inspectionCertificateFile == null) {
        errors['inspectionCertificate'] = 'Inspection certificate is required';
      }
    } else if (step == 3) {
      // Payment Info validation
      if (_mobileMoneyProvider == null && _bankNameController.text.trim().isEmpty) {
        errors['payment'] = 'Please provide at least one payment method';
      }
      if (_mobileMoneyProvider != null && _mobileMoneyNumberController.text.trim().isEmpty) {
        errors['mobileMoneyNumber'] = 'Mobile money number is required';
      }
      if (_bankNameController.text.trim().isNotEmpty && _bankAccountController.text.trim().isEmpty) {
        errors['bankAccount'] = 'Bank account number is required';
      }
    } else if (step == 4) {
      // Review & Submit validation
      if (!_agreedToTerms) {
        errors['terms'] = 'You must agree to the terms of service';
      }
      if (!_agreedToPrivacy) {
        errors['privacy'] = 'You must agree to the privacy policy';
      }
    }

    setState(() => _errors = errors);
    return errors.isEmpty;
  }

  Future<bool> _validateWithApi() async {
    setState(() => _isValidating = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/delivery-applications/validate'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'national_id': _nationalIdController.text.trim(),
          if (_licensePlateController.text.trim().isNotEmpty)
            'vehicle_license_plate': _licensePlateController.text.trim(),
          if (_driverLicenseController.text.trim().isNotEmpty)
            'driver_license_number': _driverLicenseController.text.trim(),
        }),
      );

      final result = jsonDecode(response.body);
      
      if (result['valid'] != true && result['errors'] != null) {
        final apiErrors = result['errors'] as Map<String, dynamic>;
        setState(() {
          _errors = {..._errors, ...apiErrors.map((k, v) => MapEntry(k, v?.toString()))};
        });
        return false;
      }
      
      return true;
    } catch (e) {
      // Continue anyway if validation service fails
      return true;
    } finally {
      setState(() => _isValidating = false);
    }
  }

  Future<void> _nextStep() async {
    if (!_validateStep(_currentStep)) return;

    // API validation for step 0 and 1
    if (_currentStep == 0 || _currentStep == 1) {
      final isValid = await _validateWithApi();
      if (!isValid) return;
    }

    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<String?> _uploadFile(File file, String folder, String filename) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiBaseUrl}/public/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['folder'] = folder;
      request.fields['filename'] = filename;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Upload error for $filename: $e');
      return null;
    }
  }

  Future<void> _submitApplication() async {
    if (!_validateStep(4)) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      // Upload all document files
      final folder = 'applications/${_emailController.text.trim().replaceAll('@', '_')}';
      final uploads = <String, File?>{
        'driver_license_front': _driverLicenseFrontFile,
        'driver_license_back': _driverLicenseBackFile,
        'national_id_front': _nationalIdFrontFile,
        'national_id_back': _nationalIdBackFile,
        'vehicle_registration': _vehicleRegistrationFile,
        'insurance_certificate': _insuranceCertificateFile,
        'vehicle_photo_front': _vehiclePhotoFrontFile,
        'vehicle_photo_rear': _vehiclePhotoRearFile,
        'vehicle_photo_interior': _vehiclePhotoInteriorFile,
        'inspection_certificate': _inspectionCertificateFile,
      };

      final documentUrls = <String, String?>{};
      for (final entry in uploads.entries) {
        if (entry.value != null) {
          final url = await _uploadFile(entry.value!, folder, entry.key);
          if (url != null) {
            documentUrls['${entry.key}_url'] = url;
          } else {
            setState(() {
              _submitError = 'Failed to upload ${entry.key.replaceAll('_', ' ')}. Please try again.';
            });
            return;
          }
        }
      }

      final applicationData = {
        'full_name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'date_of_birth': _dateOfBirth?.toIso8601String().split('T')[0],
        'national_id': _nationalIdController.text.trim(),
        'city': _selectedCity,
        'address': _addressController.text.trim(),
        'vehicle_type': _vehicleType,
        'vehicle_brand': _vehicleBrandController.text.trim(),
        'vehicle_model': _vehicleModelController.text.trim(),
        'vehicle_year': _vehicleYearController.text.trim(),
        'vehicle_color': _vehicleColorController.text.trim(),
        'vehicle_license_plate': _licensePlateController.text.trim(),
        'driver_license_number': _driverLicenseController.text.trim(),
        'driver_license_expiry': _licenseExpiry?.toIso8601String().split('T')[0],
        'has_smartphone': _hasSmartphone,
        'has_insulated_bag': _hasInsulatedBag,
        'mobile_money_provider': _mobileMoneyProvider,
        'mobile_money_number': _mobileMoneyNumberController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'bank_account_number': _bankAccountController.text.trim(),
        'agreed_to_terms': _agreedToTerms,
        'agreed_to_privacy_policy': _agreedToPrivacy,
        'how_did_you_hear': _howDidYouHear,
        ...documentUrls,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/delivery-applications'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode(applicationData),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() => _submitSuccess = true);
      } else {
        setState(() {
          _submitError = result['error'] ?? 'Failed to submit application. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _submitError = 'Network error. Please check your connection and try again.';
      });
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitSuccess) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.darkGray),
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Driver Application',
          style: TextStyle(
            color: AppColors.darkGray,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              // Step indicator
              _buildStepIndicator(),
              // Form content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentStep = index);
                  },
                  children: [
                    _buildPersonalInfoStep(),
                    _buildVehicleInfoStep(),
                    _buildDocumentsStep(),
                    _buildPaymentInfoStep(),
                    _buildReviewStep(),
                  ],
                ),
              ),
              // Bottom buttons
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Personal', 'Vehicle', 'Docs', 'Payment', 'Review'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isActive ? AppColors.primaryOrange : AppColors.lightGray,
                    ),
                  ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryOrange : AppColors.lightGray,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: index < _currentStep
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent ? Colors.white : AppColors.midGray,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < _currentStep ? AppColors.primaryOrange : AppColors.lightGray,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Personal Information', CupertinoIcons.person),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _fullNameController,
            label: 'Full Name',
            icon: CupertinoIcons.person,
            error: _errors['fullName'],
            required: true,
          ),
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: CupertinoIcons.mail,
            keyboardType: TextInputType.emailAddress,
            error: _errors['email'],
            required: true,
          ),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: CupertinoIcons.phone,
            keyboardType: TextInputType.phone,
            hint: '+225 XX XX XX XX',
            error: _errors['phone'],
            required: true,
          ),
          _buildDatePicker(
            label: 'Date of Birth',
            value: _dateOfBirth,
            error: _errors['dateOfBirth'],
            required: true,
            onChanged: (date) => setState(() => _dateOfBirth = date),
          ),
          _buildTextField(
            controller: _nationalIdController,
            label: 'National ID Number',
            icon: CupertinoIcons.creditcard,
            error: _errors['nationalId'],
            required: true,
          ),
          _buildDropdown(
            label: 'City',
            value: _selectedCity,
            items: _cities.map((c) => {'value': c, 'label': c}).toList(),
            error: _errors['city'],
            required: true,
            onChanged: (value) => setState(() => _selectedCity = value),
          ),
          _buildTextField(
            controller: _addressController,
            label: 'Address (Optional)',
            icon: CupertinoIcons.location,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoStep() {
    final showVehicleDetails = _vehicleType != null && _vehicleType != 'bicycle';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Vehicle Information', CupertinoIcons.car),
          const SizedBox(height: 20),
          _buildDropdown(
            label: 'Vehicle Type',
            value: _vehicleType,
            items: _vehicleTypes,
            error: _errors['vehicleType'],
            required: true,
            onChanged: (value) => setState(() => _vehicleType = value),
          ),
          if (showVehicleDetails) ...[
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _vehicleBrandController,
                    label: 'Brand',
                    hint: 'e.g., Honda',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _vehicleModelController,
                    label: 'Model',
                    hint: 'e.g., CRF 250',
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _vehicleYearController,
                    label: 'Year',
                    keyboardType: TextInputType.number,
                    hint: '2020',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _vehicleColorController,
                    label: 'Color',
                    hint: 'e.g., Red',
                  ),
                ),
              ],
            ),
            _buildTextField(
              controller: _licensePlateController,
              label: 'License Plate',
              hint: 'AB-1234-CD',
              error: _errors['licensePlate'],
              required: true,
            ),
            _buildTextField(
              controller: _driverLicenseController,
              label: 'Driver License Number',
              error: _errors['driverLicense'],
              required: true,
            ),
            _buildDatePicker(
              label: 'License Expiry Date',
              value: _licenseExpiry,
              error: _errors['licenseExpiry'],
              required: true,
              onChanged: (date) => setState(() => _licenseExpiry = date),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Equipment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          _buildCheckbox(
            label: 'I have a smartphone with data',
            value: _hasSmartphone,
            onChanged: (v) => setState(() => _hasSmartphone = v ?? true),
          ),
          _buildCheckbox(
            label: 'I have an insulated delivery bag',
            value: _hasInsulatedBag,
            onChanged: (v) => setState(() => _hasInsulatedBag = v ?? false),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSetFile(String key, Function(File) setter) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        setter(File(pickedFile.path));
        _errors.remove(key);
      });
    }
  }

  Widget _buildDocumentUploadCard({
    required String label,
    required String errorKey,
    required File? file,
    required Function(File) onPicked,
    bool required = false,
  }) {
    final hasError = _errors[errorKey] != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _pickAndSetFile(errorKey, onPicked),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? Colors.red : (file != null ? AppColors.primaryGreen : AppColors.lightGray),
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: file != null
                      ? AppColors.primaryGreen.withOpacity(0.1)
                      : AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: file != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(file, fit: BoxFit.cover),
                      )
                    : Icon(
                        CupertinoIcons.cloud_upload,
                        color: AppColors.primaryOrange,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkGray,
                            ),
                          ),
                        ),
                        if (required)
                          const Text(' *', style: TextStyle(color: Colors.red, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file != null ? file.path.split('/').last : 'Tap to upload',
                      style: TextStyle(
                        fontSize: 12,
                        color: file != null ? AppColors.primaryGreen : AppColors.midGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasError) ...[
                      const SizedBox(height: 4),
                      Text(
                        _errors[errorKey]!,
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                file != null ? Icons.check_circle : CupertinoIcons.chevron_right,
                color: file != null ? AppColors.primaryGreen : AppColors.midGray,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Documents', CupertinoIcons.doc_text),
          const SizedBox(height: 8),
          Text(
            'Upload photos of your documents. Required documents are marked with *.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.midGray.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          _buildDocumentUploadCard(
            label: "Driver's License (Front)",
            errorKey: 'driverLicenseFront',
            file: _driverLicenseFrontFile,
            onPicked: (f) => _driverLicenseFrontFile = f,
            required: true,
          ),
          _buildDocumentUploadCard(
            label: "Driver's License (Back)",
            errorKey: 'driverLicenseBack',
            file: _driverLicenseBackFile,
            onPicked: (f) => _driverLicenseBackFile = f,
          ),
          _buildDocumentUploadCard(
            label: 'National ID (Front)',
            errorKey: 'nationalIdFront',
            file: _nationalIdFrontFile,
            onPicked: (f) => _nationalIdFrontFile = f,
            required: true,
          ),
          _buildDocumentUploadCard(
            label: 'National ID (Back)',
            errorKey: 'nationalIdBack',
            file: _nationalIdBackFile,
            onPicked: (f) => _nationalIdBackFile = f,
          ),
          _buildDocumentUploadCard(
            label: 'Vehicle Registration',
            errorKey: 'vehicleRegistration',
            file: _vehicleRegistrationFile,
            onPicked: (f) => _vehicleRegistrationFile = f,
            required: true,
          ),
          _buildDocumentUploadCard(
            label: 'Insurance Certificate',
            errorKey: 'insuranceCertificate',
            file: _insuranceCertificateFile,
            onPicked: (f) => _insuranceCertificateFile = f,
            required: true,
          ),
          _buildDocumentUploadCard(
            label: 'Vehicle Photo (Front)',
            errorKey: 'vehiclePhotoFront',
            file: _vehiclePhotoFrontFile,
            onPicked: (f) => _vehiclePhotoFrontFile = f,
            required: true,
          ),
          _buildDocumentUploadCard(
            label: 'Vehicle Photo (Rear)',
            errorKey: 'vehiclePhotoRear',
            file: _vehiclePhotoRearFile,
            onPicked: (f) => _vehiclePhotoRearFile = f,
          ),
          _buildDocumentUploadCard(
            label: 'Vehicle Photo (Interior)',
            errorKey: 'vehiclePhotoInterior',
            file: _vehiclePhotoInteriorFile,
            onPicked: (f) => _vehiclePhotoInteriorFile = f,
          ),
          _buildDocumentUploadCard(
            label: 'Inspection Certificate',
            errorKey: 'inspectionCertificate',
            file: _inspectionCertificateFile,
            onPicked: (f) => _inspectionCertificateFile = f,
            required: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Payment Information', CupertinoIcons.creditcard),
          const SizedBox(height: 8),
          Text(
            'How would you like to receive your earnings?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.midGray.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          if (_errors['payment'] != null)
            _buildErrorBox(_errors['payment']!),
          // Mobile Money
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.device_phone_portrait, color: AppColors.primaryOrange),
                    SizedBox(width: 8),
                    Text(
                      'Mobile Money',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Provider',
                  value: _mobileMoneyProvider,
                  items: _mobileMoneyProviders.map((p) => {'value': p, 'label': p}).toList(),
                  onChanged: (value) => setState(() => _mobileMoneyProvider = value),
                ),
                if (_mobileMoneyProvider != null)
                  _buildTextField(
                    controller: _mobileMoneyNumberController,
                    label: 'Mobile Money Number',
                    keyboardType: TextInputType.phone,
                    hint: '+225 XX XX XX XX',
                    error: _errors['mobileMoneyNumber'],
                    required: true,
                  ),
              ],
            ),
          ),
          // Bank Account
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.building_2_fill, color: AppColors.primaryGreen),
                    SizedBox(width: 8),
                    Text(
                      'Bank Account (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _bankNameController,
                  label: 'Bank Name',
                  hint: 'e.g., SGBCI, BICICI',
                ),
                if (_bankNameController.text.isNotEmpty)
                  _buildTextField(
                    controller: _bankAccountController,
                    label: 'Account Number',
                    keyboardType: TextInputType.number,
                    error: _errors['bankAccount'],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final vehicleLabel = _vehicleTypes.firstWhere(
      (t) => t['value'] == _vehicleType,
      orElse: () => {'label': 'Not set'},
    )['label'] ?? 'Not set';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryOrange.withOpacity(0.1),
                  AppColors.primaryGreen.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.doc_text_fill,
                    color: AppColors.primaryOrange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Almost Done!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Review your information below',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.midGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Personal Info Card
          _buildReviewCard(
            icon: CupertinoIcons.person_fill,
            iconColor: AppColors.primaryOrange,
            title: 'Personal Information',
            items: [
              _buildReviewItem('Full Name', _fullNameController.text),
              _buildReviewItem('Email', _emailController.text),
              _buildReviewItem('Phone', _phoneController.text),
              _buildReviewItem('Date of Birth', _dateOfBirth != null 
                ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}' 
                : 'Not set'),
              _buildReviewItem('City', _selectedCity ?? 'Not set'),
            ],
          ),
          const SizedBox(height: 16),

          // Vehicle Info Card
          _buildReviewCard(
            icon: CupertinoIcons.car_fill,
            iconColor: AppColors.primaryGreen,
            title: 'Vehicle Information',
            items: [
              _buildReviewItem('Vehicle Type', vehicleLabel),
              if (_vehicleBrandController.text.isNotEmpty)
                _buildReviewItem('Brand & Model', '${_vehicleBrandController.text} ${_vehicleModelController.text}'.trim()),
              if (_vehicleType != 'bicycle' && _licensePlateController.text.isNotEmpty)
                _buildReviewItem('License Plate', _licensePlateController.text),
              if (_vehicleType != 'bicycle' && _driverLicenseController.text.isNotEmpty)
                _buildReviewItem('Driver License', _driverLicenseController.text),
            ],
          ),
          const SizedBox(height: 16),

          // Documents Card
          _buildReviewCard(
            icon: CupertinoIcons.doc_text_fill,
            iconColor: const Color(0xFF9C27B0),
            title: 'Documents',
            items: [
              _buildReviewItem("Driver's License (Front)", _driverLicenseFrontFile != null ? 'Uploaded' : 'Not uploaded'),
              _buildReviewItem("Driver's License (Back)", _driverLicenseBackFile != null ? 'Uploaded' : 'Not uploaded'),
              _buildReviewItem('National ID (Front)', _nationalIdFrontFile != null ? 'Uploaded' : 'Not uploaded'),
              _buildReviewItem('National ID (Back)', _nationalIdBackFile != null ? 'Uploaded' : 'Not uploaded'),
              _buildReviewItem('Vehicle Registration', _vehicleRegistrationFile != null ? 'Uploaded' : 'Not uploaded'),
              _buildReviewItem('Insurance Certificate', _insuranceCertificateFile != null ? 'Uploaded' : 'Not uploaded'),
              _buildReviewItem('Vehicle Photo (Front)', _vehiclePhotoFrontFile != null ? 'Uploaded' : 'Not uploaded'),
              _buildReviewItem('Vehicle Photo (Rear)', _vehiclePhotoRearFile != null ? 'Uploaded' : 'Not uploaded'),
              _buildReviewItem('Vehicle Photo (Interior)', _vehiclePhotoInteriorFile != null ? 'Uploaded' : 'Not uploaded'),
              _buildReviewItem('Inspection Certificate', _inspectionCertificateFile != null ? 'Uploaded' : 'Not uploaded'),
            ],
          ),
          const SizedBox(height: 16),

          // Payment Info Card
          _buildReviewCard(
            icon: CupertinoIcons.creditcard_fill,
            iconColor: const Color(0xFF2196F3),
            title: 'Payment Information',
            items: [
              if (_mobileMoneyProvider != null)
                _buildReviewItem('Mobile Money', '$_mobileMoneyProvider\n${_mobileMoneyNumberController.text}'),
              if (_bankNameController.text.isNotEmpty)
                _buildReviewItem('Bank Account', '${_bankNameController.text}\n${_bankAccountController.text}'),
              if (_mobileMoneyProvider == null && _bankNameController.text.isEmpty)
                _buildReviewItem('Payment Method', 'Not configured'),
            ],
          ),
          const SizedBox(height: 24),

          // How did you hear
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How did you hear about us?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _howDidYouHear,
                      isExpanded: true,
                      hint: const Text('Select an option'),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: BorderRadius.circular(10),
                      items: _howDidYouHearOptions.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['value'],
                          child: Text(item['label'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _howDidYouHear = value),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Agreements Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Column(
              children: [
                _buildAgreementTile(
                  'Terms of Service',
                  'I agree to the FlaRide Terms of Service',
                  _agreedToTerms,
                  (v) => setState(() => _agreedToTerms = v ?? false),
                  _errors['terms'],
                ),
                const Divider(height: 24),
                _buildAgreementTile(
                  'Privacy Policy',
                  'I agree to the FlaRide Privacy Policy',
                  _agreedToPrivacy,
                  (v) => setState(() => _agreedToPrivacy = v ?? false),
                  _errors['privacy'],
                ),
              ],
            ),
          ),

          if (_submitError != null) ...[
            const SizedBox(height: 16),
            _buildErrorBox(_submitError!),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.midGray.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementTile(
    String title,
    String subtitle,
    bool value,
    Function(bool?) onChanged,
    String? error,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? AppColors.primaryGreen : AppColors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: error != null 
                    ? Colors.red 
                    : (value ? AppColors.primaryGreen : AppColors.lightGray),
                width: 2,
              ),
            ),
            child: value
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.midGray.withOpacity(0.8),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    error,
                    style: const TextStyle(fontSize: 11, color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.midGray),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(color: AppColors.darkGray),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting || _isValidating
                  ? null
                  : (_currentStep == 4 ? _submitApplication : _nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.primaryOrange.withOpacity(0.5),
              ),
              child: _isSubmitting || _isValidating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == 4 ? 'Submit Application' : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
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
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  size: 60,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Application Submitted!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thank you for applying to become a FlaRide delivery partner. We will review your application and get back to you within 2-3 business days.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.midGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Next steps
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What happens next?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNextStep(1, 'We review your application'),
                    _buildNextStep(2, 'You\'ll receive an email with the result'),
                    _buildNextStep(3, 'If approved, you can start delivering!'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.midGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    String? error,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    // Generate placeholder if hint not provided
    final placeholder = hint ?? 'Enter ${label.toLowerCase()}';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGray,
                ),
              ),
              if (required)
                const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: TextInputAction.done,
            onEditingComplete: () => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: AppColors.midGray.withOpacity(0.6)),
              prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.midGray) : null,
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: error != null ? Colors.red : AppColors.lightGray,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: error != null ? Colors.red : AppColors.lightGray,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
    String? error,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGray,
                ),
              ),
              if (required)
                const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null ? Colors.red : AppColors.lightGray,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: Text('Select $label'),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: BorderRadius.circular(12),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['value'],
                    child: Text(item['label'] ?? ''),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required Function(DateTime) onChanged,
    String? error,
    bool required = false,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGray,
                ),
              ),
              if (required)
                const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final first = firstDate ?? DateTime(1950);
              final last = lastDate ?? DateTime.now();
              DateTime initial = value ?? DateTime.now().subtract(const Duration(days: 365 * 20));
              // Ensure initialDate is within valid range
              if (initial.isBefore(first)) initial = first;
              if (initial.isAfter(last)) initial = last;
              
              final date = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: first,
                lastDate: last,
              );
              if (date != null) onChanged(date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: error != null ? Colors.red : AppColors.lightGray,
                ),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.calendar, size: 20, color: AppColors.midGray),
                  const SizedBox(width: 12),
                  Text(
                    value != null
                        ? '${value.day}/${value.month}/${value.year}'
                        : 'Select date',
                    style: TextStyle(
                      color: value != null ? AppColors.darkGray : AppColors.midGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
    String? error,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.darkGray,
                  ),
                ),
              ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          ...items.where((item) => item.isNotEmpty).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.midGray,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.exclamationmark_circle, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
