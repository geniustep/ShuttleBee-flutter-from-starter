import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';

/// File service for file management
class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (image != null) {
        AppLogger.info('Image picked: ${image.path}');
        return File(image.path);
      }

      return null;
    } catch (e) {
      AppLogger.error('Error picking image: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>?> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (images.isNotEmpty) {
        AppLogger.info('${images.length} images picked');
        return images.map((xFile) => File(xFile.path)).toList();
      }

      return null;
    } catch (e) {
      AppLogger.error('Error picking multiple images: $e');
      return null;
    }
  }

  /// Pick video from gallery or camera
  Future<File?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );

      if (video != null) {
        AppLogger.info('Video picked: ${video.path}');
        return File(video.path);
      }

      return null;
    } catch (e) {
      AppLogger.error('Error picking video: $e');
      return null;
    }
  }

  /// Crop image
  Future<File?> cropImage({
    required File imageFile,
    CropAspectRatio? aspectRatio,
    int? maxWidth,
    int? maxHeight,
    int? compressQuality,
  }) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: aspectRatio,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF2196F3),
            toolbarWidgetColor: const Color(0xFFFFFFFF),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
        compressQuality: compressQuality ?? 90,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (croppedFile != null) {
        AppLogger.info('Image cropped: ${croppedFile.path}');
        return File(croppedFile.path);
      }

      return null;
    } catch (e) {
      AppLogger.error('Error cropping image: $e');
      return null;
    }
  }

  /// Compress image
  Future<File?> compressImage({
    required File imageFile,
    int quality = 85,
    int? targetWidth,
    int? targetHeight,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path,
        'cmp_${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: targetWidth!,
        minHeight: targetHeight!,
      );

      if (result == null) {
        AppLogger.warning('Image compression returned null result');
        return null;
      }

      AppLogger.info('Image compressed: ${result.path}');
      return File(result.path);
    } catch (e) {
      AppLogger.error('Error compressing image: $e');
      return null;
    }
  }

  /// Pick file
  Future<File?> pickFile({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        AppLogger.info('File picked: ${file.path}');
        return file;
      }

      return null;
    } catch (e) {
      AppLogger.error('Error picking file: $e');
      return null;
    }
  }

  /// Pick multiple files
  Future<List<File>?> pickMultipleFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final files = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
        AppLogger.info('${files.length} files picked');
        return files;
      }

      return null;
    } catch (e) {
      AppLogger.error('Error picking multiple files: $e');
      return null;
    }
  }

  /// Open file
  Future<void> openFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type == ResultType.done) {
        AppLogger.info('File opened: $filePath');
      } else {
        AppLogger.warning('Failed to open file: ${result.message}');
      }
    } catch (e) {
      AppLogger.error('Error opening file: $e');
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(File file) async {
    return await file.length();
  }

  /// Get file size formatted
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Save file to app directory
  Future<File?> saveFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      AppLogger.info('File saved: ${file.path}');
      return file;
    } catch (e) {
      AppLogger.error('Error saving file: $e');
      return null;
    }
  }

  /// Delete file
  Future<bool> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        AppLogger.info('File deleted: ${file.path}');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error deleting file: $e');
      return false;
    }
  }

  /// Get temp directory
  Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }

  /// Get app documents directory
  Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Clear temp directory
  Future<void> clearTempDirectory() async {
    try {
      final tempDir = await getTempDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create();
        AppLogger.info('Temp directory cleared');
      }
    } catch (e) {
      AppLogger.error('Error clearing temp directory: $e');
    }
  }
}

/// Camera service
class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  List<CameraDescription>? _cameras;
  CameraController? _controller;

  /// Get available cameras
  Future<List<CameraDescription>> getAvailableCameras() async {
    _cameras ??= await availableCameras();
    return _cameras!;
  }

  /// Initialize camera
  Future<CameraController?> initializeCamera({
    CameraLensDirection direction = CameraLensDirection.back,
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    try {
      final cameras = await getAvailableCameras();

      if (cameras.isEmpty) {
        AppLogger.warning('No cameras available');
        return null;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == direction,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        resolution,
        enableAudio: false,
      );

      await _controller!.initialize();
      AppLogger.info('Camera initialized');

      return _controller;
    } catch (e) {
      AppLogger.error('Error initializing camera: $e');
      return null;
    }
  }

  /// Take picture
  Future<File?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      AppLogger.warning('Camera not initialized');
      return null;
    }

    try {
      final XFile image = await _controller!.takePicture();
      AppLogger.info('Picture taken: ${image.path}');
      return File(image.path);
    } catch (e) {
      AppLogger.error('Error taking picture: $e');
      return null;
    }
  }

  /// Dispose camera
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
