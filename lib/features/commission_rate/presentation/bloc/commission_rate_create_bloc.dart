import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../category/domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/create_commission_rate_usecase.dart';
import 'commission_rate_create_event.dart';
import 'commission_rate_create_state.dart';

class CommissionRateCreateBloc extends Bloc<CommissionRateCreateEvent, CommissionRateCreateState> {
  final CreateCommissionRateUseCase _createCommissionRateUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;

  static const List<String> platforms = ['COUPANG', 'GMARKET', 'AUCTION', 'SMARTSTORE'];

  CommissionRateCreateBloc(
    this._createCommissionRateUseCase,
    this._getCategoriesUseCase,
  ) : super(CommissionRateCreateInitial()) {
    on<PlatformSelected>(_onPlatformSelected);
    on<CategorySelected>(_onCategorySelected);
    on<RateChanged>(_onRateChanged);
    on<CreateCommissionRateSubmitted>(_onCreateCommissionRateSubmitted);
    on<ResetCreateForm>(_onResetCreateForm);
  }

  bool _isValidForm(
    String platform,
    int? categoryId,
    String rate,
  ) {
    if (platform.isEmpty) return false;

    final parsedRate = double.tryParse(rate);
    if (parsedRate == null || parsedRate < 0.0 || parsedRate > 100.0) return false;

    return true;
  }

  Future<void> _onPlatformSelected(
    PlatformSelected event,
    Emitter<CommissionRateCreateState> emit,
  ) async {
    final currentState = state as CommissionRateCreateInitial;
    emit(currentState.copyWith(
      platform: event.platform,
      selectedCategoryId: null,
      isLoadingCategories: true,
    ));

    final result = await _getCategoriesUseCase();
    result.fold(
      (failure) {
        emit(currentState.copyWith(
          platform: event.platform,
          availableCategories: [],
          isLoadingCategories: false,
        ));
      },
      (categories) {
        final filteredCategories = categories
            .where((cat) => cat.platform == event.platform)
            .toList();
        final isValid = _isValidForm(
          event.platform,
          null,
          currentState.rate,
        );
        emit(currentState.copyWith(
          platform: event.platform,
          availableCategories: filteredCategories,
          isLoadingCategories: false,
          isValid: isValid,
        ));
      },
    );
  }

  void _onCategorySelected(
    CategorySelected event,
    Emitter<CommissionRateCreateState> emit,
  ) {
    final currentState = state as CommissionRateCreateInitial;
    emit(currentState.copyWith(
      selectedCategoryId: event.categoryId,
      isValid: _isValidForm(
        currentState.platform,
        event.categoryId,
        currentState.rate,
      ),
    ));
  }

  void _onRateChanged(
    RateChanged event,
    Emitter<CommissionRateCreateState> emit,
  ) {
    final currentState = state as CommissionRateCreateInitial;
    final isValid = _isValidForm(
      currentState.platform,
      currentState.selectedCategoryId,
      event.rate,
    );
    emit(currentState.copyWith(
      rate: event.rate,
      isValid: isValid,
    ));
  }

  Future<void> _onCreateCommissionRateSubmitted(
    CreateCommissionRateSubmitted event,
    Emitter<CommissionRateCreateState> emit,
  ) async {
    final currentState = state as CommissionRateCreateInitial;
    emit(currentState.copyWith(isSubmitting: true));
    emit(CommissionRateCreateLoading());

    final result = await _createCommissionRateUseCase(
      platform: event.platform,
      categoryId: event.categoryId,
      rate: event.rate,
    );
    result.fold(
      (failure) => emit(CommissionRateCreateError(failure.message)),
      (commissionRate) => emit(CommissionRateCreateSuccess(commissionRate)),
    );
  }

  Future<void> _onResetCreateForm(
    ResetCreateForm event,
    Emitter<CommissionRateCreateState> emit,
  ) async {
    emit(CommissionRateCreateInitial());
  }
}
