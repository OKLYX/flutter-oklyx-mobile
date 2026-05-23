sealed class CreateCategoryEvent {}

final class CreateCategoryNameChanged extends CreateCategoryEvent {
  final String name;

  CreateCategoryNameChanged({required this.name});
}

final class CreateCategoryPlatformChanged extends CreateCategoryEvent {
  final String platform;

  CreateCategoryPlatformChanged({required this.platform});
}

final class CreateCategoryIdChanged extends CreateCategoryEvent {
  final String platformCategoryId;

  CreateCategoryIdChanged({required this.platformCategoryId});
}

final class CreateCategoryParentIdChanged extends CreateCategoryEvent {
  final int? parentId;

  CreateCategoryParentIdChanged({required this.parentId});
}

final class CreateCategorySubmitted extends CreateCategoryEvent {}
