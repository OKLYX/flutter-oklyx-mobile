import 'package:flutter_oklyn_mobile/features/category/domain/entities/category.dart';

sealed class CategoryListState {}

final class CategoryListInitial extends CategoryListState {}

final class CategoryListLoading extends CategoryListState {}

final class CategoryListLoaded extends CategoryListState {
  final List<Category> categories;

  CategoryListLoaded({required this.categories});
}

final class CategoryListError extends CategoryListState {
  final String message;

  CategoryListError({required this.message});
}
