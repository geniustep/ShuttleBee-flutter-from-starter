import 'package:dartz/dartz.dart';
import 'package:bridgecore_flutter_starter/core/domain/usecases/base_usecase.dart';
import 'package:bridgecore_flutter_starter/core/error/failures.dart';
import 'package:bridgecore_flutter_starter/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase implements NoParamsUseCase<void> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}
