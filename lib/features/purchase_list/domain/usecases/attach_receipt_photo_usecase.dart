import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/receipt_detail.dart';
import '../repositories/purchase_list_repository.dart';

/// Photo of a 「영수증 나중에」 receipt — [수정] of the receipt sheet
/// (FEATURE_2611_01 D4). Right = the receipt as saved.
class AttachReceiptPhotoUseCase {
  final PurchaseListRepository repository;

  AttachReceiptPhotoUseCase({required this.repository});

  Future<Either<Failure, ReceiptDetail>> call(int receiptId, File photo) =>
      repository.attachReceiptPhoto(receiptId, photo);
}
