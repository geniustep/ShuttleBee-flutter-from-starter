import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import 'package:bridgecore_flutter_starter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bridgecore_flutter_starter/core/data/datasources/remote_data_source.dart';
import 'package:bridgecore_flutter_starter/core/data/datasources/local_data_source.dart';
import 'package:bridgecore_flutter_starter/core/error/failures.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockCacheDataSource extends Mock implements CacheDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockCacheDataSource mockCacheDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockCacheDataSource = MockCacheDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      cacheDataSource: mockCacheDataSource,
    );
  });

  group('login', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';

    test('should return TenantSession when login is successful', () async {
      // Arrange
      final tSession = TenantSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        tokenType: 'Bearer',
        expiresIn: 3600,
        user: TenantUser(
          id: '1',
          email: tEmail,
          fullName: 'Test User',
          role: 'admin',
        ),
        tenant: Tenant(
          id: 'tenant_1',
          name: 'Test Tenant',
          slug: 'test-tenant',
          status: 'active',
        ),
      );

      when(
        () => mockRemoteDataSource.login(
          email: tEmail,
          password: tPassword,
        ),
      ).thenAnswer((_) async => tSession);

      when(
        () => mockCacheDataSource.save(
          key: any(named: 'key'),
          data: any(named: 'data'),
          ttl: any(named: 'ttl'),
        ),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.login(
        email: tEmail,
        password: tPassword,
      );

      // Assert
      expect(result, equals(Right(tSession)));
      verify(
        () => mockRemoteDataSource.login(
          email: tEmail,
          password: tPassword,
        ),
      ).called(1);
    });

    test('should return AuthFailure when login fails', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.login(
          email: tEmail,
          password: tPassword,
        ),
      ).thenThrow(AuthException('Invalid credentials'));

      // Act
      final result = await repository.login(
        email: tEmail,
        password: tPassword,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<AuthFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });
}
