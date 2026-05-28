import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../category/domain/entities/category.dart';
import '../../../category/domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/delete_commission_rate_usecase.dart';
import '../../domain/usecases/get_commission_rate_usecase.dart';
import '../../domain/usecases/update_commission_rate_usecase.dart';
import 'commission_rate_detail_event.dart';
import 'commission_rate_detail_state.dart';

class CommissionRateDetailBloc extends Bloc<CommissionRateDetailEvent, CommissionRateDetailState> {
  final GetCommissionRateUseCase _getCommissionRateUseCase;
  final UpdateCommissionRateUseCase _updateCommissionRateUseCase;
  final DeleteCommissionRateUseCase _deleteCommissionRateUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;

  static const List<String> platforms = ['COUPANG', 'GMARKET', 'AUCTION', 'SMARTSTORE'];

  CommissionRateDetailBloc(
    this._getCommissionRateUseCase,
    this._updateCommissionRateUseCase,
    this._deleteCommissionRateUseCase,
    this._getCategoriesUseCase,
  ) : super(CommissionRateDetailInitial()) {
    on<FetchCommissionRateDetail>(_onFetchCommissionRateDetail);
    on<StartEditingCommissionRate>(_onStartEditingCommissionRate);
    on<PlatformChanged>(_onPlatformChanged);
    on<CategoryChanged>(_onCategoryChanged);
    on<RateChanged>(_onRateChanged);
    on<UpdateCommissionRateSubmitted>(_onUpdateCommissionRateSubmitted);
    on<CancelEditing>(_onCancelEditing);
    on<ConfirmDeleteCommissionRate>(_onConfirmDeleteCommissionRate);
  }

  Future<void> _onFetchCommissionRateDetail(
    FetchCommissionRateDetail event,
    Emitter<CommissionRateDetailState> emit,
  ) async {
    emit(CommissionRateDetailLoading());
    final result = await _getCommissionRateUseCase(event.id);
    result.fold(
      (failure) => emit(CommissionRateDetailError(failure.message)),
      (commissionRate) => emit(CommissionRateDetailLoaded(commissionRate)),
    );
  }

  Future<void> _onStartEditingCommissionRate(
    StartEditingCommissionRate event,
    Emitter<CommissionRateDetailState> emit,
  ) async {
    if (state is CommissionRateDetailLoaded) {
      final loadedState = state as CommissionRateDetailLoaded;
      final categoriesResult = await _getCategoriesUseCase();

      final categories = categoriesResult.fold(
        (failure) => <Category>[],
        (cats) => cats,
      );

      final editingData = {
        'platform': loadedState.commissionRate.platform,
        'categoryId': loadedState.commissionRate.categoryId,
        'rate': loadedState.commissionRate.rate,
      };

      emit(CommissionRateDetailEditing(
        originalCommissionRate: loadedState.commissionRate,
        editingData: editingData,
        availableCategories: categories,
      ));
    }
  }

  Future<void> _onPlatformChanged(
    PlatformChanged event,
    Emitter<CommissionRateDetailState> emit,
  ) async {
    if (state is CommissionRateDetailEditing) {
      final editingState = state as CommissionRateDetailEditing;
      final newData = {...editingState.editingData, 'platform': event.platform};
      final errors = _validateData(newData);

      emit(editingState.copyWith(
        editingData: newData,
        validationErrors: errors,
      ));
    }
  }

  Future<void> _onCategoryChanged(
    CategoryChanged event,
    Emitter<CommissionRateDetailState> emit,
  ) async {
    if (state is CommissionRateDetailEditing) {
      final editingState = state as CommissionRateDetailEditing;
      final newData = {...editingState.editingData, 'categoryId': event.categoryId};
      final errors = _validateData(newData);

      emit(editingState.copyWith(
        editingData: newData,
        validationErrors: errors,
      ));
    }
  }

  Future<void> _onRateChanged(
    RateChanged event,
    Emitter<CommissionRateDetailState> emit,
  ) async {
    if (state is CommissionRateDetailEditing) {
      final editingState = state as CommissionRateDetailEditing;
      double? rateValue;
      try {
        rateValue = double.parse(event.rate);
      } catch (e) {
        rateValue = null;
      }

      final newData = {...editingState.editingData, 'rate': rateValue};
      final errors = _validateData(newData);

      emit(editingState.copyWith(
        editingData: newData,
        validationErrors: errors,
      ));
    }
  }

  Future<void> _onUpdateCommissionRateSubmitted(
    UpdateCommissionRateSubmitted event,
    Emitter<CommissionRateDetailState> emit,
  ) async {
    if (state is CommissionRateDetailEditing) {
      final editingState = state as CommissionRateDetailEditing;
      final errors = _validateData(editingState.editingData);

      if (errors.isNotEmpty) {
        emit(editingState.copyWith(validationErrors: errors));
        return;
      }

      emit(CommissionRateDetailSubmitting(editingState.originalCommissionRate));

      final result = await _updateCommissionRateUseCase(
        id: editingState.originalCommissionRate.id,
        platform: editingState.editingData['platform'],
        categoryId: editingState.editingData['categoryId'],
        rate: editingState.editingData['rate'] as double,
      );

      result.fold(
        (failure) => emit(CommissionRateDetailError(failure.message)),
        (updatedRate) => emit(CommissionRateDetailUpdateSuccess(updatedRate)),
      );
    }
  }

  Future<void> _onCancelEditing(
    CancelEditing event,
    Emitter<CommissionRateDetailState> emit,
  ) async {
    if (state is CommissionRateDetailEditing) {
      final editingState = state as CommissionRateDetailEditing;
      emit(CommissionRateDetailLoaded(editingState.originalCommissionRate));
    }
  }

  Future<void> _onConfirmDeleteCommissionRate(
    ConfirmDeleteCommissionRate event,
    Emitter<CommissionRateDetailState> emit,
  ) async {
    final result = await _deleteCommissionRateUseCase(event.id);
    result.fold(
      (failure) => emit(CommissionRateDetailError(failure.message)),
      (_) => emit(CommissionRateDetailDeleteSuccess()),
    );
  }

  Map<String, String?> _validateData(Map<String, dynamic> data) {
    final errors = <String, String?>{};

    final platform = data['platform'];
    if (platform == null || platform.toString().isEmpty) {
      errors['platform'] = '플랫폼을 선택하세요';
    }

    final rate = data['rate'];
    if (rate == null) {
      errors['rate'] = '유효한 수수료율을 입력하세요';
    } else if (rate < 0 || rate > 1) {
      errors['rate'] = '수수료율은 0~1 범위여야 합니다';
    }

    return errors;
  }
}
