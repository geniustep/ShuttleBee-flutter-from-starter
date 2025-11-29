import 'package:dartz/dartz.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import 'package:bridgecore_flutter_starter/core/data/datasources/local_data_source.dart';
import 'package:bridgecore_flutter_starter/core/data/datasources/remote_data_source.dart';
import 'package:bridgecore_flutter_starter/core/data/repositories/base_repository.dart';
import 'package:bridgecore_flutter_starter/core/error/failures.dart';
import 'package:bridgecore_flutter_starter/features/auth/domain/entities/user.dart';
import 'package:bridgecore_flutter_starter/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final CacheDataSource cacheDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheDataSource,
  });

  @override
  Future<Either<Failure, TenantSession>> login({
    required String email,
    required String password,
  }) async {
    return execute(() async {
      final session = await remoteDataSource.login(
        email: email,
        password: password,
        
      );

      // Cache user session
      await cacheDataSource.save(
        key: 'user_session',
        data: session.toJson(),
        ttl: const Duration(days: 7),
      );

      return session;
    });
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    return execute(() async {
      // Try to get from cache first
      final cachedUser = await cacheDataSource.get<Map<String, dynamic>>(
        'current_user',
      );

      if (cachedUser != null) {
        return User.fromJson(cachedUser);
      }

      // Fetch from remote
      final meResponse = await remoteDataSource.getCurrentUser();

      final user = User.fromTenantMeResponse(meResponse);

      // Cache the user
      await cacheDataSource.save(
        key: 'current_user',
        data: user.toJson(),
        ttl: const Duration(hours: 1),
      );

      return user;
    });
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return execute(() async {
      await remoteDataSource.logout();

      // Clear cached user data
      await cacheDataSource.delete('user_session');
      await cacheDataSource.delete('current_user');
    });
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    return execute(() async {
      return await remoteDataSource.refreshToken();
    });
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    return execute(() async {
      final session = await cacheDataSource.get<Map<String, dynamic>>(
        'user_session',
      );
      return session != null;
    });
  }
}
