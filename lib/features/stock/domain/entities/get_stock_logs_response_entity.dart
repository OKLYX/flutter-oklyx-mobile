import 'package:equatable/equatable.dart';
import 'stock_log_entity.dart';

class GetStockLogsResponseEntity extends Equatable {
  final List<StockLogEntity> content;
  final int page;
  final int size;
  final int totalElements;

  const GetStockLogsResponseEntity({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
  });

  int get totalPages => (totalElements / size).ceil();

  @override
  List<Object?> get props => [content, page, size, totalElements];
}
