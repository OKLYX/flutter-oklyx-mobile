import 'package:equatable/equatable.dart';

import 'shipping_label_preview_row.dart';

/// 「내부 상품준비중」 접수시트 미리보기 (GET /api/admin/shipping-labels/v2/preview/internal, FEATURE_2609_75 / D26).
class InternalLabelPreview extends Equatable {
  /// 편집용 행 — 기존 미리보기와 같은 모양(엑셀은 기존 export 재사용).
  final List<ShippingLabelPreviewRow> rows;

  /// 내부 상품준비중인데 쿠팡 결제완료 목록에 없던 주문번호 — 화면은 건수만 보인다.
  final List<String> notAcceptedOrderIds;

  const InternalLabelPreview({
    required this.rows,
    required this.notAcceptedOrderIds,
  });

  factory InternalLabelPreview.fromJson(Map<String, dynamic> json) =>
      InternalLabelPreview(
        rows: (json['rows'] as List?)
                ?.map((e) =>
                    ShippingLabelPreviewRow.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        notAcceptedOrderIds: (json['notAcceptedOrderIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [rows, notAcceptedOrderIds];
}
