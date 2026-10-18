class AdjustManualQtyParams {
  final int manualQty; // absolute value, 1 or more (FEATURE_2610_09 D23)

  AdjustManualQtyParams({required this.manualQty});

  Map<String, dynamic> toJson() => {
        'manualQty': manualQty,
      };
}
