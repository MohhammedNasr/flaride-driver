import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/core/services/driver_service.dart';
import 'package:flaride_driver/shared/widgets/app_toast.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final DriverService _driverService = DriverService();
  
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _yearController = TextEditingController();
  
  String _selectedVehicleType = 'motorbike';
  bool _isEditing = false;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'id': 'motorbike', 'name': 'Motorcycle', 'icon': Icons.two_wheeler},
    {'id': 'bicycle', 'name': 'Bicycle', 'icon': Icons.pedal_bike},
    {'id': 'compact_car', 'name': 'Car', 'icon': Icons.directions_car},
  ];

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  void _loadDriverData() {
    final driver = context.read<DriverProvider>().driver;
    if (driver != null) {
      _selectedVehicleType = driver.vehicleType ?? 'motorcycle';
      _brandController.text = driver.vehicleBrand ?? '';
      _modelController.text = driver.vehicleModel ?? '';
      _colorController.text = driver.vehicleColor ?? '';
      _licensePlateController.text = driver.vehicleLicensePlate ?? '';
      _yearController.text = driver.vehicleYear?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _licensePlateController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final success = await _driverService.updateVehicleInfo(
      vehicleType: _selectedVehicleType,
      vehicleBrand: _brandController.text.trim(),
      vehicleModel: _modelController.text.trim(),
      vehicleColor: _colorController.text.trim(),
      vehicleLicensePlate: _licensePlateController.text.trim(),
      vehicleYear: int.tryParse(_yearController.text.trim()),
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      await context.read<DriverProvider>().refreshProfile();
      setState(() => _isEditing = false);
      AppToast.success(context, 'Vehicle info updated successfully');
    } else if (mounted) {
      AppToast.error(context, 'Failed to update vehicle info');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Vehicle Information',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Type Selection
              Text(
                'Vehicle Type',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _vehicleTypes.map((type) {
                  final isSelected = _selectedVehicleType == type['id'];
                  return GestureDetector(
                    onTap: _isEditing
                        ? () => setState(() => _selectedVehicleType = type['id'])
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryOrange.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryOrange : AppColors.lightGray,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            color: isSelected ? AppColors.primaryOrange : AppColors.midGray,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type['name'] as String,
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
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Vehicle Details
              _buildTextField(
                label: 'Brand',
                controller: _brandController,
                icon: Icons.business,
                enabled: _isEditing,
                hint: 'e.g., Honda, Toyota',
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Model',
                controller: _modelController,
                icon: Icons.two_wheeler,
                enabled: _isEditing,
                hint: 'e.g., Wave, Activa',
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Year',
                      controller: _yearController,
                      icon: Icons.calendar_today,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      hint: 'e.g., 2020',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Color',
                      controller: _colorController,
                      icon: Icons.palette,
                      enabled: _isEditing,
                      hint: 'e.g., Red',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'License Plate',
                controller: _licensePlateController,
                icon: Icons.confirmation_number,
                enabled: _isEditing,
                hint: 'e.g., ABC-1234',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'License plate is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Equipment Section
              Container(
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
                      'Equipment',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<DriverProvider>(
                      builder: (context, provider, child) {
                        final driver = provider.driver;
                        return Column(
                          children: [
                            _buildEquipmentRow(
                              'Insulated Bag',
                              driver?.hasInsulatedBag ?? false,
                              Icons.shopping_bag,
                            ),
                            _buildEquipmentRow(
                              'Smartphone',
                              driver?.hasSmartphone ?? true,
                              Icons.smartphone,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              if (_isEditing) ...[
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _loadDriverData();
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
                                'Save Changes',
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
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(
        color: enabled ? AppColors.darkGray : AppColors.midGray,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(color: AppColors.midGray),
        hintStyle: GoogleFonts.poppins(color: AppColors.lightGray, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.midGray),
        filled: true,
        fillColor: enabled ? Colors.white : AppColors.background,
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerGray),
        ),
      ),
    );
  }

  Widget _buildEquipmentRow(String label, bool hasIt, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.midGray, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.darkGray,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: hasIt
                  ? AppColors.primaryGreen.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              hasIt ? 'Yes' : 'No',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: hasIt ? AppColors.primaryGreen : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
