import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_seller_by_id_usecase.dart';
import 'seller_detail_event.dart';
import 'seller_detail_state.dart';

class SellerDetailBloc extends Bloc<SellerDetailEvent, SellerDetailState> {
  final GetSellerByIdUseCase getSellerByIdUseCase;

  SellerDetailBloc({required this.getSellerByIdUseCase})
      : super(const SellerDetailInitial()) {
    on<LoadSellerDetail>(_onLoadDetail);
  }

  Future<void> _onLoadDetail(
    LoadSellerDetail event,
    Emitter<SellerDetailState> emit,
  ) async {
    emit(const SellerDetailLoading());
    final result = await getSellerByIdUseCase(event.sellerId);
    result.fold(
      (failure) => emit(SellerDetailError(failure.message)),
      (seller) => emit(SellerDetailLoaded(seller)),
    );
  }
}
