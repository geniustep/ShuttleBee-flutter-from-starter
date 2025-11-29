import 'package:dartz/dartz.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import 'package:bridgecore_flutter_starter/core/error/failures.dart';
import 'package:bridgecore_flutter_starter/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, TenantSession>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> getCurrentUser();

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, String>> refreshToken();

  Future<Either<Failure, bool>> isAuthenticated();
}
