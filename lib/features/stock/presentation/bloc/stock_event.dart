import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock.dart';

sealed class StockEvent extends Equatable {
  const StockEvent();
}

class GetStockRequested extends StockEvent {
  final String barcodeId;

  const GetStockRequested(this.barcodeId);

  @override
  List<Object?> get props => [barcodeId];
}

class CreateStockRequested extends StockEvent {
  final CreateStockRequest request;

  const CreateStockRequested(this.request);

  @override
  List<Object?> get props => [request];
}
