import 'package:equatable/equatable.dart';
import 'batch_stock_item_entity.dart';

enum StockType { IN, OUT }

class BatchStockRequestEntity extends Equatable {
  final StockType type;
  final List<BatchStockItemEntity> items;

  const BatchStockRequestEntity({
    required this.type,
    required this.items,
  });

  @override
  List<Object?> get props => [type, items];
}
