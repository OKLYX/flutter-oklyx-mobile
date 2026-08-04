import 'package:equatable/equatable.dart';

abstract class ShippingLabelPreviewEvent extends Equatable {
  const ShippingLabelPreviewEvent();

  @override
  List<Object?> get props => [];
}

/// preview 로드 / 판매자 필터 변경(새 sellerId 재조회).
class LoadPreview extends ShippingLabelPreviewEvent {
  final int? sellerId;

  const LoadPreview([this.sellerId]);

  @override
  List<Object?> get props => [sellerId];
}

/// 특정 라인의 택배수량 편집 (최소 1은 BLoC 에서 강제).
class UpdateParcelQuantity extends ShippingLabelPreviewEvent {
  final String rowKey;
  final int parcelQuantity;

  const UpdateParcelQuantity(this.rowKey, this.parcelQuantity);

  @override
  List<Object?> get props => [rowKey, parcelQuantity];
}

/// 편집된 rows 로 xlsx export 요청.
class ExportRequested extends ShippingLabelPreviewEvent {
  const ExportRequested();
}
