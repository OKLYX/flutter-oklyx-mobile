import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import '../../domain/usecases/shipping_label_usecase.dart';
import 'shipping_label_preview_event.dart';
import 'shipping_label_preview_state.dart';

/// Shipping Label V2 미리보기/편집 BLoC.
///
/// preview(full rows) 로드 → 라인별 택배수량 편집 → 편집 rows POST(export).
/// 판매자 필터 드롭다운은 기존 seller 기능의 [GetSellersUseCase] 를 재사용한다.
class ShippingLabelPreviewBloc
    extends Bloc<ShippingLabelPreviewEvent, ShippingLabelPreviewState> {
  final ShippingLabelUseCase useCase;
  final GetSellersUseCase getSellersUseCase;

  ShippingLabelPreviewBloc({
    required this.useCase,
    required this.getSellersUseCase,
  }) : super(const PreviewInitial()) {
    on<LoadPreview>(_onLoad);
    on<UpdateParcelQuantity>(_onUpdateParcelQuantity);
    on<ExportRequested>(_onExport);
  }

  /// 현재 상태에 보관된 판매자 목록(있으면 재사용해 필터 변경 시 재조회 회피).
  List<Seller> _sellersOf(ShippingLabelPreviewState s) {
    if (s is PreviewLoaded) return s.sellers;
    if (s is PreviewExporting) return s.sellers;
    if (s is PreviewExportSuccess) return s.sellers;
    return const [];
  }

  Future<void> _onLoad(
    LoadPreview event,
    Emitter<ShippingLabelPreviewState> emit,
  ) async {
    var sellers = _sellersOf(state);
    emit(const PreviewLoading());

    // 판매자 목록은 최초 1회만 로드(필터 변경 재조회 시 재사용). 실패는 비치명적 → '전체' 폴백.
    if (sellers.isEmpty) {
      final sellersResult = await getSellersUseCase();
      sellers = sellersResult.fold((_) => <Seller>[], (list) => list);
    }

    final result = await useCase.previewRows(sellerId: event.sellerId);
    result.fold(
      (failure) => emit(PreviewError(_errorMessage(failure))),
      (rows) => emit(PreviewLoaded(
        sellers: sellers,
        rows: rows,
        sellerId: event.sellerId,
      )),
    );
  }

  void _onUpdateParcelQuantity(
    UpdateParcelQuantity event,
    Emitter<ShippingLabelPreviewState> emit,
  ) {
    final current = state;
    if (current is! PreviewLoaded) return;

    // 하한 최소 1 강제 (0/음수 → 1).
    final parcel = event.parcelQuantity < 1 ? 1 : event.parcelQuantity;
    final rows = current.rows
        .map((r) => r.rowKey == event.rowKey
            ? r.copyWith(parcelQuantity: parcel)
            : r)
        .toList();
    emit(PreviewLoaded(
      sellers: current.sellers,
      rows: rows,
      sellerId: current.sellerId,
    ));
  }

  Future<void> _onExport(
    ExportRequested event,
    Emitter<ShippingLabelPreviewState> emit,
  ) async {
    final current = state;
    if (current is! PreviewLoaded) return;
    if (current.rows.isEmpty) return;

    emit(PreviewExporting(
      sellers: current.sellers,
      rows: current.rows,
      sellerId: current.sellerId,
    ));

    final result = await useCase.exportSpreadsheet(current.rows);
    result.fold(
      (failure) => emit(PreviewError(_errorMessage(failure))),
      (bytes) {
        // 성공 bytes 를 transient 로 전달(UI 가 저장/공유) → 곧바로 Loaded 로 복귀(계속 편집 가능).
        emit(PreviewExportSuccess(
          sellers: current.sellers,
          rows: current.rows,
          sellerId: current.sellerId,
          bytes: bytes,
        ));
        emit(PreviewLoaded(
          sellers: current.sellers,
          rows: current.rows,
          sellerId: current.sellerId,
        ));
      },
    );
  }

  // 403(권한) 외에는 고정 메시지. 다운로드/발송처리와 동일하게 에러 본문은 파싱하지 않는다.
  String _errorMessage(Failure failure) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    if (code == 403) return '권한이 없습니다. 관리자 계정으로 로그인해주세요.';
    return '주문목록을 불러오지 못했습니다. 다시 시도해주세요.';
  }
}
