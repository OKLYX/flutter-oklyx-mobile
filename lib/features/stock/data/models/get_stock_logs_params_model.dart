import 'package:flutter_oklyn_mobile/features/stock/domain/entities/get_stock_logs_params_entity.dart';

class GetStockLogsParamsModel extends GetStockLogsParamsEntity {
  const GetStockLogsParamsModel({
    String? barcodeId,
    String? productName,
    DateTime? startDate,
    DateTime? endDate,
    int page = 0,
    int size = 20,
  }) : super(
    barcodeId: barcodeId,
    productName: productName,
    startDate: startDate,
    endDate: endDate,
    page: page,
    size: size,
  );

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toQueryMap() {
    final params = <String, dynamic>{};

    if (barcodeId != null && barcodeId!.isNotEmpty) {
      params['barcodeId'] = barcodeId;
    }

    if (productName != null && productName!.isNotEmpty) {
      params['productName'] = productName;
    }

    if (startDate != null) {
      params['startDate'] = _formatDate(startDate!);
    }

    if (endDate != null) {
      params['endDate'] = _formatDate(endDate!);
    }

    params['page'] = page;
    params['size'] = size;

    return params;
  }

  @override
  GetStockLogsParamsModel copyWith({
    String? barcodeId,
    String? productName,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? size,
  }) {
    return GetStockLogsParamsModel(
      barcodeId: barcodeId ?? this.barcodeId,
      productName: productName ?? this.productName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }
}
