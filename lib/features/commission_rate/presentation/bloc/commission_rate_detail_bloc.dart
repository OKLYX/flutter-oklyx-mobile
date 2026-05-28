import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/delete_commission_rate_usecase.dart';
import '../../domain/usecases/get_commission_rate_usecase.dart';
import '../../domain/usecases/update_commission_rate_usecase.dart';
import 'commission_rate_detail_event.dart';
import 'commission_rate_detail_state.dart';

class CommissionRateDetailBloc extends Bloc<CommissionRateDetailEvent, CommissionRateDetailState> {
  final GetCommissionRateUseCase _getCommissionRateUseCase;
  final UpdateCommissionRateUseCase _updateCommissionRateUseCase;
  final DeleteCommissionRateUseCase _deleteCommissionRateUseCase;

  CommissionRateDetailBloc(
    this._getCommissionRateUseCase,
    this._updateCommissionRateUseCase,
    this._deleteCommissionRateUseCase,
  ) : super(CommissionRateDetailInitial()) {
    on<FetchCommissionRateDetail>(_onFetchCommissionRateDetail);
    on<UpdateCommissionRate>(_onUpdateCommissionRate);
    on<DeleteCommissionRate>(_onDeleteCommissionRate);
  }

  Future<void> _onFetchCommissionRateDetail(
    FetchCommissionRateDetail event,
    Emitter<CommissionRateDetailState> emit,
  ) async {
    emit(CommissionRateDetailLoading());
    final result = await _getCommissionRateUseCase(event.id);
    result.fold(
      (failure) => emit(CommissionRateDetailError(failure.message)),
      (commissionRate) => emit(CommissionRateDetailSuccess(commissionRate)),
    );
  }

  Future<void> _onUpdateCommissionRate(
    UpdateCommissionRate event,
    Emitter<CommissionRateDetailState> emit,
  ) async {
    emit(CommissionRateDetailUpdating());
    final result = await _updateCommissionRateUseCase(
      id: event.id,
      platform: event.platform,
      categoryId: event.categoryId,
      rate: event.rate,
    );
    result.fold(
      (failure) => emit(CommissionRateDetailError(failure.message)),
      (commissionRate) => emit(CommissionRateDetailUpdateSuccess(commissionRate)),
    );
  }

  Future<void> _onDeleteCommissionRate(
    DeleteCommissionRate event,
    Emitter<CommissionRateDetailState> emit,
  ) async {
    emit(CommissionRateDetailDeleting());
    final result = await _deleteCommissionRateUseCase(event.id);
    result.fold(
      (failure) => emit(CommissionRateDetailError(failure.message)),
      (_) => emit(CommissionRateDetailDeleteSuccess()),
    );
  }
}
