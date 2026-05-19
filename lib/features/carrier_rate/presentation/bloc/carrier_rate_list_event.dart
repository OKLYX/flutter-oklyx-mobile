abstract class CarrierRateListEvent {}

class FetchCarrierRates extends CarrierRateListEvent {}

class SearchCarrierRates extends CarrierRateListEvent {
  final String query;
  SearchCarrierRates({required this.query});
}
