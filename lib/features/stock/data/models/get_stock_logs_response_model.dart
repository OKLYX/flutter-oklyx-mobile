import 'package:flutter_oklyn_mobile/features/stock/domain/entities/get_stock_logs_response_entity.dart';
import 'stock_log_model.dart';

class GetStockLogsResponseModel extends GetStockLogsResponseEntity {
  const GetStockLogsResponseModel({
    required List<StockLogModel> content,
    required int page,
    required int size,
    required int totalElements,
  }) : super(
    content: content,
    page: page,
    size: size,
    totalElements: totalElements,
  );

  factory GetStockLogsResponseModel.fromJson(Map<String, dynamic> json) {
    final contentList = (json['content'] as List?)
        ?.map((item) => StockLogModel.fromJson(item as Map<String, dynamic>))
        .toList() ?? [];

    return GetStockLogsResponseModel(
      content: contentList,
      page: (json['page'] as dynamic) ?? 0,
      size: (json['size'] as dynamic) ?? 0,
      totalElements: (json['totalElements'] as dynamic) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'content': (content as List<StockLogModel>)
        .map((item) => item.toJson())
        .toList(),
    'page': page,
    'size': size,
    'totalElements': totalElements,
  };
}
