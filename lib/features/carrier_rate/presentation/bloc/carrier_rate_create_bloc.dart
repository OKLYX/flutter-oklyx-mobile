import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/usecases/get_carriers_usecase.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/usecases/create_carrier_rate_usecase.dart';
import 'carrier_rate_create_event.dart';
import 'carrier_rate_create_state.dart';

class CarrierRateCreateBloc
    extends Bloc<CarrierRateCreateEvent, CarrierRateCreateState> {
  final CreateCarrierRateUseCase createCarrierRateUseCase;
  final GetCarriersUseCase getCarriersUseCase;

  CarrierRateCreateBloc({
    required this.createCarrierRateUseCase,
    required this.getCarriersUseCase,
  }) : super(CarrierRateCreateInitial()) {
    on<LoadCarriers>(_onLoadCarriers);
    on<CarrierIdChanged>(_onCarrierIdChanged);
    on<TypeChanged>(_onTypeChanged);
    on<CostChanged>(_onCostChanged);
    on<EffectiveDateChanged>(_onEffectiveDateChanged);
    on<IsDefaultChanged>(_onIsDefaultChanged);
    on<CreateCarrierRateSubmitted>(_onSubmitted);
    on<ResetCreateForm>(_onResetForm);
  }

  Future<void> _onLoadCarriers(LoadCarriers event, Emitter emit) async {
    final current = state as CarrierRateCreateInitial;
    emit(current.copyWith(carriersLoading: true));

    final result = await getCarriersUseCase();
    result.fold(
      // On failure, leave carriers empty → dialog shows "load failed" + save disabled.
      (_) => emit((state as CarrierRateCreateInitial)
          .copyWith(carriers: const [], carriersLoading: false)),
      (carriers) => emit((state as CarrierRateCreateInitial)
          .copyWith(carriers: carriers, carriersLoading: false)),
    );
  }

  void _onCarrierIdChanged(CarrierIdChanged event, Emitter emit) {
    emit((state as CarrierRateCreateInitial).copyWith(
      carrierId: event.carrierId,
    ));
  }

  void _onTypeChanged(TypeChanged event, Emitter emit) {
    emit((state as CarrierRateCreateInitial).copyWith(
      type: TypeForm.dirty(value: event.type),
    ));
  }

  void _onCostChanged(CostChanged event, Emitter emit) {
    try {
      final cost = double.parse(event.cost);
      emit((state as CarrierRateCreateInitial).copyWith(
        cost: CostForm.dirty(value: cost),
      ));
    } catch (e) {
      // Invalid number format - state remains unchanged
    }
  }

  void _onEffectiveDateChanged(EffectiveDateChanged event, Emitter emit) {
    emit((state as CarrierRateCreateInitial).copyWith(
      effectiveDate: EffectiveDateForm.dirty(value: event.date),
    ));
  }

  void _onIsDefaultChanged(IsDefaultChanged event, Emitter emit) {
    emit((state as CarrierRateCreateInitial).copyWith(
      isDefault: event.isDefault,
    ));
  }

  void _onResetForm(ResetCreateForm event, Emitter emit) {
    print('[CreateCarrierRateBloc] Resetting form');
    emit(CarrierRateCreateInitial());
  }

  Future<void> _onSubmitted(
      CreateCarrierRateSubmitted event, Emitter emit) async {
    print('[CreateCarrierRateBloc] _onSubmitted called');
    final state = this.state as CarrierRateCreateInitial;
    if (!state.isValid) {
      print('[CreateCarrierRateBloc] Form is invalid');
      return;
    }

    print('[CreateCarrierRateBloc] Emitting isSubmitting=true');
    emit(state.copyWith(isSubmitting: true, error: null));

    final result = await createCarrierRateUseCase(CreateCarrierRateParams(
      carrierId: state.carrierId!,
      type: state.type.value,
      cost: state.cost.value,
      effectiveDate: state.effectiveDate.value,
      isDefault: state.isDefault,
    ));

    print('[CreateCarrierRateBloc] API Result: $result');

    result.fold(
      (failure) {
        print('[CreateCarrierRateBloc] Failure: ${failure.message}');
        emit(state.copyWith(isSubmitting: false, error: failure.message));
      },
      (_) {
        print('[CreateCarrierRateBloc] Success - emitting CarrierRateCreateSuccess');
        emit(CarrierRateCreateSuccess());
      },
    );
  }
}
