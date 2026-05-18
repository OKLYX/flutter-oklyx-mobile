import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/repositories/package_repository.dart';

class GetPackagesUseCase {
  final PackageRepository repository;

  GetPackagesUseCase({required this.repository});

  Future<Either<Failure, List<Package>>> call() {
    return repository.getPackages();
  }
}
