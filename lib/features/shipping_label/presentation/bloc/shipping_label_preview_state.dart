import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../data/models/shipping_label_preview_row.dart';

abstract class ShippingLabelPreviewState extends Equatable {
  const ShippingLabelPreviewState();

  @override
  List<Object?> get props => [];
}

class PreviewInitial extends ShippingLabelPreviewState {
  const PreviewInitial();
}

class PreviewLoading extends ShippingLabelPreviewState {
  const PreviewLoading();
}

/// 편집 대기 상태 — full rows(D2) + 현재 필터(sellerId) 보관.
/// [sellers] 는 판매자 필터 드롭다운 소스(기존 seller usecase 재사용).
class PreviewLoaded extends ShippingLabelPreviewState {
  final List<Seller> sellers;
  final List<ShippingLabelPreviewRow> rows;
  final int? sellerId;

  const PreviewLoaded({
    required this.sellers,
    required this.rows,
    required this.sellerId,
  });

  @override
  List<Object?> get props => [sellers, rows, sellerId];
}

/// export 진행 중 (rows/필터 유지).
class PreviewExporting extends ShippingLabelPreviewState {
  final List<Seller> sellers;
  final List<ShippingLabelPreviewRow> rows;
  final int? sellerId;

  const PreviewExporting({
    required this.sellers,
    required this.rows,
    required this.sellerId,
  });

  @override
  List<Object?> get props => [sellers, rows, sellerId];
}

/// export 성공 — 저장/공유용 [bytes] 를 담은 transient 상태.
/// UI 리스너가 파일 저장 후 BLoC 은 곧바로 [PreviewLoaded] 로 되돌린다(계속 편집 가능).
class PreviewExportSuccess extends ShippingLabelPreviewState {
  final List<Seller> sellers;
  final List<ShippingLabelPreviewRow> rows;
  final int? sellerId;
  final Uint8List bytes;

  const PreviewExportSuccess({
    required this.sellers,
    required this.rows,
    required this.sellerId,
    required this.bytes,
  });

  @override
  List<Object?> get props => [sellers, rows, sellerId, bytes];
}

class PreviewError extends ShippingLabelPreviewState {
  final String message;

  const PreviewError(this.message);

  @override
  List<Object?> get props => [message];
}
