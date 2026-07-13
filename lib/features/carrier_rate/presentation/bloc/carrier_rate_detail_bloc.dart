import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/carrier.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/usecases/get_carriers_usecase.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/usecases/get_carrier_rate_usecase.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/usecases/update_carrier_rate_usecase.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/usecases/delete_carrier_rate_usecase.dart';
import 'carrier_rate_create_state.dart';
import 'carrier_rate_detail_event.dart';
import 'carrier_rate_detail_state.dart';

class CarrierRateDetailBloc
    extends Bloc<CarrierRateDetailEvent, CarrierRateDetailState> {
  final GetCarrierRateUseCase getCarrierRateUseCase;
  final UpdateCarrierRateUseCase updateCarrierRateUseCase;
  final DeleteCarrierRateUseCase deleteCarrierRateUseCase;
  final GetCarriersUseCase getCarriersUseCase;

  // Carriers cached on the bloc so fetch (carrierId) and LoadCarriersDetail
  // (carriers list) can complete in any order and still converge into Loaded.
  List<Carrier> _carriers = const [];
  bool _carriersLoading = false;

  CarrierRateDetailBloc({
    required this.getCarrierRateUseCase,
    required this.updateCarrierRateUseCase,
    required this.deleteCarrierRateUseCase,
    required this.getCarriersUseCase,
  }) : super(CarrierRateDetailLoading()) {
    on<FetchCarrierRateDetail>(_onFetch);
    on<LoadCarriersDetail>(_onLoadCarriers);
    on<CarrierIdDetailChanged>(_onCarrierIdChanged);
    on<TypeDetailChanged>(_onTypeChanged);
    on<CostDetailChanged>(_onCostChanged);
    on<EffectiveDateDetailChanged>(_onDateChanged);
    on<IsDefaultDetailChanged>(_onIsDefaultChanged);
    on<UpdateCarrierRateSubmitted>(_onSubmitted);
    on<ConfirmDeleteCarrierRate>(_onConfirmDelete);
  }

  Future<void> _onFetch(
      FetchCarrierRateDetail event, Emitter emit) async {
    emit(CarrierRateDetailLoading());

    final result = await getCarrierRateUseCase(event.id);
    result.fold(
      (failure) => emit(CarrierRateDetailError(failure.message)),
      (carrierRate) => emit(CarrierRateDetailLoaded(
        carrierId: carrierRate.carrierId,
        carriers: _carriers,
        carriersLoading: _carriersLoading,
        type: TypeForm.dirty(value: carrierRate.type),
        cost: CostForm.dirty(value: carrierRate.cost),
        effectiveDate: EffectiveDateForm.dirty(value: carrierRate.effectiveDate),
        isDefault: carrierRate.isDefault,
      )),
    );
  }

  Future<void> _onLoadCarriers(LoadCarriersDetail event, Emitter emit) async {
    _carriersLoading = true;
    if (state is CarrierRateDetailLoaded) {
      emit((state as CarrierRateDetailLoaded).copyWith(carriersLoading: true));
    }

    final result = await getCarriersUseCase();
    // On failure, leave carriers empty → dialog shows "load failed" + save disabled.
    _carriers = result.fold((_) => const [], (carriers) => carriers);
    _carriersLoading = false;

    if (state is CarrierRateDetailLoaded) {
      emit((state as CarrierRateDetailLoaded)
          .copyWith(carriers: _carriers, carriersLoading: false));
    }
  }

  void _onCarrierIdChanged(CarrierIdDetailChanged event, Emitter emit) {
    if (state is CarrierRateDetailLoaded) {
      emit((state as CarrierRateDetailLoaded).copyWith(
        carrierId: event.carrierId,
      ));
    }
  }

  void _onTypeChanged(TypeDetailChanged event, Emitter emit) {
    if (state is CarrierRateDetailLoaded) {
      emit((state as CarrierRateDetailLoaded).copyWith(
        type: TypeForm.dirty(value: event.type),
      ));
    }
  }

  void _onCostChanged(CostDetailChanged event, Emitter emit) {
    if (state is CarrierRateDetailLoaded) {
      try {
        final cost = double.parse(event.cost);
        emit((state as CarrierRateDetailLoaded).copyWith(
          cost: CostForm.dirty(value: cost),
        ));
      } catch (e) {
        // Invalid format
      }
    }
  }

  void _onDateChanged(EffectiveDateDetailChanged event, Emitter emit) {
    if (state is CarrierRateDetailLoaded) {
      emit((state as CarrierRateDetailLoaded).copyWith(
        effectiveDate: EffectiveDateForm.dirty(value: event.date),
      ));
    }
  }

  void _onIsDefaultChanged(IsDefaultDetailChanged event, Emitter emit) {
    if (state is CarrierRateDetailLoaded) {
      emit((state as CarrierRateDetailLoaded).copyWith(
        isDefault: event.isDefault,
      ));
    }
  }

  Future<void> _onSubmitted(UpdateCarrierRateSubmitted event, Emitter emit) async {
    if (state is! CarrierRateDetailLoaded) return;

    final curState = state as CarrierRateDetailLoaded;
    if (!curState.isValid) return;

    emit(curState.copyWith(isSubmitting: true, error: null));

    final result = await updateCarrierRateUseCase(UpdateCarrierRateParams(
      id: event.id,
      carrierId: curState.carrierId!,
      type: curState.type.value,
      cost: curState.cost.value,
      effectiveDate: curState.effectiveDate.value,
      isDefault: curState.isDefault,
    ));

    result.fold(
      (failure) =>
          emit(curState.copyWith(isSubmitting: false, error: failure.message)),
      (_) => emit(CarrierRateDetailSuccess()),
    );
  }

  Future<void> _onConfirmDelete(
    ConfirmDeleteCarrierRate event,
    Emitter emit,
  ) async {
    if (state is! CarrierRateDetailLoaded) return;

    emit(CarrierRateDetailDeleting());

    final result = await deleteCarrierRateUseCase(event.id);

    result.fold(
      (failure) => emit(CarrierRateDetailError(failure.message)),
      (_) => emit(CarrierRateDetailDeleteSuccess()),
    );
  }
}
