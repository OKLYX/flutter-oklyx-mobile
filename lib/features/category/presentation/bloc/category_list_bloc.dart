import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/entities/category.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/usecases/get_categories_usecase.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_event.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_state.dart';

class CategoryListBloc extends Bloc<CategoryListEvent, CategoryListState> {
  final GetCategoriesUseCase getCategoriesUseCase;
  List<Category> _allCategories = [];

  CategoryListBloc({required this.getCategoriesUseCase})
      : super(CategoryListInitial()) {
    on<FetchCategoriesRequested>(_onFetchCategoriesRequested);
    on<SearchCategoriesRequested>(_onSearchCategoriesRequested);
  }

  Future<void> _onFetchCategoriesRequested(
    FetchCategoriesRequested event,
    Emitter<CategoryListState> emit,
  ) async {
    emit(CategoryListLoading());

    final result = await getCategoriesUseCase();

    result.fold(
      (failure) {
        emit(CategoryListError(message: failure.message));
      },
      (categories) {
        _allCategories = categories;
        emit(CategoryListLoaded(categories: categories));
      },
    );
  }

  Future<void> _onSearchCategoriesRequested(
    SearchCategoriesRequested event,
    Emitter<CategoryListState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(CategoryListLoaded(categories: _allCategories));
      return;
    }

    final filtered = _allCategories
        .where((category) =>
            category.name.toLowerCase().contains(event.query.toLowerCase()) ||
            category.platform.toLowerCase().contains(event.query.toLowerCase()))
        .toList();

    emit(CategoryListLoaded(categories: filtered));
  }
}
