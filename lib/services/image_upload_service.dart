import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';

/// A safe, user-facing image upload failure.
class ImageUploadFailure implements Exception {
  const ImageUploadFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Picks, validates, compresses, and uploads room photos to Cloudinary.
class ImageUploadService {
  ImageUploadService({ImagePicker? picker, http.Client? client})
    : _picker = picker ?? ImagePicker(),
      _client = client ?? http.Client();

  static const Set<String> _allowedExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  };

  final ImagePicker _picker;
  final http.Client _client;

  Future<String?> pickAndUpload({
    required ImageSource source,
    bool compressAlways = false,
    int maxWidth = 1600,
    int maxHeight = 1600,
    int imageQuality = 82,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      if (picked == null) return null;
      return await upload(picked, compressAlways: compressAlways);
    } on ImageUploadFailure {
      rethrow;
    } catch (_) {
      throw const ImageUploadFailure(
        'Could not open the image picker. Please try again.',
      );
    }
  }

  Future<String> upload(XFile file, {bool compressAlways = false}) async {
    final extension = _extensionFor(file);
    if (extension.isEmpty) {
      throw const ImageUploadFailure('Choose a JPG, PNG, WebP, or HEIC image.');
    }

    var bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const ImageUploadFailure('That image file is empty.');
    }
    if (compressAlways || bytes.length > AppConstants.maxImageBytes) {
      bytes = await _compress(file, bytes);
    }
    if (bytes.length > AppConstants.maxImageBytes) {
      throw const ImageUploadFailure(
        'That image is larger than 5 MB after compression. Choose another.',
      );
    }

    try {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse(AppConstants.cloudinaryUploadUrl),
            )
            ..fields['upload_preset'] = AppConstants.cloudinaryUploadPreset
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                bytes,
                filename:
                    'boardease-${DateTime.now().millisecondsSinceEpoch}.$extension',
              ),
            );
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ImageUploadFailure(
          'The photo could not be uploaded. Please try again.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ImageUploadFailure('The upload returned invalid data.');
      }
      final url = decoded['secure_url'];
      if (url is! String || !url.startsWith('https://res.cloudinary.com/')) {
        throw const ImageUploadFailure(
          'The upload did not return a secure image URL.',
        );
      }
      return url;
    } on ImageUploadFailure {
      rethrow;
    } catch (_) {
      throw const ImageUploadFailure(
        'Could not upload the photo. Check your connection and try again.',
      );
    }
  }

  Future<Uint8List> _compress(XFile file, Uint8List original) async {
    if (file.path.isEmpty) return original;
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        file.path,
        minWidth: AppConstants.imageMaxDimension,
        minHeight: AppConstants.imageMaxDimension,
        quality: AppConstants.imageQuality,
        format: CompressFormat.jpeg,
      );
      return compressed ?? original;
    } catch (_) {
      return original;
    }
  }

  String _extensionFor(XFile file) {
    final name = file.name.toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot >= 0) {
      final extension = name.substring(dot + 1);
      if (_allowedExtensions.contains(extension)) return extension;
      return '';
    }
    final mime = (file.mimeType ?? '').toLowerCase();
    if (mime == 'image/jpeg') return 'jpg';
    if (mime == 'image/png') return 'png';
    if (mime == 'image/webp') return 'webp';
    if (mime == 'image/heic') return 'heic';
    if (mime == 'image/heif') return 'heif';
    return '';
  }
}
