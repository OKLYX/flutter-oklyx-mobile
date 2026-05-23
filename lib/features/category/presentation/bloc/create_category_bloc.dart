import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/usecases/create_category_usecase.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/create_category_event.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/create_category_state.dart';

class CreateCategoryBloc extends Bloc<CreateCategoryEvent, CreateCategoryState> {
  final CreateCategoryUseCase createCategoryUseCase;

  String _name = '';
  String _platform = '';
  String _platformCategoryId = '';
  int? _parentId;

  CreateCategoryBloc({required this.createCategoryUseCase})
      : super(CreateCategoryInitial()) {
    on<CreateCategoryNameChanged>(_onNameChanged);
    on<CreateCategoryPlatformChanged>(_onPlatformChanged);
    on<CreateCategoryIdChanged>(_onIdChanged);
    on<CreateCategoryParentIdChanged>(_onParentIdChanged);
    on<CreateCategorySubmitted>(_onSubmitted);
  }

  void _onNameChanged(
    CreateCategoryNameChanged event,
    Emitter<CreateCategoryState> emit,
  ) {
    _name = event.name;
    _validateAndEmit(emit);
  }

  void _onPlatformChanged(
    CreateCategoryPlatformChanged event,
    Emitter<CreateCategoryState> emit,
  ) {
    _platform = event.platform;
    _validateAndEmit(emit);
  }

  void _onIdChanged(
    CreateCategoryIdChanged event,
    Emitter<CreateCategoryState> emit,
  ) {
    _platformCategoryId = event.platformCategoryId;
    _validateAndEmit(emit);
  }

  void _onParentIdChanged(
    CreateCategoryParentIdChanged event,
    Emitter<CreateCategoryState> emit,
  ) {
    _parentId = event.parentId;
    _validateAndEmit(emit);
  }

  void _validateAndEmit(Emitter<CreateCategoryState> emit) {
    final isValid = _name.isNotEmpty &&
        _name.length <= 100 &&
        _platform.isNotEmpty &&
        _platformCategoryId.isNotEmpty &&
        _platformCategoryId.length <= 50;

    emit(CreateCategoryEditing(
      name: _name,
      platform: _platform,
      platformCategoryId: _platformCategoryId,
      parentId: _parentId,
      isValid: isValid,
    ));
  }

  Future<void> _onSubmitted(
    CreateCategorySubmitted event,
    Emitter<CreateCategoryState> emit,
  ) async {
    emit(CreateCategoryLoading());

    final result = await createCategoryUseCase(
      name: _name,
      platform: _platform,
      platformCategoryId: _platformCategoryId,
      parentId: _parentId,
    );

    result.fold(
      (failure) => emit(CreateCategoryError(message: failure.message ?? 'Unknown error')),
      (_) => emit(CreateCategorySuccess()),
    );
  }
}
