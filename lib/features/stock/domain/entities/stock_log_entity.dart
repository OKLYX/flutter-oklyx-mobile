import 'package:equatable/equatable.dart';

class StockLogEntity extends Equatable {
  final int stockId;
  final String barcodeId;
  final String productName;
  final int inStock;
  final int stockAdd;
  final int stockSub;
  final DateTime createdDate;

  const StockLogEntity({
    required this.stockId,
    required this.barcodeId,
    required this.productName,
    required this.inStock,
    required this.stockAdd,
    required this.stockSub,
    required this.createdDate,
  });

  @override
  List<Object?> get props => [
    stockId,
    barcodeId,
    productName,
    inStock,
    stockAdd,
    stockSub,
    createdDate,
  ];
}
