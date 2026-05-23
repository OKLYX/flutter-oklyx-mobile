sealed class CategoryDetailEvent {}

final class FetchCategoryRequested extends CategoryDetailEvent {
  final int categoryId;

  FetchCategoryRequested({required this.categoryId});
}

final class NameDetailChanged extends CategoryDetailEvent {
  final String name;
  NameDetailChanged(this.name);
}

final class PlatformDetailChanged extends CategoryDetailEvent {
  final String platform;
  PlatformDetailChanged(this.platform);
}

final class PlatformCategoryIdDetailChanged extends CategoryDetailEvent {
  final String platformCategoryId;
  PlatformCategoryIdDetailChanged(this.platformCategoryId);
}

final class ParentIdDetailChanged extends CategoryDetailEvent {
  final String parentId;
  ParentIdDetailChanged(this.parentId);
}

final class UpdateCategorySubmitted extends CategoryDetailEvent {}

final class DeleteCategoryRequested extends CategoryDetailEvent {
  final int categoryId;

  DeleteCategoryRequested(this.categoryId);
}
