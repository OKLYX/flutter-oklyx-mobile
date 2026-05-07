import 'package:equatable/equatable.dart';

class GetStockLogsParamsEntity extends Equatable {
  final String? barcodeId;
  final String? productName;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int size;

  const GetStockLogsParamsEntity({
    this.barcodeId,
    this.productName,
    this.startDate,
    this.endDate,
    this.page = 0,
    this.size = 20,
  });

  GetStockLogsParamsEntity copyWith({
    String? barcodeId,
    String? productName,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? size,
  }) {
    return GetStockLogsParamsEntity(
      barcodeId: barcodeId ?? this.barcodeId,
      productName: productName ?? this.productName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }

  @override
  List<Object?> get props => [barcodeId, productName, startDate, endDate, page, size];
}
