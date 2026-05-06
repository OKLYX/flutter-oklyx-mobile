import 'package:equatable/equatable.dart';

sealed class StockState extends Equatable {
  const StockState();
}

class StockInitial extends StockState {
  const StockInitial();

  @override
  List<Object?> get props => [];
}

class StockLoading extends StockState {
  const StockLoading();

  @override
  List<Object?> get props => [];
}

class StockLoaded extends StockState {
  final int inStock;
  final String barcodeId;

  const StockLoaded({required this.inStock, required this.barcodeId});

  @override
  List<Object?> get props => [inStock, barcodeId];
}

class StockError extends StockState {
  final String message;

  const StockError(this.message);

  @override
  List<Object?> get props => [message];
}

class StockSubmitting extends StockState {
  final int inStock;
  final String barcodeId;

  const StockSubmitting({required this.inStock, required this.barcodeId});

  @override
  List<Object?> get props => [inStock, barcodeId];
}

class StockSubmitError extends StockState {
  final String message;
  final int inStock;
  final String barcodeId;

  const StockSubmitError({
    required this.message,
    required this.inStock,
    required this.barcodeId,
  });

  @override
  List<Object?> get props => [message, inStock, barcodeId];
}

class StockSubmitSuccess extends StockState {
  final int inStock;
  final String barcodeId;

  const StockSubmitSuccess({required this.inStock, required this.barcodeId});

  @override
  List<Object?> get props => [inStock, barcodeId];
}
