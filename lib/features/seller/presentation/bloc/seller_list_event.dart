import 'package:equatable/equatable.dart';

abstract class SellerListEvent extends Equatable {
  const SellerListEvent();
  @override
  List<Object?> get props => [];
}

class FetchSellers extends SellerListEvent {
  const FetchSellers();
}

class SearchSellers extends SellerListEvent {
  final String query;
  const SearchSellers({required this.query});
  @override
  List<Object?> get props => [query];
}
