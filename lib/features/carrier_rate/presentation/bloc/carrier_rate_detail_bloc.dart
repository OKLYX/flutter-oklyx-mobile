import 'package:flutter_bloc/flutter_bloc.dart';
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

  CarrierRateDetailBloc({
    required this.getCarrierRateUseCase,
    required this.updateCarrierRateUseCase,
    required this.deleteCarrierRateUseCase,
  }) : super(CarrierRateDetailLoading()) {
    on<FetchCarrierRateDetail>(_onFetch);
    on<CarrierDetailChanged>(_onCarrierChanged);
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
        carrier: CarrierForm.dirty(value: carrierRate.carrier),
        type: TypeForm.dirty(value: carrierRate.type),
        cost: CostForm.dirty(value: carrierRate.cost),
        effectiveDate: EffectiveDateForm.dirty(value: carrierRate.effectiveDate),
        isDefault: carrierRate.isDefault,
      )),
    );
  }

  void _onCarrierChanged(CarrierDetailChanged event, Emitter emit) {
    if (state is CarrierRateDetailLoaded) {
      emit((state as CarrierRateDetailLoaded).copyWith(
        carrier: CarrierForm.dirty(value: event.carrier),
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
      carrier: curState.carrier.value,
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
