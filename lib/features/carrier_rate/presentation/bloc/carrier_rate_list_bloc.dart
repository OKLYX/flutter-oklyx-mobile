import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/entities/carrier_rate.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/usecases/get_carrier_rates_usecase.dart';
import 'carrier_rate_list_event.dart';
import 'carrier_rate_list_state.dart';

class CarrierRateListBloc extends Bloc<CarrierRateListEvent, CarrierRateListState> {
  final GetCarrierRatesUseCase getCarrierRatesUseCase;
  List<CarrierRate> _allCarrierRates = [];

  CarrierRateListBloc({required this.getCarrierRatesUseCase})
      : super(CarrierRateListInitial()) {
    on<FetchCarrierRates>(_onFetchCarrierRates);
    on<SearchCarrierRates>(_onSearchCarrierRates);
  }

  Future<void> _onFetchCarrierRates(
    FetchCarrierRates event,
    Emitter<CarrierRateListState> emit,
  ) async {
    emit(CarrierRateListLoading());
    final result = await getCarrierRatesUseCase();
    result.fold(
      (failure) => emit(CarrierRateListError(message: failure.message)),
      (carrierRates) {
        _allCarrierRates = carrierRates;
        if (carrierRates.isEmpty) {
          emit(CarrierRateListEmpty());
        } else {
          emit(CarrierRateListLoaded(carrierRates: carrierRates));
        }
      },
    );
  }

  Future<void> _onSearchCarrierRates(
    SearchCarrierRates event,
    Emitter<CarrierRateListState> emit,
  ) async {
    final query = event.query.toLowerCase();
    final filtered = _allCarrierRates
        .where((rate) => rate.carrier.toLowerCase().contains(query))
        .toList();

    if (query.isEmpty) {
      emit(CarrierRateListLoaded(carrierRates: _allCarrierRates));
    } else if (filtered.isEmpty) {
      emit(CarrierRateListEmpty());
    } else {
      emit(CarrierRateListLoaded(carrierRates: filtered));
    }
  }
}
