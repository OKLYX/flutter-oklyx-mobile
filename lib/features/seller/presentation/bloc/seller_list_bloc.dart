import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import 'seller_list_event.dart';
import 'seller_list_state.dart';

class SellerListBloc extends Bloc<SellerListEvent, SellerListState> {
  final GetSellersUseCase getSellersUseCase;
  List<Seller> _allSellers = [];

  SellerListBloc({required this.getSellersUseCase}) : super(const SellerListInitial()) {
    on<FetchSellers>(_onFetchSellers);
    on<SearchSellers>(_onSearchSellers);
  }

  Future<void> _onFetchSellers(FetchSellers event, Emitter<SellerListState> emit) async {
    emit(const SellerListLoading());
    final result = await getSellersUseCase();
    result.fold(
      (failure) => emit(SellerListError(failure.message ?? 'Error loading sellers')),
      (sellers) {
        _allSellers = sellers;
        emit(sellers.isEmpty ? const SellerListEmpty() : SellerListLoaded(sellers));
      },
    );
  }

  Future<void> _onSearchSellers(SearchSellers event, Emitter<SellerListState> emit) async {
    if (event.query.isEmpty) {
      emit(_allSellers.isEmpty ? const SellerListEmpty() : SellerListLoaded(_allSellers));
    } else {
      final filtered = _allSellers
          .where((s) => s.sellerName.toLowerCase().contains(event.query.toLowerCase()))
          .toList();
      emit(filtered.isEmpty ? const SellerListEmpty() : SellerListLoaded(filtered));
    }
  }
}
