import 'package:flutter_bloc/flutter_bloc.dart';
import 'seller_list_event.dart';
import 'seller_list_state.dart';

class SellerListBloc extends Bloc<SellerListEvent, SellerListState> {
  SellerListBloc() : super(const SellerListInitial()) {
    on<FetchSellers>(_onFetchSellers);
    on<SearchSellers>(_onSearchSellers);
  }

  Future<void> _onFetchSellers(FetchSellers event, Emitter<SellerListState> emit) async {
    // Phase 2: Implement actual fetch logic
    // For now, emit empty state for UI structure verification
    emit(const SellerListEmpty());
  }

  Future<void> _onSearchSellers(SearchSellers event, Emitter<SellerListState> emit) async {
    // Phase 2: Implement search logic
    // For now, just keep current state
  }
}
