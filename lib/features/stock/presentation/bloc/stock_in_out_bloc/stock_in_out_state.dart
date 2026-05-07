import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/batch_stock_request_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/models/stock_in_out_item.dart';

sealed class StockInOutState extends Equatable {
  const StockInOutState();

  @override
  List<Object?> get props => [];
}

class StockInOutInitial extends StockInOutState {
  const StockInOutInitial();
}

class StockInOutLoaded extends StockInOutState {
  final List<StockInOutItem> items;
  final StockType selectedType;

  const StockInOutLoaded(this.items, this.selectedType);

  @override
  List<Object?> get props => [items, selectedType];
}

class BarcodeSearchLoading extends StockInOutState {
  const BarcodeSearchLoading();
}

class BarcodeSearchError extends StockInOutState {
  final String message;

  const BarcodeSearchError(this.message);

  @override
  List<Object?> get props => [message];
}

class StockInOutSubmitting extends StockInOutState {
  const StockInOutSubmitting();
}

class StockInOutSubmitSuccess extends StockInOutState {
  const StockInOutSubmitSuccess();
}

class StockInOutSubmitError extends StockInOutState {
  final String message;

  const StockInOutSubmitError(this.message);

  @override
  List<Object?> get props => [message];
}

class QuantityExceededAlert extends StockInOutState {
  final String message;

  const QuantityExceededAlert(this.message);

  @override
  List<Object?> get props => [message];
}
