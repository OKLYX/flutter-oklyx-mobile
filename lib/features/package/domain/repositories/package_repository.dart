import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';

abstract class PackageRepository {
  Future<Either<Failure, List<Package>>> getPackages();
}
