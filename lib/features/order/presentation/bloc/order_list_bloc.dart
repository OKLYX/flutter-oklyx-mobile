import 'package:file_saver/file_saver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/domain/usecases/shipping_label_usecase.dart';
import '../../domain/usecases/order_usecase.dart';
import 'order_list_event.dart';
import 'order_list_state.dart';

/// 주문내역 조회/동기화 BLoC
///
/// 프론트 OrderContainer와 동일하게 동작한다:
/// - 진입 시 판매자 목록 + 전체 주문 로드 ([LoadOrders])
/// - 판매자 선택 ([SelectSeller]) 후 조회 ([SearchOrders])
/// - 외부 마켓플레이스 동기화 ([SyncOrders]) 후 목록 갱신 + 결과 요약 표시
///
/// 판매자 목록은 기존 seller 기능의 [GetSellersUseCase]를 재사용한다.
class OrderListBloc extends Bloc<OrderListEvent, OrderListState> {
  final OrderUseCase orderUseCase;
  final GetSellersUseCase getSellersUseCase;
  final ShippingLabelUseCase shippingLabelUseCase;

  OrderListBloc({
    required this.orderUseCase,
    required this.getSellersUseCase,
    required this.shippingLabelUseCase,
  }) : super(OrderListInitial()) {
    on<LoadOrders>(_onLoad);
    on<SelectSeller>(_onSelectSeller);
    on<SearchOrders>(_onSearch);
    on<SyncOrders>(_onSync);
    on<SelectStatus>(_onSelectStatus);
    on<DownloadShippingLabel>(_onDownload);
  }

  Future<void> _onLoad(LoadOrders event, Emitter<OrderListState> emit) async {
    emit(OrderListLoading());

    // 판매자 목록 실패는 비치명적: 드롭다운만 '전체'로 폴백 (프론트와 동일).
    final sellersResult = await getSellersUseCase();
    final sellers = sellersResult.fold((_) => <Seller>[], (list) => list);

    final ordersResult = await orderUseCase.getOrders();
    ordersResult.fold(
      (failure) => emit(OrderListError(message: failure.message)),
      (orders) => emit(OrderListLoaded(sellers: sellers, orders: orders)),
    );
  }

  void _onSelectSeller(SelectSeller event, Emitter<OrderListState> emit) {
    final current = state;
    if (current is! OrderListLoaded) return;
    emit(current.copyWith(
      selectedSellerId: event.sellerId,
      clearSelectedSeller: event.sellerId == null,
    ));
  }

  void _onSelectStatus(SelectStatus event, Emitter<OrderListState> emit) {
    final current = state;
    if (current is! OrderListLoaded) return;
    emit(current.copyWith(
      selectedStatus: event.status,
      clearSelectedStatus: event.status == null,
    ));
  }

  Future<void> _onSearch(
    SearchOrders event,
    Emitter<OrderListState> emit,
  ) async {
    final current = state;
    if (current is! OrderListLoaded) return;
    if (current.isSearching || current.isSyncing || current.isDownloading) return;

    emit(current.copyWith(
        isSearching: true,
        clearActionError: true,
        clearSyncResult: true,
        clearDownloadResult: true));

    final result = await orderUseCase.getOrders(sellerId: current.selectedSellerId);
    result.fold(
      (failure) => emit(current.copyWith(
        isSearching: false,
        orders: const [],
        actionError: failure.message,
      )),
      (orders) => emit(current.copyWith(isSearching: false, orders: orders)),
    );
  }

  Future<void> _onSync(SyncOrders event, Emitter<OrderListState> emit) async {
    final current = state;
    if (current is! OrderListLoaded) return;
    if (current.isSearching || current.isSyncing || current.isDownloading) return;

    emit(current.copyWith(
        isSyncing: true,
        clearActionError: true,
        clearSyncResult: true,
        clearDownloadResult: true));

    final result = await orderUseCase.syncOrders(sellerId: current.selectedSellerId);
    result.fold(
      (failure) => emit(current.copyWith(
        isSyncing: false,
        actionError: failure.message,
      )),
      (sync) => emit(current.copyWith(
        isSyncing: false,
        orders: sync.orders,
        syncResult: sync,
        lastSyncedAt: sync.syncedAt,
      )),
    );
  }

  /// 주문목록 다운로드: Shipping Label xlsx bytes 수신 → file_saver 로 기기
  /// 다운로드 폴더에 저장 → 성공 경로를 transient 로 emit(SnackBar 노출).
  Future<void> _onDownload(
    DownloadShippingLabel event,
    Emitter<OrderListState> emit,
  ) async {
    final current = state;
    if (current is! OrderListLoaded) return;
    if (current.isSearching || current.isSyncing || current.isDownloading) return;

    emit(current.copyWith(
        isDownloading: true, clearActionError: true, clearDownloadResult: true));

    final result =
        await shippingLabelUseCase.downloadSpreadsheet(sellerId: current.selectedSellerId);

    await result.fold(
      (failure) async => emit(current.copyWith(
        isDownloading: false,
        actionError: _downloadErrorMessage(failure),
      )),
      (bytes) async {
        try {
          final now = DateTime.now();
          String two(int n) => n.toString().padLeft(2, '0');
          final today = '${now.year}${two(now.month)}${two(now.day)}';
          // file_saver: 기기 다운로드 폴더에 저장, 저장 경로 반환.
          final path = await FileSaver.instance.saveFile(
            name: '주문목록_$today',
            bytes: bytes,
            ext: 'xlsx',
            mimeType: MimeType.microsoftExcel,
          );
          emit(current.copyWith(isDownloading: false, downloadSavedPath: path));
        } catch (_) {
          emit(current.copyWith(
              isDownloading: false, actionError: '파일 저장에 실패했습니다.'));
        }
      },
    );
  }

  // 403(권한) 외에는 고정 메시지. 프론트와 동일하게 에러 본문은 파싱하지 않는다.
  String _downloadErrorMessage(Failure failure) {
    if (failure is ServerFailure && failure.statusCode == 403) {
      return '권한이 없습니다. 관리자 계정으로 로그인해주세요.';
    }
    return '주문목록 다운로드에 실패했습니다. 다시 시도해주세요.';
  }
}
