import 'package:flutter_oklyn_mobile/features/category/domain/entities/category.dart';

sealed class CategoryDetailState {}

final class CategoryDetailInitial extends CategoryDetailState {}

final class CategoryDetailLoading extends CategoryDetailState {}

final class CategoryDetailLoaded extends CategoryDetailState {
  final Category category;

  CategoryDetailLoaded({required this.category});
}

final class CategoryDetailDeleting extends CategoryDetailState {}

final class CategoryDetailDeleteSuccess extends CategoryDetailState {}

final class CategoryDetailError extends CategoryDetailState {
  final String message;

  CategoryDetailError({required this.message});
}
