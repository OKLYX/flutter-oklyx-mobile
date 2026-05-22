sealed class CategoryDetailEvent {}

final class FetchCategoryRequested extends CategoryDetailEvent {
  final int categoryId;

  FetchCategoryRequested({required this.categoryId});
}

final class DeleteCategoryRequested extends CategoryDetailEvent {
  final int categoryId;

  DeleteCategoryRequested(this.categoryId);
}
