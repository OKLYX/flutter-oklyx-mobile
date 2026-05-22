sealed class CategoryListEvent {}

final class FetchCategoriesRequested extends CategoryListEvent {}

final class SearchCategoriesRequested extends CategoryListEvent {
  final String query;

  SearchCategoriesRequested({required this.query});
}
