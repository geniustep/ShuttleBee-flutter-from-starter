import 'package:dartz/dartz.dart';
import 'package:bridgecore_flutter_starter/core/error/failures.dart';

/// Base use case interface
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use case with no parameters
abstract class NoParamsUseCase<T> {
  Future<Either<Failure, T>> call();
}

/// Use case with stream result
abstract class StreamUseCase<T, Params> {
  Stream<Either<Failure, T>> call(Params params);
}

/// No parameters class
class NoParams {
  const NoParams();
}
