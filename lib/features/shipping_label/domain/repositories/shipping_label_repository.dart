import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';

abstract class ShippingLabelRepository {
  /// 쿠팡 INSTRUCT(상품준비중) 주문 → 택배사 접수용 xlsx 바이너리.
  Future<Either<Failure, Uint8List>> downloadSpreadsheet({int? sellerId});
}
