abstract class PurchaseSettingEvent {}

/// Reloads the stock link setting — sent when the drawer opens, when the
/// purchase list page loads and when the 「입고·조정」 page loads
/// (FEATURE_2610_09 D71).
class LoadPurchaseSetting extends PurchaseSettingEvent {}
