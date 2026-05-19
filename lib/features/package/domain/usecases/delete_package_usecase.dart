import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/repositories/package_repository.dart';

class DeletePackageUseCase {
  final PackageRepository repository;

  DeletePackageUseCase({required this.repository});

  Future<Either<Failure, void>> call(int id) {
    return repository.deletePackage(id);
  }
}
