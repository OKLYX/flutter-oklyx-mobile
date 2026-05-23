import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/entities/category.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/repositories/category_repository.dart';

class CreateCategoryUseCase {
  final CategoryRepository repository;

  CreateCategoryUseCase({required this.repository});

  Future<Either<Failure, Category>> call({
    required String name,
    required String platform,
    required String platformCategoryId,
    int? parentId,
  }) {
    return repository.createCategory(
      name: name,
      platform: platform,
      platformCategoryId: platformCategoryId,
      parentId: parentId,
    );
  }
}
