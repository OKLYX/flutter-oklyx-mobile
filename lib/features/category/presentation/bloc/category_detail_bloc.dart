import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/usecases/delete_category_usecase.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/usecases/get_category_usecase.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_detail_event.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_detail_state.dart';

class CategoryDetailBloc extends Bloc<CategoryDetailEvent, CategoryDetailState> {
  final GetCategoryUseCase getCategoryUseCase;
  final DeleteCategoryUseCase deleteCategoryUseCase;

  CategoryDetailBloc({
    required this.getCategoryUseCase,
    required this.deleteCategoryUseCase,
  }) : super(CategoryDetailInitial()) {
    on<FetchCategoryRequested>(_onFetchCategoryRequested);
    on<DeleteCategoryRequested>(_onDeleteCategoryRequested);
  }

  Future<void> _onFetchCategoryRequested(
    FetchCategoryRequested event,
    Emitter<CategoryDetailState> emit,
  ) async {
    emit(CategoryDetailLoading());

    final result = await getCategoryUseCase(event.categoryId);

    result.fold(
      (failure) => emit(CategoryDetailError(message: failure.message)),
      (category) => emit(CategoryDetailLoaded(category: category)),
    );
  }

  Future<void> _onDeleteCategoryRequested(
    DeleteCategoryRequested event,
    Emitter<CategoryDetailState> emit,
  ) async {
    emit(CategoryDetailDeleting());

    final result = await deleteCategoryUseCase(event.categoryId);

    result.fold(
      (failure) => emit(CategoryDetailError(message: failure.message)),
      (_) => emit(CategoryDetailDeleteSuccess()),
    );
  }
}
