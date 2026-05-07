import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/batch_stock_request_entity.dart';

sealed class StockInOutEvent extends Equatable {
  const StockInOutEvent();

  @override
  List<Object?> get props => [];
}

class StockTypeChanged extends StockInOutEvent {
  final StockType type;

  const StockTypeChanged(this.type);

  @override
  List<Object?> get props => [type];
}

class BarcodeSearched extends StockInOutEvent {
  final String barcode;
  final String name;

  const BarcodeSearched(this.barcode, this.name);

  @override
  List<Object?> get props => [barcode, name];
}

class QuantityUpdated extends StockInOutEvent {
  final int index;
  final int newQuantity;

  const QuantityUpdated(this.index, this.newQuantity);

  @override
  List<Object?> get props => [index, newQuantity];
}

class ItemRemoved extends StockInOutEvent {
  final int index;

  const ItemRemoved(this.index);

  @override
  List<Object?> get props => [index];
}

class BatchSubmitRequested extends StockInOutEvent {
  const BatchSubmitRequested();
}
