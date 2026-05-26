import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/usecases/delete_category_usecase.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/usecases/get_category_usecase.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/usecases/update_category_usecase.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_event_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_detail_event.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_detail_state.dart';

class CategoryDetailBloc extends Bloc<CategoryDetailEvent, CategoryDetailState> {
  final GetCategoryUseCase getCategoryUseCase;
  final UpdateCategoryUseCase updateCategoryUseCase;
  final DeleteCategoryUseCase deleteCategoryUseCase;
  final CategoryEventBloc categoryEventBloc;

  String _editName = '';
  String _editPlatform = '';
  String _editPlatformCategoryId = '';
  String _editParentId = '';

  CategoryDetailBloc({
    required this.getCategoryUseCase,
    required this.updateCategoryUseCase,
    required this.deleteCategoryUseCase,
    required this.categoryEventBloc,
  }) : super(CategoryDetailInitial()) {
    on<FetchCategoryRequested>(_onFetchCategoryRequested);
    on<NameDetailChanged>(_onNameChanged);
    on<PlatformDetailChanged>(_onPlatformChanged);
    on<PlatformCategoryIdDetailChanged>(_onPlatformCategoryIdChanged);
    on<ParentIdDetailChanged>(_onParentIdChanged);
    on<UpdateCategorySubmitted>(_onUpdateSubmitted);
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
      (category) {
        _editName = category.name;
        _editPlatform = category.platform;
        _editPlatformCategoryId = category.platformCategoryId;
        _editParentId = category.parentId?.toString() ?? '';
        emit(CategoryDetailLoaded(category: category));
      },
    );
  }

  void _onNameChanged(NameDetailChanged event, Emitter<CategoryDetailState> emit) {
    _editName = event.name;
  }

  void _onPlatformChanged(PlatformDetailChanged event, Emitter<CategoryDetailState> emit) {
    _editPlatform = event.platform;
  }

  void _onPlatformCategoryIdChanged(
    PlatformCategoryIdDetailChanged event,
    Emitter<CategoryDetailState> emit,
  ) {
    _editPlatformCategoryId = event.platformCategoryId;
  }

  void _onParentIdChanged(ParentIdDetailChanged event, Emitter<CategoryDetailState> emit) {
    _editParentId = event.parentId;
  }

  Future<void> _onUpdateSubmitted(
    UpdateCategorySubmitted event,
    Emitter<CategoryDetailState> emit,
  ) async {
    final state = this.state;
    if (state is! CategoryDetailLoaded) return;

    emit(CategoryDetailLoading());

    final parentId = _editParentId.isEmpty ? null : int.tryParse(_editParentId);

    final result = await updateCategoryUseCase(
      id: state.category.id,
      name: _editName,
      platform: _editPlatform,
      platformCategoryId: _editPlatformCategoryId,
      parentId: parentId,
    );

    result.fold(
      (failure) => emit(CategoryDetailError(message: failure.message)),
      (category) {
        _editName = category.name;
        _editPlatform = category.platform;
        _editPlatformCategoryId = category.platformCategoryId;
        _editParentId = category.parentId?.toString() ?? '';
        emit(CategoryDetailLoaded(
          category: category,
          editName: _editName,
          editPlatform: _editPlatform,
          editPlatformCategoryId: _editPlatformCategoryId,
          editParentId: _editParentId,
        ));
        emit(CategoryDetailSuccess());
      },
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
      (_) {
        // 삭제 성공 → CategoryEventBloc으로 브로드캐스트
        categoryEventBloc.add(CategoryDeleted(event.categoryId));
        emit(CategoryDetailDeleteSuccess());
      },
    );
  }
}
