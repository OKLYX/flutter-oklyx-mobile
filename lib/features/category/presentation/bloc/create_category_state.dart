sealed class CreateCategoryState {}

final class CreateCategoryInitial extends CreateCategoryState {}

final class CreateCategoryEditing extends CreateCategoryState {
  final String name;
  final String platform;
  final String platformCategoryId;
  final int? parentId;
  final bool isValid;

  CreateCategoryEditing({
    required this.name,
    required this.platform,
    required this.platformCategoryId,
    required this.parentId,
    required this.isValid,
  });
}

final class CreateCategoryLoading extends CreateCategoryState {}

final class CreateCategorySuccess extends CreateCategoryState {}

final class CreateCategoryError extends CreateCategoryState {
  final String message;

  CreateCategoryError({required this.message});
}
