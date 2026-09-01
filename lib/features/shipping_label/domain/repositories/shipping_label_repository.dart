import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../data/models/shipment_confirm_result.dart';
import '../../data/models/shipping_label_preview_row.dart';

abstract class ShippingLabelRepository {
  /// 쿠팡 INSTRUCT(상품준비중) 주문 → 택배사 접수용 xlsx 바이너리.
  Future<Either<Failure, Uint8List>> downloadSpreadsheet({int? sellerId});

  /// 택배사 결과 xlsx 업로드 → 쿠팡 송장업로드 배치 결과.
  Future<Either<Failure, ShipmentConfirmResult>> confirmShipment({
    required Uint8List bytes,
    required String filename,
  });

  /// V2 편집용 미리보기 행 조회 (full rows).
  Future<Either<Failure, List<ShippingLabelPreviewRow>>> previewRows({
    int? sellerId,
  });

  /// V2 단건 주문(상태 무관) 편집용 미리보기 행 조회.
  Future<Either<Failure, List<ShippingLabelPreviewRow>>> previewRowsByOrder({
    required int orderItemId,
  });

  /// V2 편집된 rows → 접수용 xlsx 바이너리.
  Future<Either<Failure, Uint8List>> exportSpreadsheet(
    List<ShippingLabelPreviewRow> rows,
  );
}
