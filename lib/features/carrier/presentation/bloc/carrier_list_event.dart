abstract class CarrierListEvent {}

class FetchCarriers extends CarrierListEvent {}

class SearchCarriers extends CarrierListEvent {
  final String query;
  SearchCarriers({required this.query});
}
