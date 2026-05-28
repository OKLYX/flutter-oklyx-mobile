import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_commission_rate_usecase.dart';
import 'commission_rate_create_event.dart';
import 'commission_rate_create_state.dart';

class CommissionRateCreateBloc extends Bloc<CommissionRateCreateEvent, CommissionRateCreateState> {
  final CreateCommissionRateUseCase _createCommissionRateUseCase;

  CommissionRateCreateBloc(this._createCommissionRateUseCase) : super(CommissionRateCreateInitial()) {
    on<CreateCommissionRate>(_onCreateCommissionRate);
    on<ResetCreateForm>(_onResetCreateForm);
  }

  Future<void> _onCreateCommissionRate(
    CreateCommissionRate event,
    Emitter<CommissionRateCreateState> emit,
  ) async {
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
