class AdjustManualQtyParams {
  final int manualQty; // absolute value (0+)

  AdjustManualQtyParams({required this.manualQty});

  Map<String, dynamic> toJson() => {
        'manualQty': manualQty,
      };
}
