import 'package:dartz/dartz.dart';

import '../../error/failures.dart';
import '../domain/local_storage_repository.dart';

/// Local cache for Media & Attachments
///
/// Provides offline-first caching for:
/// - Image thumbnails metadata
/// - File metadata
/// - Download status
class MediaLocalCache {
  final LocalStorageRepository _storage;

  // Collection names
  static const String _thumbnailsCollection = 'media_thumbnails';
  static const String _fileMetadataCollection = 'file_metadata';
  static const String _downloadStatusCollection = 'download_status';

  // Cache TTL
  static const Duration _thumbnailsTTL = Duration(days: 30);
  static const Duration _fileMetadataTTL = Duration(days: 90);
  // Download status: Until downloaded

  MediaLocalCache(this._storage);

  // ════════════════════════════════════════════════════════════
  // Thumbnails Cache
  // ════════════════════════════════════════════════════════════

  /// Save thumbnail metadata
  Future<Either<Failure, bool>> cacheThumbnail({
    required String mediaId,
    required String thumbnailUrl,
    String? localPath,
    int? width,
    int? height,
    int? sizeBytes,
  }) async {
    try {
      final thumbnailsResult = await getThumbnails();
      return await thumbnailsResult.fold(
        (failure) => Left(failure),
        (thumbnails) async {
          // Remove if exists
          thumbnails.removeWhere((t) => t['media_id'] == mediaId);

          // Add
          thumbnails.insert(0, {
            'media_id': mediaId,
            'thumbnail_url': thumbnailUrl,
            'local_path': localPath,
            'width': width,
            'height': height,
            'size_bytes': sizeBytes,
            'cached_at': DateTime.now().toIso8601String(),
          });

          return await _storage.saveCollection(
            collectionName: _thumbnailsCollection,
            items: thumbnails,
            ttl: _thumbnailsTTL,
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache thumbnail: $e'));
    }
  }

  /// Get thumbnail metadata
  Future<Either<Failure, Map<String, dynamic>?>> getThumbnail(String mediaId) async {
    final thumbnailsResult = await getThumbnails();
    return thumbnailsResult.fold(
      (failure) => Left(failure),
      (thumbnails) {
        try {
          final thumbnail = thumbnails.firstWhere(
            (t) => t['media_id'] == mediaId,
            orElse: () => throw Exception('Thumbnail not found'),
          );
          return Right(thumbnail);
        } catch (_) {
          return const Right(null);
        }
      },
    );
  }

  /// Get all thumbnails
  Future<Either<Failure, List<Map<String, dynamic>>>> getThumbnails() async {
    return await _storage.loadCollection(_thumbnailsCollection);
  }

  // ════════════════════════════════════════════════════════════
  // File Metadata Cache
  // ════════════════════════════════════════════════════════════

  /// Save file metadata
  Future<Either<Failure, bool>> cacheFileMetadata({
    required String fileId,
    required String fileName,
    required int fileSize,
    String? fileUrl,
    String? localPath,
    String? mimeType,
    DateTime? uploadedAt,
  }) async {
    try {
      final metadataResult = await getFileMetadata();
      return await metadataResult.fold(
        (failure) => Left(failure),
        (metadata) async {
          // Remove if exists
          metadata.removeWhere((m) => m['file_id'] == fileId);

          // Add
          metadata.insert(0, {
            'file_id': fileId,
            'file_name': fileName,
            'file_size': fileSize,
            'file_url': fileUrl,
            'local_path': localPath,
            'mime_type': mimeType,
            'uploaded_at': uploadedAt?.toIso8601String(),
            'cached_at': DateTime.now().toIso8601String(),
          });

          return await _storage.saveCollection(
            collectionName: _fileMetadataCollection,
            items: metadata,
            ttl: _fileMetadataTTL,
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache metadata: $e'));
    }
  }

  /// Get file metadata
  Future<Either<Failure, Map<String, dynamic>?>> getFileMetadataById(
    String fileId,
  ) async {
    final metadataResult = await getFileMetadata();
    return metadataResult.fold(
      (failure) => Left(failure),
      (metadata) {
        try {
          final fileMeta = metadata.firstWhere(
            (m) => m['file_id'] == fileId,
            orElse: () => throw Exception('Metadata not found'),
          );
          return Right(fileMeta);
        } catch (_) {
          return const Right(null);
        }
      },
    );
  }

  /// Get all file metadata
  Future<Either<Failure, List<Map<String, dynamic>>>> getFileMetadata() async {
    return await _storage.loadCollection(_fileMetadataCollection);
  }

  // ════════════════════════════════════════════════════════════
  // Download Status Cache
  // ════════════════════════════════════════════════════════════

  /// Save download status
  Future<Either<Failure, bool>> cacheDownloadStatus({
    required String fileId,
    required String status, // 'pending', 'downloading', 'completed', 'failed'
    double? progress,
    String? localPath,
    String? error,
  }) async {
    try {
      return await _storage.save(
        key: '$_downloadStatusCollection$fileId',
        data: {
          'file_id': fileId,
          'status': status,
          'progress': progress,
          'local_path': localPath,
          'error': error,
          'updated_at': DateTime.now().toIso8601String(),
        },
        ttl: null, // Until downloaded
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache status: $e'));
    }
  }

  /// Get download status
  Future<Either<Failure, Map<String, dynamic>?>> getDownloadStatus(
    String fileId,
  ) async {
    final result = await _storage.load('$_downloadStatusCollection$fileId');
    return result.fold(
      (failure) => Left(failure),
      (data) => Right(data),
    );
  }

  /// Mark download as completed
  Future<Either<Failure, bool>> markDownloadCompleted(
    String fileId,
    String localPath,
  ) async {
    return await cacheDownloadStatus(
      fileId: fileId,
      status: 'completed',
      localPath: localPath,
      progress: 1.0,
    );
  }

  /// Mark download as failed
  Future<Either<Failure, bool>> markDownloadFailed(
    String fileId,
    String error,
  ) async {
    return await cacheDownloadStatus(
      fileId: fileId,
      status: 'failed',
      error: error,
    );
  }

  // ════════════════════════════════════════════════════════════
  // Cache Management
  // ════════════════════════════════════════════════════════════

  /// Clear all media caches
  Future<Either<Failure, bool>> clearAllCaches() async {
    try {
      await _storage.deleteCollection(_thumbnailsCollection);
      await _storage.deleteCollection(_fileMetadataCollection);
      // Download status keys are individual, will be cleaned via TTL
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear caches: $e'));
    }
  }

  /// Get cache statistics
  Future<Either<Failure, Map<String, dynamic>>> getCacheStats() async {
    return _storage.getStats();
  }
}

