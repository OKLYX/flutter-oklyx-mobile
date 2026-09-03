import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../data/models/shipment_confirm_result.dart';
import '../../data/models/shipping_label_preview_row.dart';
import '../repositories/shipping_label_repository.dart';

/// Shipping Label 발송처리/미리보기/내보내기 UseCase (Repository 에 위임하는 얇은 계층).
class ShippingLabelUseCase {
  final ShippingLabelRepository repository;

  ShippingLabelUseCase({required this.repository});

  Future<Either<Failure, ShipmentConfirmResult>> confirmShipment({
    required Uint8List bytes,
    required String filename,
  }) =>
      repository.confirmShipment(bytes: bytes, filename: filename);

  Future<Either<Failure, List<ShippingLabelPreviewRow>>> previewRows({
    int? sellerId,
  }) =>
      repository.previewRows(sellerId: sellerId);

  Future<Either<Failure, List<ShippingLabelPreviewRow>>> previewRowsByOrder({
    required int orderItemId,
  }) =>
      repository.previewRowsByOrder(orderItemId: orderItemId);

  Future<Either<Failure, Uint8List>> exportSpreadsheet(
    List<ShippingLabelPreviewRow> rows,
  ) =>
      repository.exportSpreadsheet(rows);
}
