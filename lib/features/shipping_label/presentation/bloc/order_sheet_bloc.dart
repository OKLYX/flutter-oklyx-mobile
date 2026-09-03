import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/usecases/shipping_label_usecase.dart';
import 'order_sheet_event.dart';
import 'order_sheet_state.dart';

/// 주문 상세의 단건 송장 접수시트 BLoC.
///
/// 목록용 ShippingLabelPreviewBloc 과 달리 판매자 필터가 없고, 주문 한 건(상태 무관)의
/// rows 만 다룬다. 페이지 진입 시 자동 조회하지 않고 사용자가 버튼을 탭할 때만 로드한다.
///
/// **권한**: 클라이언트 role 게이트 없음 — 백엔드 403 에 의존(기존 송장시트 화면과 동일).
class OrderSheetBloc extends Bloc<OrderSheetEvent, OrderSheetState> {
  final ShippingLabelUseCase useCase;

  OrderSheetBloc({required this.useCase}) : super(const OrderSheetInitial()) {
    on<LoadOrderSheet>(_onLoad);
    on<UpdateOrderSheetParcelQuantity>(_onUpdateParcelQuantity);
    on<ExportOrderSheetRequested>(_onExport);
  }

  Future<void> _onLoad(
    LoadOrderSheet event,
    Emitter<OrderSheetState> emit,
  ) async {
    emit(const OrderSheetLoading());

    final result =
        await useCase.previewRowsByOrder(orderItemId: event.orderItemId);
    result.fold(
      (failure) => emit(OrderSheetError(
        _errorMessage(failure, '쿠팡 주문 조회에 실패했습니다.'),
      )),
      (rows) => emit(OrderSheetLoaded(rows)),
    );
  }

  void _onUpdateParcelQuantity(
    UpdateOrderSheetParcelQuantity event,
    Emitter<OrderSheetState> emit,
  ) {
    final current = state;
    if (current is! OrderSheetLoaded) return;

    // 하한 최소 1 강제 (0/음수 → 1). rows 는 copyWith 로 immutable 하게 교체한다.
    final rows = current.rows
        .map((r) => r.rowKey == event.rowKey
            ? r.copyWith(
                parcelQuantity:
                    event.parcelQuantity < 1 ? 1 : event.parcelQuantity)
            : r)
        .toList();
    emit(OrderSheetLoaded(rows));
  }

  Future<void> _onExport(
    ExportOrderSheetRequested event,
    Emitter<OrderSheetState> emit,
  ) async {
    final current = state;
    if (current is! OrderSheetLoaded) return;
    if (current.rows.isEmpty) return;

    emit(OrderSheetExporting(current.rows));

    final result = await useCase.exportSpreadsheet(current.rows);
    result.fold(
      (failure) {
        // 조회 실패(Error)와 달리 섹션을 유지한다 — 편집한 택배수량을 잃지 않도록
        // transient 로 알린 뒤 곧바로 Loaded 로 복귀.
        emit(OrderSheetExportFailure(
          rows: current.rows,
          message: _errorMessage(failure, '엑셀 생성에 실패했습니다.'),
        ));
        emit(OrderSheetLoaded(current.rows));
      },
      (bytes) {
        // 성공 bytes 를 transient 로 전달(UI 가 저장) → 곧바로 Loaded 로 복귀.
        emit(OrderSheetExportSuccess(rows: current.rows, bytes: bytes));
        emit(OrderSheetLoaded(current.rows));
      },
    );
  }

  // 에러 본문은 파싱하지 않고 statusCode 로만 분기한다(기존 송장시트 정책과 동일).
  // 400 은 서버가 계정 platform 으로 판정하므로 표시용 order.platform 게이트를 통과한
  // 데이터에서도 올 수 있다.
  String _errorMessage(Failure failure, String fallback) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    if (code == 403) return '권한이 없습니다. 관리자 계정으로 로그인해주세요.';
    if (code == 404) return '주문을 찾을 수 없습니다.';
    if (code == 400) return '쿠팡 주문만 지원합니다.';
    return fallback;
  }
}
