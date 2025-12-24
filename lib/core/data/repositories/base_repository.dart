import 'package:dartz/dartz.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart' as bridgecore;
import 'package:bridgecore_flutter_starter/core/error/failures.dart';
import 'package:bridgecore_flutter_starter/core/error_handling/exceptions.dart'
    as AppExceptions;

/// Base repository interface
abstract class BaseRepository {
  /// Execute a repository call with error handling
  Future<Either<Failure, T>> execute<T>(
    Future<T> Function() call, {
    String? errorMessage,
  }) async {
    try {
      final result = await call();
      return Right(result);
    } on AppExceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AppExceptions.CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on AppExceptions.NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AppExceptions.AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on AppExceptions.ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on bridgecore.MissingOdooCredentialsException catch (_) {
      return const Left(
        AuthFailure(
          message: 'انتهت صلاحية الجلسة. يرجى تسجيل الخروج وإعادة تسجيل الدخول',
        ),
      );
    } on bridgecore.UnauthorizedException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on bridgecore.ForbiddenException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      // Check if it's an authentication error by message
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('missing odoo credentials') ||
          errorString.contains('no tokens found') ||
          errorString.contains('not authenticated') ||
          errorString.contains('403') ||
          (errorString.contains('400') &&
              errorString.contains('credentials'))) {
        return const Left(
          AuthFailure(
            message:
                'انتهت صلاحية الجلسة. يرجى تسجيل الخروج وإعادة تسجيل الدخول',
          ),
        );
      }
      return Left(UnknownFailure(message: errorMessage ?? e.toString()));
    }
  }
}
