/// One payment card registered under a seller (FEATURE_2610_18 D29 · D52).
///
/// [maskedNumber] = the masked number printed on receipts. Cards are
/// registered on the web seller screen only (D55) — mobile reads them for the
/// receipt popup.
class SellerCard {
  final int id;
  final int sellerId;
  final String sellerName;
  final String alias;
  final String maskedNumber;

  const SellerCard({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.alias,
    required this.maskedNumber,
  });
}
