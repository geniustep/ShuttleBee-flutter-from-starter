import 'package:dartz/dartz.dart';
import 'package:bridgecore_flutter_starter/core/error/failures.dart';

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
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: errorMessage ?? e.toString()));
    }
  }
}
