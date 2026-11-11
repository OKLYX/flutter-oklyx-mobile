import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../data/models/create_receipt_params.dart';
import '../repositories/purchase_list_repository.dart';

/// Receipt check-in: photo + lines in one request (FEATURE_2610_18 D28 · D76).
/// Returns the stock rows its lines wrote (FEATURE_2611_22 D3 ①).
class CreateReceiptUseCase {
  final PurchaseListRepository repository;

  CreateReceiptUseCase({required this.repository});

  Future<Either<Failure, List<int>>> call(
      File photo, CreateReceiptParams params) {
    return repository.createReceipt(photo, params);
  }
}
