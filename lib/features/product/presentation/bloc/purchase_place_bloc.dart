import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_purchase_places_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/purchase_place_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/purchase_place_state.dart';

/// 물품 화면의 구매처 선택지 (FEATURE_2609_76 / D5).
///
/// 물품 등록·상세 BLoC 과 **따로 둔다** — 그 두 BLoC 의 상태는 화면 전체를 바꾸는 상태라
/// 목록 조회 결과를 끼워 넣으면 폼이 사라진다. 화면마다 새 인스턴스(`registerFactory`).
class PurchasePlaceBloc extends Bloc<PurchasePlaceEvent, PurchasePlaceState> {
  final GetPurchasePlacesUseCase getPurchasePlacesUseCase;

  PurchasePlaceBloc({required this.getPurchasePlacesUseCase})
      : super(const PurchasePlaceInitial()) {
    on<PurchasePlacesRequested>(_onRequested);
  }

  Future<void> _onRequested(
    PurchasePlacesRequested event,
    Emitter<PurchasePlaceState> emit,
  ) async {
    emit(const PurchasePlaceLoading());
    final result = await getPurchasePlacesUseCase();
    result.fold(
      (failure) => emit(const PurchasePlaceError('구매처 목록을 불러오지 못했습니다.')),
      (places) => emit(PurchasePlaceLoaded(places)),
    );
  }
}
