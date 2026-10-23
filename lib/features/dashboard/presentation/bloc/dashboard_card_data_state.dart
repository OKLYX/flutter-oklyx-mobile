/// Load state of one dashboard card (FEATURE_2610_29 / D20).
class DashboardCardDataState<T> {
  final bool loading;

  /// Loaded data; null while loading or after a failure.
  final T? data;

  /// Failure text; empty when there was none.
  final String message;

  const DashboardCardDataState({
    this.loading = true,
    this.data,
    this.message = '',
  });
}
