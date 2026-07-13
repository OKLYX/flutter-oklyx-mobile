import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/carrier.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/usecases/get_carriers_usecase.dart';
import 'carrier_list_event.dart';
import 'carrier_list_state.dart';

/// 택배사 마스터 목록 BLoC. 조회 + 이름 검색(내부 필터).
///
/// CarrierRateListBloc 을 미러한다. `_allCarriers` 에 원본 목록을 보관하고
/// SearchCarriers 는 로컬 필터링만 수행한다.
class CarrierListBloc extends Bloc<CarrierListEvent, CarrierListState> {
  final GetCarriersUseCase getCarriersUseCase;
  List<Carrier> _allCarriers = [];

  CarrierListBloc({required this.getCarriersUseCase})
      : super(CarrierListInitial()) {
    on<FetchCarriers>(_onFetchCarriers);
    on<SearchCarriers>(_onSearchCarriers);
  }

  Future<void> _onFetchCarriers(
    FetchCarriers event,
    Emitter<CarrierListState> emit,
  ) async {
    emit(CarrierListLoading());
    final result = await getCarriersUseCase();
    result.fold(
      (failure) => emit(CarrierListError(message: failure.message)),
      (carriers) {
        _allCarriers = carriers;
        if (carriers.isEmpty) {
          emit(CarrierListEmpty());
        } else {
          emit(CarrierListLoaded(carriers: carriers));
        }
      },
    );
  }

  Future<void> _onSearchCarriers(
    SearchCarriers event,
    Emitter<CarrierListState> emit,
  ) async {
    final query = event.query.toLowerCase();
    final filtered = _allCarriers
        .where((carrier) => carrier.name.toLowerCase().contains(query))
        .toList();

    if (query.isEmpty) {
      emit(CarrierListLoaded(carriers: _allCarriers));
    } else if (filtered.isEmpty) {
      emit(CarrierListEmpty());
    } else {
      emit(CarrierListLoaded(carriers: filtered));
    }
  }
}
