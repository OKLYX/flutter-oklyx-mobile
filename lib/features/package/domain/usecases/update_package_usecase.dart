import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/repositories/package_repository.dart';

class UpdatePackageUseCase {
  final PackageRepository repository;

  UpdatePackageUseCase({required this.repository});

  Future<Either<Failure, Package>> call({
    required int id,
    required String type,
    required double cost,
    required bool isDefault,
    required double widthCm,
    required double lengthCm,
    required double heightCm,
  }) {
    return repository.updatePackage(
      id: id,
      type: type,
      cost: cost,
      isDefault: isDefault,
      widthCm: widthCm,
      lengthCm: lengthCm,
      heightCm: heightCm,
    );
  }
}
