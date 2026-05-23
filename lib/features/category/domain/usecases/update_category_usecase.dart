import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/entities/category.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/repositories/category_repository.dart';

class UpdateCategoryUseCase {
  final CategoryRepository repository;

  UpdateCategoryUseCase({required this.repository});

  Future<Either<Failure, Category>> call({
    required int id,
    required String name,
    required String platform,
    required String platformCategoryId,
    required int? parentId,
  }) {
    return repository.updateCategory(
      id: id,
      name: name,
      platform: platform,
      platformCategoryId: platformCategoryId,
      parentId: parentId,
    );
  }
}
