import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_commission_rates_usecase.dart';
import 'commission_rate_list_event.dart';
import 'commission_rate_list_state.dart';

class CommissionRateListBloc extends Bloc<CommissionRateListEvent, CommissionRateListState> {
  final GetCommissionRatesUseCase _getCommissionRatesUseCase;

  CommissionRateListBloc(this._getCommissionRatesUseCase) : super(CommissionRateListInitial()) {
    on<FetchCommissionRates>(_onFetchCommissionRates);
    on<ReloadCommissionRates>(_onReloadCommissionRates);
  }

  Future<void> _onFetchCommissionRates(
    FetchCommissionRates event,
    Emitter<CommissionRateListState> emit,
  ) async {
    emit(CommissionRateListLoading());
    final result = await _getCommissionRatesUseCase();
    result.fold(
      (failure) => emit(CommissionRateListError(failure.message)),
      (commissionRates) => emit(CommissionRateListSuccess(commissionRates)),
    );
  }

  Future<void> _onReloadCommissionRates(
    ReloadCommissionRates event,
    Emitter<CommissionRateListState> emit,
  ) async {
    emit(CommissionRateListLoading());
    final result = await _getCommissionRatesUseCase();
    result.fold(
      (failure) => emit(CommissionRateListError(failure.message)),
      (commissionRates) => emit(CommissionRateListSuccess(commissionRates)),
    );
  }
}
