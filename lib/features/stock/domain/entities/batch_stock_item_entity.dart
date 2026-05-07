import 'package:equatable/equatable.dart';

class BatchStockItemEntity extends Equatable {
  final String barcodeId;
  final int quantity;
  final String name;

  const BatchStockItemEntity({
    required this.barcodeId,
    required this.quantity,
    required this.name,
  });

  @override
  List<Object?> get props => [barcodeId, quantity, name];
}
