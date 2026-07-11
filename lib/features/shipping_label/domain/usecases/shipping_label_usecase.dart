import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/shipping_label_repository.dart';

/// Shipping Label 다운로드 UseCase (Repository 에 위임하는 얇은 계층).
class ShippingLabelUseCase {
  final ShippingLabelRepository repository;

  ShippingLabelUseCase({required this.repository});

  Future<Either<Failure, Uint8List>> downloadSpreadsheet({int? sellerId}) =>
      repository.downloadSpreadsheet(sellerId: sellerId);
}
