import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/usecases/create_carrier_usecase.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/usecases/update_carrier_usecase.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/usecases/delete_carrier_usecase.dart';
import 'carrier_form_event.dart';
import 'carrier_form_state.dart';

/// 택배사 생성/수정/활성토글/삭제 액션 BLoC.
///
/// 다이얼로그/스와이프 액션에서 사용된다. 리스트 데이터는 보유하지 않으며,
/// 성공 시 CarrierListPage 의 BlocListener 가 CarrierListBloc 재조회를 발행한다.
class CarrierFormBloc extends Bloc<CarrierFormEvent, CarrierFormState> {
  final CreateCarrierUseCase createCarrierUseCase;
  final UpdateCarrierUseCase updateCarrierUseCase;
  final DeleteCarrierUseCase deleteCarrierUseCase;

  CarrierFormBloc({
    required this.createCarrierUseCase,
    required this.updateCarrierUseCase,
    required this.deleteCarrierUseCase,
  }) : super(CarrierFormInitial()) {
    on<CreateCarrier>(_onCreate);
    on<UpdateCarrier>(_onUpdate);
    on<ToggleActive>(_onToggle);
    on<DeleteCarrier>(_onDelete);
  }

  Future<void> _onCreate(
    CreateCarrier event,
    Emitter<CarrierFormState> emit,
  ) async {
    emit(CarrierFormLoading());
    final result = await createCarrierUseCase(event.name, event.isActive);
    result.fold(
      (failure) => emit(CarrierFormError(message: failure.message)),
      (_) => emit(CarrierFormSuccess(
        action: CarrierFormAction.create,
        message: '택배사가 추가되었습니다.',
      )),
    );
  }

  Future<void> _onUpdate(
    UpdateCarrier event,
    Emitter<CarrierFormState> emit,
  ) async {
    emit(CarrierFormLoading());
    final result =
        await updateCarrierUseCase(event.id, event.name, event.isActive);
    result.fold(
      (failure) => emit(CarrierFormError(message: failure.message)),
      (_) => emit(CarrierFormSuccess(
        action: CarrierFormAction.update,
        message: '택배사가 수정되었습니다.',
      )),
    );
  }

  Future<void> _onToggle(
    ToggleActive event,
    Emitter<CarrierFormState> emit,
  ) async {
    emit(CarrierFormLoading());
    // PATCH 는 full-replace 이므로 기존 name 을 유지하고 isActive 만 반전한다.
    final result = await updateCarrierUseCase(
      event.carrier.id,
      event.carrier.name,
      !event.carrier.isActive,
    );
    result.fold(
      (failure) => emit(CarrierFormError(message: failure.message)),
      (_) => emit(CarrierFormSuccess(
        action: CarrierFormAction.toggle,
        message: !event.carrier.isActive ? '활성화되었습니다.' : '비활성화되었습니다.',
      )),
    );
  }

  Future<void> _onDelete(
    DeleteCarrier event,
    Emitter<CarrierFormState> emit,
  ) async {
    emit(CarrierFormLoading());
    final result = await deleteCarrierUseCase(event.id);
    result.fold(
      (failure) {
        final message = (failure is ServerFailure && failure.statusCode == 409)
            ? '요율에서 사용 중인 택배사는 삭제할 수 없습니다'
            : failure.message;
        emit(CarrierFormError(message: message));
      },
      (_) => emit(CarrierFormSuccess(
        action: CarrierFormAction.delete,
        message: '택배사가 삭제되었습니다.',
      )),
    );
  }
}
