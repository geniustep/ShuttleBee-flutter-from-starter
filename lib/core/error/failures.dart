import 'package:equatable/equatable.dart';

/// Base failure class
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

/// Server failure
class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Network failure
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

/// Unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure({required super.message});
}

/// Permission failure
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message});
}

/// Timeout failure
class TimeoutFailure extends Failure {
  const TimeoutFailure({required super.message});
}

/// Exceptions (to be caught and converted to failures)

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}
