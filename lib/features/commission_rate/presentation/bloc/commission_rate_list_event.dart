sealed class CommissionRateListEvent {}

class FetchCommissionRates extends CommissionRateListEvent {}

class ReloadCommissionRates extends CommissionRateListEvent {}

class SearchCommissionRates extends CommissionRateListEvent {
  final String query;
  SearchCommissionRates({required this.query});
}

class ClearSearch extends CommissionRateListEvent {}
