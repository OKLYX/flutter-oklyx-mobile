import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../data/models/carrier_option.dart';
import '../../data/models/manual_shipment_result.dart';
import '../../data/models/shipment_confirm_result.dart';
import '../../data/models/shipping_label_preview_row.dart';

abstract class ShippingLabelRepository {
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

  /// 단건 발송처리용 택배사 드롭다운 항목 (그 플랫폼에 코드가 등록된 활성 택배사).
  Future<Either<Failure, List<CarrierOption>>> getCarrierOptions({
    required String platform,
  });

  /// 한 박스 단건 발송처리(또는 송장수정) — 모드 판정은 서버가 한다(PLAN 2609_11 D3).
  Future<Either<Failure, ManualShipmentResult>> confirmManualShipment({
    required int orderItemId,
    required String deliveryCompanyCode,
    required String invoiceNumber,
  });
}
