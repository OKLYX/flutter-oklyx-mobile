import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/commission_rate.dart';
import '../../domain/usecases/get_commission_rates_usecase.dart';
import 'commission_rate_list_event.dart';
import 'commission_rate_list_state.dart';

class CommissionRateListBloc extends Bloc<CommissionRateListEvent, CommissionRateListState> {
  final GetCommissionRatesUseCase _getCommissionRatesUseCase;
  List<CommissionRate> _allCommissionRates = [];

  CommissionRateListBloc(this._getCommissionRatesUseCase) : super(CommissionRateListInitial()) {
    on<FetchCommissionRates>(_onFetchCommissionRates);
    on<ReloadCommissionRates>(_onReloadCommissionRates);
    on<SearchCommissionRates>(_onSearchCommissionRates);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onFetchCommissionRates(
    FetchCommissionRates event,
    Emitter<CommissionRateListState> emit,
  ) async {
    emit(CommissionRateListLoading());
    final result = await _getCommissionRatesUseCase();
    result.fold(
      (failure) => emit(CommissionRateListError(message: failure.message)),
      (commissionRates) {
        _allCommissionRates = commissionRates;
        if (commissionRates.isEmpty) {
          emit(CommissionRateListEmpty());
        } else {
          emit(CommissionRateListLoaded(commissionRates: commissionRates));
        }
      },
    );
  }

  Future<void> _onReloadCommissionRates(
    ReloadCommissionRates event,
    Emitter<CommissionRateListState> emit,
  ) async {
    emit(CommissionRateListLoading());
    final result = await _getCommissionRatesUseCase();
    result.fold(
      (failure) => emit(CommissionRateListError(message: failure.message)),
      (commissionRates) {
        _allCommissionRates = commissionRates;
        if (commissionRates.isEmpty) {
          emit(CommissionRateListEmpty());
        } else {
          emit(CommissionRateListLoaded(commissionRates: commissionRates));
        }
      },
    );
  }

  Future<void> _onSearchCommissionRates(
    SearchCommissionRates event,
    Emitter<CommissionRateListState> emit,
  ) async {
    if (event.query.isEmpty) {
      return;
    }

    final filtered = _allCommissionRates
        .where((rate) => rate.platform.toLowerCase().contains(event.query.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      emit(CommissionRateListEmpty());
    } else {
      emit(CommissionRateListLoaded(commissionRates: filtered));
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<CommissionRateListState> emit,
  ) async {
    if (_allCommissionRates.isEmpty) {
      emit(CommissionRateListEmpty());
    } else {
      emit(CommissionRateListLoaded(commissionRates: _allCommissionRates));
    }
  }
}
