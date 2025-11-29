import 'package:dartz/dartz.dart';
import 'package:bridgecore_flutter_starter/core/domain/usecases/base_usecase.dart';
import 'package:bridgecore_flutter_starter/core/error/failures.dart';
import 'package:bridgecore_flutter_starter/features/auth/domain/entities/user.dart';
import 'package:bridgecore_flutter_starter/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase implements NoParamsUseCase<User> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call() async {
    return await repository.getCurrentUser();
  }
}
