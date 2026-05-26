import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/entities/category.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/usecases/get_categories_usecase.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_event_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_event.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_state.dart';

class CategoryListBloc extends Bloc<CategoryListEvent, CategoryListState> {
  final GetCategoriesUseCase getCategoriesUseCase;
  final CategoryEventBloc categoryEventBloc;

  List<Category> _allCategories = [];
  StreamSubscription? _categoryEventSubscription;

  CategoryListBloc({
    required this.getCategoriesUseCase,
    required this.categoryEventBloc,
  }) : super(CategoryListInitial()) {
    on<FetchCategoriesRequested>(_onFetchCategoriesRequested);
    on<SearchCategoriesRequested>(_onSearchCategoriesRequested);
    on<CategoryDeletedLocally>(_onCategoryDeletedLocally);

    _setupEventStreamSubscription();
  }

  /// CategoryEventBloc의 stream을 구독하여 삭제/수정 이벤트 감지
  void _setupEventStreamSubscription() {
    _categoryEventSubscription = categoryEventBloc.stream.listen(
      (eventState) {
        if (eventState is CategoryDeletedEventBroadcasted) {
          // 삭제 이벤트 수신 → 로컬 상태에서 즉시 제거
          add(CategoryDeletedLocally(categoryId: eventState.categoryId));
        } else if (eventState is CategoryUpdatedEventBroadcasted) {
          // 수정 이벤트 수신 (필요시 처리)
        }
      },
    );
  }

  @override
  Future<void> close() async {
    await _categoryEventSubscription?.cancel();
    await super.close();
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

  /// Optimistic Update: 로컬 상태에서 해당 카테고리를 즉시 제거
  Future<void> _onCategoryDeletedLocally(
    CategoryDeletedLocally event,
    Emitter<CategoryListState> emit,
  ) async {
    // 로컬 캐시에서 해당 id의 카테고리 제거
    _allCategories.removeWhere((category) => category.id == event.categoryId);

    // 현재 상태가 로드된 상태면 UI 업데이트
    if (state is CategoryListLoaded) {
      final currentState = state as CategoryListLoaded;
      final updatedCategories = currentState.categories
          .where((category) => category.id != event.categoryId)
          .toList();
      emit(CategoryListLoaded(categories: updatedCategories));
    }
  }
}
