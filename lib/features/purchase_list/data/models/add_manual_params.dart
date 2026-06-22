class AddManualParams {
  final int productId;
  final int quantity; // >= 1; accumulates into existing manual line

  AddManualParams({required this.productId, required this.quantity});

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
      };
}
