import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/entities/category.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<Category>>> getCategories();

  Future<Either<Failure, Category>> createCategory({
    required String name,
    required String platform,
    required String platformCategoryId,
  });
}
