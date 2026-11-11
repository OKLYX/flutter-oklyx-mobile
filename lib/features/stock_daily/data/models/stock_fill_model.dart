import '../../domain/entities/stock_fill.dart';

/// JSON of `GET /api/admin/stock/fill/candidates` (FEATURE_2611_22 D3 ① ·
/// D31) — one product's 「채울까요?」 sheet.
class FillCandidateModel extends FillCandidate {
  const FillCandidateModel({
    required super.productId,
    required super.productName,
    required super.rowCount,
    required super.emptyQuantity,
    required super.lots,
  });

  factory FillCandidateModel.fromJson(Map<String, dynamic> json) =>
      FillCandidateModel(
        productId: json['productId'] as int,
        productName: json['productName'] as String? ?? '',
        rowCount: json['rowCount'] as int,
        emptyQuantity: json['emptyQuantity'] as int,
        lots: ((json['lots'] as List<dynamic>?) ?? const []).map((e) {
          final lot = e as Map<String, dynamic>;
          return FillCandidateLot(
            lotId: lot['lotId'] as int,
            movedOn: lot['movedOn'] as String? ?? '',
            sellerName: lot['sellerName'] as String?,
            quantity: lot['quantity'] as int,
            rows: ((lot['rows'] as List<dynamic>?) ?? const []).map((r) {
              final row = r as Map<String, dynamic>;
              return FillRow(
                movementId: row['movementId'] as int,
                orderNumber: row['orderNumber'] as String? ?? '',
                movedOn: row['movedOn'] as String? ?? '',
                sellerName: row['sellerName'] as String? ?? '',
                emptyQuantity: row['emptyQuantity'] as int,
                checkedQuantity: row['checkedQuantity'] as int,
              );
            }).toList(),
          );
        }).toList(),
      );
}

/// JSON of `GET /api/admin/stock/fill/lots` (FEATURE_2611_22 D15).
class FillLotModel extends FillLot {
  const FillLotModel({
    required super.lotId,
    required super.movedOn,
    required super.sellerName,
    required super.quantity,
  });

  factory FillLotModel.fromJson(Map<String, dynamic> json) => FillLotModel(
        lotId: json['lotId'] as int,
        movedOn: json['movedOn'] as String? ?? '',
        sellerName: json['sellerName'] as String?,
        quantity: json['quantity'] as int,
      );
}
