sealed class CategoryListEvent {}

final class FetchCategoriesRequested extends CategoryListEvent {}

final class SearchCategoriesRequested extends CategoryListEvent {
  final String query;

  SearchCategoriesRequested({required this.query});
}

final class CategoryDeletedLocally extends CategoryListEvent {
  final int categoryId;

  CategoryDeletedLocally({required this.categoryId});
}
