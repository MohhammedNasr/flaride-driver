import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/upload_service.dart';
import 'package:flaride_driver/core/utils/haptic_utils.dart';
import 'package:image_picker/image_picker.dart';

class DeliveryPhotoScreen extends StatefulWidget {
  final String orderId;
  final DeliveryPhotoType photoType;
  final VoidCallback? onPhotoUploaded;

  const DeliveryPhotoScreen({
    super.key,
    required this.orderId,
    required this.photoType,
    this.onPhotoUploaded,
  });

  @override
  State<DeliveryPhotoScreen> createState() => _DeliveryPhotoScreenState();
}

class _DeliveryPhotoScreenState extends State<DeliveryPhotoScreen> {
  final UploadService _uploadService = UploadService();
  
  File? _selectedImage;
  bool _isUploading = false;
  String? _error;

  String get _title {
    return widget.photoType == DeliveryPhotoType.pickupConfirmation
        ? 'Pickup Confirmation'
        : 'Delivery Proof';
  }

  String get _instruction {
    return widget.photoType == DeliveryPhotoType.pickupConfirmation
        ? 'Take a photo of the order before pickup'
        : 'Take a photo as proof of delivery';
  }

  Future<void> _takePhoto() async {
    final file = await _uploadService.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
      quality: 85,
    );

    if (file != null) {
      HapticUtils.lightImpact();
      setState(() {
        _selectedImage = file;
        _error = null;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await _uploadService.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      quality: 85,
    );

    if (file != null) {
      HapticUtils.lightImpact();
      setState(() {
        _selectedImage = file;
        _error = null;
      });
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) {
      setState(() => _error = 'Please take or select a photo first');
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    final result = await _uploadService.uploadDeliveryPhoto(
      orderId: widget.orderId,
      photoType: widget.photoType,
      file: _selectedImage!,
    );

    if (!mounted) return;

    setState(() => _isUploading = false);

    if (result.success) {
      HapticUtils.success();
      widget.onPhotoUploaded?.call();
      Navigator.of(context).pop(true);
    } else {
      HapticUtils.error();
      setState(() => _error = result.error ?? 'Upload failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instruction
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primaryOrange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _instruction,
                        style: const TextStyle(
                          color: AppColors.darkGray,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Photo preview
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedImage != null 
                          ? AppColors.primaryGreen 
                          : AppColors.midGray.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  onPressed: () {
                                    setState(() => _selectedImage = null);
                                  },
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 64,
                              color: AppColors.midGray.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No photo selected',
                              style: TextStyle(
                                color: AppColors.midGray.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Error message
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickFromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primaryOrange),
                        foregroundColor: AppColors.primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Upload button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedImage != null && !_isUploading
                      ? _uploadPhoto
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.lightGray,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Upload Photo',
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
}
