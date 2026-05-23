import 'package:flutter_oklyn_mobile/features/category/domain/entities/category.dart';

sealed class CategoryDetailState {}

final class CategoryDetailInitial extends CategoryDetailState {}

final class CategoryDetailLoading extends CategoryDetailState {}

final class CategoryDetailLoaded extends CategoryDetailState {
  final Category category;
  final String editName;
  final String editPlatform;
  final String editPlatformCategoryId;
  final String editParentId;

  CategoryDetailLoaded({
    required this.category,
    String? editName,
    String? editPlatform,
    String? editPlatformCategoryId,
    String? editParentId,
  })  : editName = editName ?? category.name,
        editPlatform = editPlatform ?? category.platform,
        editPlatformCategoryId = editPlatformCategoryId ?? category.platformCategoryId,
        editParentId = editParentId ?? (category.parentId?.toString() ?? '');

  CategoryDetailLoaded copyWith({
    Category? category,
    String? editName,
    String? editPlatform,
    String? editPlatformCategoryId,
    String? editParentId,
  }) {
    return CategoryDetailLoaded(
      category: category ?? this.category,
      editName: editName ?? this.editName,
      editPlatform: editPlatform ?? this.editPlatform,
      editPlatformCategoryId: editPlatformCategoryId ?? this.editPlatformCategoryId,
      editParentId: editParentId ?? this.editParentId,
    );
  }
}

final class CategoryDetailDeleting extends CategoryDetailState {}

final class CategoryDetailDeleteSuccess extends CategoryDetailState {}

final class CategoryDetailSuccess extends CategoryDetailState {}

final class CategoryDetailError extends CategoryDetailState {
  final String message;

  CategoryDetailError({required this.message});
}
