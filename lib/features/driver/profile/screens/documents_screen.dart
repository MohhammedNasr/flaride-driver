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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Keep your documents up to date to maintain your active status.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Documents List
                _buildDocumentCard(
                  context,
                  title: "Driver's License (Front)",
                  subtitle: 'Front side of license',
                  icon: Icons.badge,
                  status: driver?.driverLicenseFrontUrl != null ? 'uploaded' : 'pending',
                  expiryDate: driver?.driverLicenseExpiry,
                  documentType: DocumentType.driverLicenseFront,
                  currentUrl: driver?.driverLicenseFrontUrl,
                ),
                const SizedBox(height: 12),

                _buildDocumentCard(
                  context,
                  title: "Driver's License (Back)",
                  subtitle: 'Back side of license',
                  icon: Icons.badge,
                  status: driver?.driverLicenseBackUrl != null ? 'uploaded' : 'pending',
                  documentType: DocumentType.driverLicenseBack,
                  currentUrl: driver?.driverLicenseBackUrl,
                ),
                const SizedBox(height: 12),

                _buildDocumentCard(
                  context,
                  title: 'National ID (Front)',
                  subtitle: 'Front side of ID',
                  icon: Icons.credit_card,
                  status: driver?.nationalIdFrontUrl != null ? 'uploaded' : 'pending',
                  documentType: DocumentType.nationalIdFront,
                  currentUrl: driver?.nationalIdFrontUrl,
                ),
                const SizedBox(height: 12),

                _buildDocumentCard(
                  context,
                  title: 'National ID (Back)',
                  subtitle: 'Back side of ID',
                  icon: Icons.credit_card,
                  status: driver?.nationalIdBackUrl != null ? 'uploaded' : 'pending',
                  documentType: DocumentType.nationalIdBack,
                  currentUrl: driver?.nationalIdBackUrl,
                ),
                const SizedBox(height: 12),

                _buildDocumentCard(
                  context,
                  title: 'Vehicle Registration',
                  subtitle: 'Current registration document',
                  icon: Icons.description,
                  status: driver?.vehicleRegistrationUrl != null ? 'uploaded' : 'pending',
                  documentType: DocumentType.vehicleRegistration,
                  currentUrl: driver?.vehicleRegistrationUrl,
                ),
                const SizedBox(height: 24),

                // Document Status Legend
                Container(
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
                        'Status Guide',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatusLegend('Uploaded', AppColors.primaryGreen, Icons.check_circle),
                      _buildStatusLegend('Pending', Colors.orange, Icons.hourglass_empty),
                      _buildStatusLegend('Expired', Colors.red, Icons.error),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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

  Widget _buildDocumentCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String status,
    DateTime? expiryDate,
    DocumentType? documentType,
    String? currentUrl,
  }) {
    final isUploading = _uploadingDocument == title;
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Expired';
    } else {
      switch (status) {
        case 'uploaded':
          statusColor = AppColors.primaryGreen;
          statusIcon = Icons.check_circle;
          statusText = 'Uploaded';
          break;
        case 'pending':
          statusColor = Colors.orange;
          statusIcon = Icons.hourglass_empty;
          statusText = 'Pending';
          break;
        default:
          statusColor = AppColors.midGray;
          statusIcon = Icons.help_outline;
          statusText = 'Unknown';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerGray),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryOrange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.midGray,
                  ),
                ),
                if (expiryDate != null)
                  Text(
                    'Expires: ${_formatDate(expiryDate)}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: expiryDate.isBefore(DateTime.now()) ? Colors.red : AppColors.midGray,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isUploading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryOrange,
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'uploaded' && currentUrl != null)
                      GestureDetector(
                        onTap: () => _viewDocument(currentUrl, title),
                        child: Text(
                          'View',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    if (status == 'uploaded' && currentUrl != null)
                      const SizedBox(width: 12),
                    GestureDetector(
                      onTap: documentType != null
                          ? () => _uploadDocument(documentType, title)
                          : null,
                      child: Text(
                        status == 'uploaded' ? 'Update' : 'Upload',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLegend(String label, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
