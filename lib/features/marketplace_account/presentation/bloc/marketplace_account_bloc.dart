import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/usecases/create_marketplace_account_usecase.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/usecases/delete_marketplace_account_usecase.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/usecases/get_marketplace_accounts_by_seller_usecase.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/usecases/update_marketplace_account_usecase.dart';
import 'marketplace_account_event.dart';
import 'marketplace_account_state.dart';

/// 한 판매자(sellerId)의 판매채널 섹션을 담당하는 BLoC.
///
/// SellerChannelSection 위젯이 펼쳐질 때 판매자별로 factory 로 생성된다.
/// 생성/수정/삭제 후에는 목록을 자동으로 재조회한다.
class MarketplaceAccountBloc extends Bloc<MarketplaceAccountEvent, MarketplaceAccountState> {
  final int sellerId;
  final GetMarketplaceAccountsBySellerUseCase getBySellerUseCase;
  final CreateMarketplaceAccountUseCase createUseCase;
  final UpdateMarketplaceAccountUseCase updateUseCase;
  final DeleteMarketplaceAccountUseCase deleteUseCase;

  MarketplaceAccountBloc({
    required this.sellerId,
    required this.getBySellerUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
  }) : super(const MarketplaceAccountInitial()) {
    on<LoadChannels>(_onLoadChannels);
    on<CreateChannelRequested>(_onCreate);
    on<UpdateChannelRequested>(_onUpdate);
    on<DeleteChannelRequested>(_onDelete);
  }

  Future<void> _onLoadChannels(
    LoadChannels event,
    Emitter<MarketplaceAccountState> emit,
  ) async {
    emit(const MarketplaceAccountLoading());
    await _loadAndEmit(emit);
  }

  Future<void> _onCreate(
    CreateChannelRequested event,
    Emitter<MarketplaceAccountState> emit,
  ) async {
    emit(const MarketplaceAccountActionInProgress());
    final result = await createUseCase(event.params);
    await result.fold(
      (failure) async => emit(MarketplaceAccountActionFailure(failure.message)),
      (_) async {
        emit(const MarketplaceAccountActionSuccess('판매채널이 등록되었습니다.'));
        await _loadAndEmit(emit);
      },
    );
  }

  Future<void> _onUpdate(
    UpdateChannelRequested event,
    Emitter<MarketplaceAccountState> emit,
  ) async {
    emit(const MarketplaceAccountActionInProgress());
    final result = await updateUseCase(
      UpdateMarketplaceAccountParamsWithId(id: event.id, params: event.params),
    );
    await result.fold(
      (failure) async => emit(MarketplaceAccountActionFailure(failure.message)),
      (_) async {
        emit(const MarketplaceAccountActionSuccess('판매채널이 수정되었습니다.'));
        await _loadAndEmit(emit);
      },
    );
  }

  Future<void> _onDelete(
    DeleteChannelRequested event,
    Emitter<MarketplaceAccountState> emit,
  ) async {
    emit(const MarketplaceAccountActionInProgress());
    final result = await deleteUseCase(event.id);
    await result.fold(
      (failure) async => emit(MarketplaceAccountActionFailure(failure.message)),
      (_) async {
        emit(const MarketplaceAccountActionSuccess('판매채널이 삭제되었습니다.'));
        await _loadAndEmit(emit);
      },
    );
  }

  Future<void> _loadAndEmit(Emitter<MarketplaceAccountState> emit) async {
    final result = await getBySellerUseCase(sellerId);
    result.fold(
      (failure) => emit(MarketplaceAccountError(failure.message)),
      (channels) => emit(MarketplaceAccountLoaded(channels)),
    );
  }
}
