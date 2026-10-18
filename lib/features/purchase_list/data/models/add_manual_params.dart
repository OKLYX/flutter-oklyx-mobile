class AddManualParams {
  final int productId;
  final int sellerId; // required (FEATURE_2610_09 D11)
  final int
      quantity; // >= 1; accumulates into the (product × seller) manual line

  AddManualParams({
    required this.productId,
    required this.sellerId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'sellerId': sellerId,
        'quantity': quantity,
      };
}
