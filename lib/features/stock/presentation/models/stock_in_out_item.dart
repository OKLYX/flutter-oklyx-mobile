class StockInOutItem {
  final String barcodeId;
  final String name;
  final int currentStock;
  int quantity;

  StockInOutItem({
    required this.barcodeId,
    required this.name,
    required this.currentStock,
    required this.quantity,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockInOutItem &&
          runtimeType == other.runtimeType &&
          barcodeId == other.barcodeId;

  @override
  int get hashCode => barcodeId.hashCode;
}
