/// CarrierFormBloc 이 수행한 액션 종류.
enum CarrierFormAction { create, update, toggle, delete }

abstract class CarrierFormState {}

class CarrierFormInitial extends CarrierFormState {}

class CarrierFormLoading extends CarrierFormState {}

/// 액션 성공 (transient). SnackBar 표시 + 목록 재조회 트리거.
/// 리스트 데이터는 미보유 — 갱신은 CarrierListBloc 이 재조회한다.
class CarrierFormSuccess extends CarrierFormState {
  final CarrierFormAction action;
  final String message;
  CarrierFormSuccess({required this.action, required this.message});
}

class CarrierFormError extends CarrierFormState {
  final String message;
  CarrierFormError({required this.message});
}
