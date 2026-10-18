/// Stock link setting state (FEATURE_2610_09 D65 · D71).
///
/// [stockLinked] is null until the first load succeeds and keeps the previous
/// value when a load fails. Readers show the stock-linked parts only when it is
/// `true` — null behaves like off (D69 default).
class PurchaseSettingState {
  final bool? stockLinked;

  const PurchaseSettingState({this.stockLinked});
}
