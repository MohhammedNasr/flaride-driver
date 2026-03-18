import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/core/services/upload_service.dart';
import 'package:flaride_driver/shared/widgets/app_toast.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final UploadService _uploadService = UploadService();
  String? _uploadingDocument;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Documents',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
      ),
      body: Consumer<DriverProvider>(
        builder: (context, driverProvider, child) {
          final driver = driverProvider.driver;
          final uploadedCount = _countUploaded(driver);
          const totalRequired = 6;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                _buildProgressBar(uploadedCount, totalRequired),
                const SizedBox(height: 20),

                // Driver's License group
                _buildDocumentGroup(
                  title: "Driver's License",
                  icon: Icons.badge,
                  required: true,
                  expiryDate: driver?.driverLicenseExpiry,
                  sides: [
                    _DocSide('Front', DocumentType.driverLicenseFront, driver?.driverLicenseFrontUrl),
                    _DocSide('Back', DocumentType.driverLicenseBack, driver?.driverLicenseBackUrl),
                  ],
                ),
                const SizedBox(height: 12),

                // National ID group
                _buildDocumentGroup(
                  title: 'National ID',
                  icon: Icons.credit_card,
                  required: true,
                  sides: [
                    _DocSide('Front', DocumentType.nationalIdFront, driver?.nationalIdFrontUrl),
                    _DocSide('Back', DocumentType.nationalIdBack, driver?.nationalIdBackUrl),
                  ],
                ),
                const SizedBox(height: 12),

                // Single documents
                _buildSingleDocumentCard(
                  title: 'Vehicle Registration',
                  icon: Icons.description,
                  required: true,
                  documentType: DocumentType.vehicleRegistration,
                  currentUrl: driver?.vehicleRegistrationUrl,
                ),
                const SizedBox(height: 12),

                _buildSingleDocumentCard(
                  title: 'Insurance Certificate',
                  icon: Icons.shield,
                  required: true,
                  documentType: DocumentType.insuranceCertificate,
                  currentUrl: driver?.insuranceCertificateUrl ?? driver?.vehicleInsuranceUrl,
                ),
                const SizedBox(height: 12),

                _buildSingleDocumentCard(
                  title: 'Inspection Certificate',
                  icon: Icons.verified_user,
                  required: true,
                  documentType: DocumentType.inspectionCertificate,
                  currentUrl: driver?.inspectionCertificateUrl,
                ),
                const SizedBox(height: 12),

                // Vehicle Photos group
                _buildDocumentGroup(
                  title: 'Vehicle Photos',
                  icon: Icons.directions_car,
                  required: true,
                  sides: [
                    _DocSide('Front', DocumentType.vehiclePhotoFront, driver?.vehiclePhotoFrontUrl),
                    _DocSide('Rear', DocumentType.vehiclePhotoRear, driver?.vehiclePhotoRearUrl),
                    _DocSide('Interior', DocumentType.vehiclePhotoInterior, driver?.vehiclePhotoInteriorUrl, optional: true),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  int _countUploaded(driver) {
    if (driver == null) return 0;
    int count = 0;
    if (driver.driverLicenseFrontUrl != null) count++;
    if (driver.nationalIdFrontUrl != null) count++;
    if (driver.vehicleRegistrationUrl != null) count++;
    if (driver.insuranceCertificateUrl != null || driver.vehicleInsuranceUrl != null) count++;
    if (driver.vehiclePhotoFrontUrl != null) count++;
    if (driver.inspectionCertificateUrl != null) count++;
    return count;
  }

  Widget _buildProgressBar(int uploaded, int total) {
    final ratio = total > 0 ? uploaded / total : 0.0;
    final isComplete = uploaded >= total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.primaryGreen.withOpacity(0.08) : AppColors.primaryOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isComplete ? AppColors.primaryGreen.withOpacity(0.2) : AppColors.primaryOrange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isComplete ? Icons.check_circle : Icons.info_outline, size: 20, color: isComplete ? AppColors.primaryGreen : AppColors.primaryOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isComplete ? 'All required documents uploaded' : '$uploaded of $total required documents uploaded',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isComplete ? AppColors.primaryGreen : AppColors.primaryOrange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.white,
              color: isComplete ? AppColors.primaryGreen : AppColors.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentGroup({
    required String title,
    required IconData icon,
    required bool required,
    DateTime? expiryDate,
    required List<_DocSide> sides,
  }) {
    final allUploaded = sides.where((s) => !s.optional).every((s) => s.url != null);
    final anyUploaded = sides.any((s) => s.url != null);
    final isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerGray),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primaryOrange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                          if (required) ...[
                            const SizedBox(width: 6),
                            Text('*', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.red)),
                          ],
                        ],
                      ),
                      if (expiryDate != null)
                        Text(
                          'Expires: ${_formatDate(expiryDate)}',
                          style: GoogleFonts.poppins(fontSize: 11, color: isExpired ? Colors.red : AppColors.midGray),
                        ),
                    ],
                  ),
                ),
                _statusChip(allUploaded, isExpired),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Side thumbnails row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: sides.map((side) {
                final isUploading = _uploadingDocument == '$title (${side.label})';
                final hasUrl = side.url != null;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: side == sides.last ? 0 : 8),
                    child: GestureDetector(
                      onTap: isUploading
                          ? null
                          : hasUrl
                              ? () => _showSideActions(side, title)
                              : () => _uploadDocument(side.type, '$title (${side.label})'),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: hasUrl ? AppColors.primaryGreen.withOpacity(0.05) : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: hasUrl ? AppColors.primaryGreen.withOpacity(0.3) : AppColors.dividerGray,
                            width: 1.5,
                          ),
                        ),
                        child: isUploading
                            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOrange)))
                            : hasUrl
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(9),
                                        child: Image.network(side.url!, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                                          errorBuilder: (_, __, ___) => Center(child: Icon(Icons.image, color: AppColors.primaryGreen.withOpacity(0.5), size: 28)),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.55),
                                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
                                          ),
                                          child: Text(side.label, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_a_photo_outlined, size: 22, color: AppColors.midGray),
                                      const SizedBox(height: 4),
                                      Text(side.optional ? '${side.label}\n(Optional)' : side.label, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.midGray)),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleDocumentCard({
    required String title,
    required IconData icon,
    required bool required,
    required DocumentType documentType,
    String? currentUrl,
  }) {
    final isUploading = _uploadingDocument == title;
    final hasUrl = currentUrl != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerGray),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray), overflow: TextOverflow.ellipsis, maxLines: 1)),
                if (required) ...[
                  const SizedBox(width: 4),
                  Text('*', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.red)),
                ],
              ],
            ),
          ),
          if (isUploading)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOrange))
          else ...[
            _statusChip(hasUrl, false),
            const SizedBox(width: 8),
            if (hasUrl)
              GestureDetector(
                onTap: () => _viewDocument(currentUrl, title),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('View', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
                ),
              ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _uploadDocument(documentType, title),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(hasUrl ? 'Update' : 'Upload', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryOrange)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(bool uploaded, bool expired) {
    if (expired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error, size: 14, color: Colors.red),
          const SizedBox(width: 4),
          Text('Expired', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red)),
        ]),
      );
    }
    if (uploaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, size: 14, color: AppColors.primaryGreen),
          const SizedBox(width: 4),
          Text('Done', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.hourglass_empty, size: 14, color: Colors.orange),
        const SizedBox(width: 4),
        Text('Pending', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange)),
      ]),
    );
  }

  void _showSideActions(_DocSide side, String groupTitle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility, color: AppColors.primaryGreen),
                title: Text('View ${side.label}', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _viewDocument(side.url!, '$groupTitle (${side.label})');
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload, color: AppColors.primaryOrange),
                title: Text('Update ${side.label}', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadDocument(side.type, '$groupTitle (${side.label})');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadDocument(DocumentType documentType, String title) async {
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

    final file = await _uploadService.pickImage(source: source);
    if (file == null) return;

    setState(() => _uploadingDocument = title);

    final result = await _uploadService.uploadDriverDocument(
      documentType: documentType,
      file: file,
    );

    setState(() => _uploadingDocument = null);

    if (result.success && mounted) {
      await context.read<DriverProvider>().refreshProfile();
      AppToast.success(context, '$title uploaded successfully');
    } else if (mounted) {
      AppToast.error(context, result.error ?? 'Failed to upload $title');
    }
  }

  void _viewDocument(String url, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: AppColors.lightGray,
                  child: const Center(
                    child: Icon(Icons.error_outline, size: 48, color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _DocSide {
  final String label;
  final DocumentType type;
  final String? url;
  final bool optional;
  _DocSide(this.label, this.type, this.url, {this.optional = false});
}
