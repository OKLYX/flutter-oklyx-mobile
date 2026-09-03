import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../data/models/shipping_label_preview_row.dart';

abstract class OrderSheetState extends Equatable {
  const OrderSheetState();

  @override
  List<Object?> get props => [];
}

/// 섹션 접힘 — 버튼만 노출(진입 시 자동 조회 없음).
class OrderSheetInitial extends OrderSheetState {
  const OrderSheetInitial();
}

class OrderSheetLoading extends OrderSheetState {
  const OrderSheetLoading();
}

/// 편집 대기 상태 — 단건 주문의 full rows 보관.
class OrderSheetLoaded extends OrderSheetState {
  final List<ShippingLabelPreviewRow> rows;

  const OrderSheetLoaded(this.rows);

  @override
  List<Object?> get props => [rows];
}

/// export 진행 중 (rows 유지).
class OrderSheetExporting extends OrderSheetState {
  final List<ShippingLabelPreviewRow> rows;

  const OrderSheetExporting(this.rows);

  @override
  List<Object?> get props => [rows];
}

/// export 성공 — 저장용 [bytes] 를 담은 transient 상태.
/// UI 리스너가 파일 저장 후 BLoC 은 곧바로 [OrderSheetLoaded] 로 되돌린다(계속 편집 가능).
class OrderSheetExportSuccess extends OrderSheetState {
  final List<ShippingLabelPreviewRow> rows;
  final Uint8List bytes;

  const OrderSheetExportSuccess({required this.rows, required this.bytes});

  @override
  List<Object?> get props => [rows, bytes];
}

/// export 실패 — transient. 편집한 rows 를 잃지 않도록 곧바로 [OrderSheetLoaded] 로 복귀한다.
class OrderSheetExportFailure extends OrderSheetState {
  final List<ShippingLabelPreviewRow> rows;
  final String message;

  const OrderSheetExportFailure({required this.rows, required this.message});

  @override
  List<Object?> get props => [rows, message];
}

/// 조회 실패 전용 — 섹션 전체를 에러+재시도로 대체한다(export 실패와 구분).
class OrderSheetError extends OrderSheetState {
  final String message;

  const OrderSheetError(this.message);

  @override
  List<Object?> get props => [message];
}
