import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/models/create_package_params.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/repositories/package_repository.dart';

class CreatePackageUseCase {
  final PackageRepository repository;

  CreatePackageUseCase({required this.repository});

  Future<Either<Failure, Package>> call(CreatePackageParams params) =>
      repository.createPackage(params);
}
