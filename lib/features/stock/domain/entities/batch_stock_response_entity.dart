import 'package:equatable/equatable.dart';
import 'stock.dart';

class BatchStockResponseEntity extends Equatable {
  final List<CreateStockResponse> items;

  const BatchStockResponseEntity({
    required this.items,
  });

  @override
  List<Object?> get props => [items];
}
