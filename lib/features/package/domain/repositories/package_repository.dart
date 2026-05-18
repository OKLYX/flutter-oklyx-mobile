import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/models/create_package_params.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';

abstract class PackageRepository {
  Future<Either<Failure, List<Package>>> getPackages();
  Future<Either<Failure, Package>> createPackage(CreatePackageParams params);
  Future<Either<Failure, Package>> updatePackage({
    required int id,
    required String type,
    required double cost,
    required String effectiveDate,
    required bool isDefault,
  });
}
