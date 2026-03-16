import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flaride_driver/core/config/api_config.dart';
import 'package:flaride_driver/core/services/auth_service.dart';
import 'package:flaride_driver/core/services/driver_service.dart';

enum DocumentType {
  profilePhoto,
  driverLicenseFront,
  driverLicenseBack,
  nationalIdFront,
  nationalIdBack,
  vehiclePhoto,
  vehicleRegistration,
}

enum DeliveryPhotoType {
  pickupConfirmation,
  deliveryProof,
}

/// Folder types for organizing images in single bucket
enum ImageFolder {
  driverProfile,
  driverDocuments,
  deliveryPhotos,
}

class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  String _documentTypeToString(DocumentType type) {
    switch (type) {
      case DocumentType.profilePhoto:
        return 'profile_photo';
      case DocumentType.driverLicenseFront:
        return 'driver_license_front';
      case DocumentType.driverLicenseBack:
        return 'driver_license_back';
      case DocumentType.nationalIdFront:
        return 'national_id_front';
      case DocumentType.nationalIdBack:
        return 'national_id_back';
      case DocumentType.vehiclePhoto:
        return 'vehicle_photo';
      case DocumentType.vehicleRegistration:
        return 'vehicle_registration';
    }
  }

  String _deliveryPhotoTypeToString(DeliveryPhotoType type) {
    switch (type) {
      case DeliveryPhotoType.pickupConfirmation:
        return 'pickup_confirmation';
      case DeliveryPhotoType.deliveryProof:
        return 'delivery_proof';
    }
  }

  String _folderPrefix(ImageFolder folder) {
    switch (folder) {
      case ImageFolder.driverProfile:
        return 'drivers';
      case ImageFolder.driverDocuments:
        return 'documents';
      case ImageFolder.deliveryPhotos:
        return 'deliveries';
    }
  }

  /// Pick an image from camera or gallery
  Future<File?> pickImage({
    required ImageSource source,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('UploadService: Error picking image: $e');
      return null;
    }
  }

  /// Compress image to target size (max 500KB)
  Future<File?> compressImage(File file, {int maxSizeKB = 500}) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      int quality = 90;
      XFile? result;
      int attempts = 0;
      const maxAttempts = 5;

      // Try compressing with decreasing quality until under max size
      do {
        result = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: quality,
          minWidth: 1200,
          minHeight: 1200,
          format: CompressFormat.jpeg,
        );

        if (result == null) break;

        final resultFile = File(result.path);
        final size = await resultFile.length();
        
        if (size <= maxSizeKB * 1024) {
          debugPrint('UploadService: Compressed to ${(size / 1024).toStringAsFixed(1)}KB at quality $quality');
          return resultFile;
        }

        quality -= 15;
        attempts++;
      } while (attempts < maxAttempts && quality > 20);

      // Return last result even if slightly over
      if (result != null) {
        return File(result.path);
      }
      return null;
    } catch (e) {
      debugPrint('UploadService: Compression error: $e');
      return null;
    }
  }

  /// Universal upload method - uploads any image with compression
  /// Uses single bucket 'flaride-images' with folder organization
  Future<UploadResult> uploadImage({
    required File file,
    required ImageFolder folderType,
    required String filename,
    String? subFolder,
    bool compress = true,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return UploadResult(success: false, error: 'Not authenticated');
      }

      // Compress image if needed
      File fileToUpload = file;
      if (compress) {
        final compressed = await compressImage(file);
        if (compressed != null) {
          fileToUpload = compressed;
        }
      }

      // Build folder path: {folderPrefix}/{subFolder or userId}
      final folderPath = subFolder ?? _folderPrefix(folderType);

      // Create multipart request
      final uri = Uri.parse('${ApiConfig.apiBaseUrl}/upload');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['folder'] = folderPath;
      request.fields['filename'] = filename;

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        fileToUpload.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('UploadService: Response status: ${response.statusCode}');
      debugPrint('UploadService: Response body: ${response.body}');

      if (response.body.isEmpty) {
        return UploadResult(success: false, error: 'Server returned empty response (${response.statusCode})');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UploadResult(
          success: true,
          url: data['data']['public_url'],
          path: data['data']['path'],
          message: 'Uploaded successfully',
          compressionRatio: data['data']['compression_ratio']?.toString(),
        );
      } else {
        try {
          final error = jsonDecode(response.body)['error'] ?? 'Upload failed';
          return UploadResult(success: false, error: error);
        } catch (_) {
          return UploadResult(success: false, error: 'Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('UploadService: Upload error: $e');
      return UploadResult(success: false, error: 'Upload failed: $e');
    }
  }

  /// Upload profile photo and save URL to database
  Future<UploadResult> uploadProfilePhoto(File file) async {
    final result = await uploadImage(
      file: file,
      folderType: ImageFolder.driverProfile,
      filename: 'profile',
    );
    
    // If upload successful, save the URL to the driver profile
    if (result.success && result.url != null) {
      debugPrint('UploadService: Saving profile photo URL to database: ${result.url}');
      final driverService = DriverService();
      final saved = await driverService.updateProfile(profilePhoto: result.url);
      debugPrint('UploadService: Profile photo save result: $saved');
    }
    
    return result;
  }

  /// Upload a driver document (license, ID, etc.) and save URL to database
  Future<UploadResult> uploadDriverDocument({
    required DocumentType documentType,
    required File file,
  }) async {
    final result = await uploadImage(
      file: file,
      folderType: ImageFolder.driverDocuments,
      filename: _documentTypeToString(documentType),
    );
    
    // If upload successful, save the URL to the driver profile
    if (result.success && result.url != null) {
      debugPrint('UploadService: Saving document URL to database: ${result.url}');
      final driverService = DriverService();
      
      switch (documentType) {
        case DocumentType.driverLicenseFront:
          await driverService.updateProfile(driverLicenseFrontUrl: result.url);
          break;
        case DocumentType.driverLicenseBack:
          await driverService.updateProfile(driverLicenseBackUrl: result.url);
          break;
        case DocumentType.nationalIdFront:
          await driverService.updateProfile(nationalIdFrontUrl: result.url);
          break;
        case DocumentType.nationalIdBack:
          await driverService.updateProfile(nationalIdBackUrl: result.url);
          break;
        case DocumentType.vehicleRegistration:
          await driverService.updateProfile(vehicleRegistrationUrl: result.url);
          break;
        default:
          break;
      }
    }
    
    return result;
  }

  /// Upload delivery photo (pickup/delivery proof)
  Future<UploadResult> uploadDeliveryPhoto({
    required String orderId,
    required DeliveryPhotoType photoType,
    required File file,
  }) async {
    return uploadImage(
      file: file,
      folderType: ImageFolder.deliveryPhotos,
      filename: _deliveryPhotoTypeToString(photoType),
      subFolder: 'deliveries/$orderId',
    );
  }

  /// Pick and upload in one step
  Future<UploadResult> pickAndUpload({
    required ImageSource source,
    required ImageFolder folderType,
    required String filename,
    String? subFolder,
  }) async {
    final file = await pickImage(source: source);
    if (file == null) {
      return UploadResult(success: false, error: 'No image selected');
    }
    return uploadImage(
      file: file,
      folderType: folderType,
      filename: filename,
      subFolder: subFolder,
    );
  }

  /// Legacy method for backward compatibility
  Future<UploadResult> _legacyUploadDriverDocument({
    required DocumentType documentType,
    required File file,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return UploadResult(success: false, error: 'Not authenticated');
      }

      // Step 1: Get signed upload URL
      final contentType = file.path.toLowerCase().endsWith('.png') 
          ? 'image/png' 
          : 'image/jpeg';

      final urlResponse = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/api/driver/upload-url'),
        headers: ApiConfig.getAuthHeaders(token),
        body: jsonEncode({
          'document_type': _documentTypeToString(documentType),
          'content_type': contentType,
        }),
      );

      if (urlResponse.statusCode != 200) {
        final error = jsonDecode(urlResponse.body)['error'] ?? 'Failed to get upload URL';
        return UploadResult(success: false, error: error);
      }

      final urlData = jsonDecode(urlResponse.body);
      final uploadUrl = urlData['upload_url'] as String;
      final publicUrl = urlData['public_url'] as String;

      // Step 2: Upload file to signed URL
      final bytes = await file.readAsBytes();
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: bytes,
      );

      if (uploadResponse.statusCode != 200 && uploadResponse.statusCode != 201) {
        return UploadResult(success: false, error: 'Failed to upload file');
      }

      // Step 3: Confirm upload and save URL to profile
      final confirmResponse = await http.put(
        Uri.parse('${ApiConfig.apiBaseUrl}/api/driver/upload-url'),
        headers: ApiConfig.getAuthHeaders(token),
        body: jsonEncode({
          'document_type': _documentTypeToString(documentType),
          'file_url': publicUrl,
        }),
      );

      if (confirmResponse.statusCode != 200) {
        return UploadResult(success: false, error: 'Failed to save document');
      }

      return UploadResult(
        success: true,
        url: publicUrl,
        message: 'Document uploaded successfully',
      );
    } catch (e) {
      debugPrint('UploadService: Upload error: $e');
      return UploadResult(success: false, error: 'Upload failed: $e');
    }
  }

  /// Take a photo with camera and upload as delivery proof
  Future<UploadResult> captureAndUploadDeliveryPhoto({
    required String orderId,
    required DeliveryPhotoType photoType,
  }) async {
    final file = await pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
      quality: 80,
    );

    if (file == null) {
      return UploadResult(success: false, error: 'No photo captured');
    }

    return uploadDeliveryPhoto(
      orderId: orderId,
      photoType: photoType,
      file: file,
    );
  }
}

class UploadResult {
  final bool success;
  final String? url;
  final String? path;
  final String? error;
  final String? message;
  final String? compressionRatio;

  UploadResult({
    required this.success,
    this.url,
    this.path,
    this.error,
    this.message,
    this.compressionRatio,
  });

  @override
  String toString() {
    return 'UploadResult(success: $success, url: $url, error: $error, compression: $compressionRatio)';
  }
}
