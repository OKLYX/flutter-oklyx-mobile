import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/usecases/get_packages_usecase.dart';
import '../../domain/entities/packing.dart';
import '../../domain/usecases/complete_parcel_usecase.dart';
import '../../domain/usecases/get_box_candidates_usecase.dart';
import '../../domain/usecases/get_pending_parcels_usecase.dart';
import '../../domain/usecases/lookup_packing_barcode_usecase.dart';
import '../../domain/usecases/mark_parcel_unused_usecase.dart';
import '../../domain/usecases/restore_parcel_usecase.dart';
import '../../domain/usecases/scan_parcel_usecase.dart';
import 'packing_event.dart';
import 'packing_state.dart';

/// BLoC of the app 「포장 작업」 screen (FEATURE_2611_03 / PLAN D23 · D26 ·
/// D27).
///
/// **Purpose**: one input field opens a box by its invoice number and then
/// matches product barcodes; the operator completes the box, closes it as
/// unused, or restores an unused box.
/// **File**: lib/features/packing/presentation/bloc/packing_bloc.dart
///
/// ⚠️ Every judgement (remaining quantity, last box, full-quantity check) is
///    the server's (D27). The app draws the values it gets and counts the
///    packed quantity only — a refused completion shows the server message.
class PackingBloc extends Bloc<PackingEvent, PackingState> {
  final GetPendingParcelsUseCase getPendingParcelsUseCase;
  final GetPackagesUseCase getPackagesUseCase;
  final ScanParcelUseCase scanParcelUseCase;
  final LookupPackingBarcodeUseCase lookupPackingBarcodeUseCase;
  final GetBoxCandidatesUseCase getBoxCandidatesUseCase;
  final CompleteParcelUseCase completeParcelUseCase;
  final MarkParcelUnusedUseCase markParcelUnusedUseCase;
  final RestoreParcelUseCase restoreParcelUseCase;

  PackingBloc({
    required this.getPendingParcelsUseCase,
    required this.getPackagesUseCase,
    required this.scanParcelUseCase,
    required this.lookupPackingBarcodeUseCase,
    required this.getBoxCandidatesUseCase,
    required this.completeParcelUseCase,
    required this.markParcelUnusedUseCase,
    required this.restoreParcelUseCase,
  }) : super(const PackingState()) {
    on<PackingStarted>(_onStarted);
    on<PackingInputSubmitted>(_onInputSubmitted);
    on<PackingParcelOpened>(_onParcelOpened);
    on<PackingLineChanged>(_onLineChanged);
    on<PackingBoxSelected>(_onBoxSelected);
    on<PackingCompleteRequested>(_onCompleteRequested);
    on<PackingCancelled>(_onCancelled);
    on<PackingUnusedRequested>(_onUnusedRequested);
    on<PackingRestoreRequested>(_onRestoreRequested);
  }

  Future<void> _onStarted(
    PackingStarted event,
    Emitter<PackingState> emit,
  ) async {
    await _reloadPending(emit);
    final packages = await getPackagesUseCase();
    emit(state.copyWith(
      packages: packages.fold((_) => const [], (list) => list),
    ));
  }

  /// Work list — a failure leaves it empty without a toast.
  Future<void> _reloadPending(Emitter<PackingState> emit) async {
    emit(state.copyWith(pendingLoading: true));
    final result = await getPendingParcelsUseCase();
    emit(state.copyWith(
      pending: result.fold((_) => const [], (list) => list),
      pendingLoading: false,
    ));
  }

  Future<void> _onInputSubmitted(
    PackingInputSubmitted event,
    Emitter<PackingState> emit,
  ) async {
    final value = event.value.trim();
    if (value.isEmpty || state.busy) {
      return;
    }
    final scan = state.scan;
    if (scan == null) {
      await _open(value, emit);
      return;
    }
    if (scan.parcel.status == ParcelStatus.pending) {
      await _matchBarcode(value, emit);
    }
    // A closed box ignores the input (R11).
  }

  Future<void> _onParcelOpened(
    PackingParcelOpened event,
    Emitter<PackingState> emit,
  ) async {
    if (state.busy) {
      return;
    }
    await _open(event.invoiceNumber, emit);
  }

  /// Opens a box by its invoice number and, for a pending box, asks the box
  /// candidates once.
  Future<void> _open(String invoiceNumber, Emitter<PackingState> emit) async {
    emit(state.copyWith(busy: true));
    final result = await scanParcelUseCase(invoiceNumber);
    final scan = result.fold((failure) {
      final message = failure is ServerFailure && failure.statusCode == 404
          ? '유효하지 않은 송장번호입니다 — 아직 발송처리 전이거나 주문 동기화가 필요합니다'
          : failure.message;
      emit(state.copyWith(
        busy: false,
        notice: PackingNotice(PackingNoticeKind.error, message),
      ));
      return null;
    }, (scan) => scan);
    if (scan == null) {
      return;
    }
    emit(state.copyWith(
      scan: scan,
      packed: const {},
      candidates: const [],
      candidatesLoading: false,
      clearSelectedBox: true,
      busy: false,
      notice: _openNotice(scan),
    ));
    if (scan.parcel.status == ParcelStatus.pending) {
      await _loadCandidates(scan, emit);
    }
  }

  PackingNotice _openNotice(PackingScan scan) {
    switch (scan.parcel.status) {
      case ParcelStatus.packed:
        return PackingNotice(PackingNoticeKind.error, '이미 출고된 박스입니다');
      case ParcelStatus.unused:
        return PackingNotice(
          PackingNoticeKind.error,
          '미사용 처리된 송장입니다 — [미사용 되돌리기] 로 되돌릴 수 있습니다',
        );
      case ParcelStatus.pending:
        if (scan.unexpanded.isNotEmpty) {
          return PackingNotice(
              PackingNoticeKind.error, packingUnexpandedMessage);
        }
        if (scan.remaining.isEmpty) {
          return PackingNotice(PackingNoticeKind.info, _nothingToPackMessage);
        }
        return PackingNotice(
          PackingNoticeKind.success,
          '송장을 스캔했습니다 — ${scan.parcel.invoiceNumber}',
        );
    }
  }

  /// One request per box (not again while packing — same as the web). The
  /// response is dropped when another box was opened meanwhile.
  Future<void> _loadCandidates(
    PackingScan scan,
    Emitter<PackingState> emit,
  ) async {
    if (scan.remaining.isEmpty) {
      // The server refuses an empty list with 400.
      emit(state.copyWith(candidates: const [], clearSelectedBox: true));
      return;
    }
    final quantities = <int, int>{};
    for (final item in scan.remaining) {
      quantities[item.productId] =
          (quantities[item.productId] ?? 0) + item.remainingQty;
    }
    emit(state.copyWith(candidatesLoading: true));
    final result = await getBoxCandidatesUseCase([
      for (final entry in quantities.entries)
        BoxCandidateItem(productId: entry.key, quantity: entry.value),
    ]);
    if (!identical(state.scan, scan)) {
      return;
    }
    final candidates = result.fold((_) => const <BoxCandidate>[], (l) => l);
    final picked = _defaultCandidate(candidates);
    emit(state.copyWith(
      candidates: candidates,
      candidatesLoading: false,
      selectedBoxId: picked,
      clearSelectedBox: picked == null,
    ));
  }

  /// The most recently used candidate; no date = oldest, a tie keeps the
  /// server order (web `defaultCandidate`).
  int? _defaultCandidate(List<BoxCandidate> candidates) {
    BoxCandidate? latest;
    var latestAt = -1;
    for (final candidate in candidates) {
      final at = DateTime.tryParse(candidate.lastUsedAt ?? '')
              ?.millisecondsSinceEpoch ??
          0;
      if (latest == null || at > latestAt) {
        latest = candidate;
        latestAt = at;
      }
    }
    return latest?.packageId;
  }

  Future<void> _matchBarcode(String value, Emitter<PackingState> emit) async {
    final scan = state.scan!;
    final sameBarcode = scan.remaining
        .where((item) => item.barcodeId?.trim() == value)
        .toList();
    if (sameBarcode.isNotEmpty) {
      _addOne(sameBarcode, emit);
      return;
    }
    emit(state.copyWith(busy: true));
    final result = await lookupPackingBarcodeUseCase(value, scan.parcel.id);
    if (!identical(state.scan, scan)) {
      emit(state.copyWith(busy: false));
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(
        busy: false,
        notice: PackingNotice(PackingNoticeKind.error, failure.message),
      )),
      (lookup) {
        if (!lookup.found) {
          emit(state.copyWith(
            busy: false,
            notice: PackingNotice(
              PackingNoticeKind.error,
              '등록되지 않은 바코드입니다 ($value) — 물품에 바코드를 등록해 주세요',
            ),
          ));
          return;
        }
        if (!lookup.inThisParcel) {
          emit(state.copyWith(
            busy: false,
            notice: PackingNotice(
              PackingNoticeKind.error,
              '없는 물품입니다 — ${lookup.productName ?? value}',
            ),
          ));
          return;
        }
        emit(state.copyWith(busy: false));
        _addOne(
          scan.remaining
              .where((item) => item.productId == lookup.productId)
              .toList(),
          emit,
        );
      },
    );
  }

  /// +1 on the first of [lines] that is not full.
  void _addOne(List<PackingRemainingItem> lines, Emitter<PackingState> emit) {
    for (final item in lines) {
      final current = state.packedOf(item);
      if (current < item.remainingQty) {
        emit(state.copyWith(packed: {
          ...state.packed,
          PackingState.lineKey(item.orderLineId, item.productId): current + 1,
        }));
        return;
      }
    }
    emit(state.copyWith(
      notice: PackingNotice(PackingNoticeKind.error, '수량을 초과했습니다'),
    ));
  }

  void _onLineChanged(PackingLineChanged event, Emitter<PackingState> emit) {
    final scan = state.scan;
    if (state.busy ||
        scan == null ||
        scan.parcel.status != ParcelStatus.pending) {
      return;
    }
    for (final item in scan.remaining) {
      if (item.orderLineId != event.orderLineId ||
          item.productId != event.productId) {
        continue;
      }
      final next = state.packedOf(item) + event.delta;
      if (next < 0 || next > item.remainingQty) {
        return;
      }
      emit(state.copyWith(packed: {
        ...state.packed,
        PackingState.lineKey(item.orderLineId, item.productId): next,
      }));
      return;
    }
  }

  void _onBoxSelected(PackingBoxSelected event, Emitter<PackingState> emit) {
    emit(state.copyWith(selectedBoxId: event.packageId));
  }

  Future<void> _onCompleteRequested(
    PackingCompleteRequested event,
    Emitter<PackingState> emit,
  ) async {
    final scan = state.scan;
    if (state.busy || scan == null) {
      return;
    }
    if (scan.unexpanded.isNotEmpty) {
      emit(state.copyWith(
        notice:
            PackingNotice(PackingNoticeKind.error, packingUnexpandedMessage),
      ));
      return;
    }
    final items = [
      for (final item in scan.remaining)
        if (state.packedOf(item) > 0)
          PackedItem(
            orderLineId: item.orderLineId,
            productId: item.productId,
            quantity: state.packedOf(item),
          ),
    ];
    if (items.isEmpty) {
      emit(state.copyWith(
        notice: PackingNotice(PackingNoticeKind.error, _nothingToPackMessage),
      ));
      return;
    }
    final boxId = state.selectedBoxId;
    if (boxId == null) {
      emit(state.copyWith(
        notice: PackingNotice(PackingNoticeKind.error, '상자를 먼저 선택하세요'),
      ));
      return;
    }
    final left = state.requiredTotal - state.packedTotal;
    emit(state.copyWith(busy: true));
    final result = await completeParcelUseCase(scan.parcel.id, boxId, items);
    final done = result.fold((failure) {
      emit(state.copyWith(
        busy: false,
        notice: PackingNotice(PackingNoticeKind.error, failure.message),
      ));
      return null;
    }, (done) => done);
    if (done == null) {
      return;
    }
    var message =
        left > 0 ? '완료 — 남은 $left개, 다음 송장을 스캔하세요' : '완료 — 다음 송장을 스캔하세요';
    if (done.notices.isNotEmpty) {
      message = '$message · ${done.notices.join(' · ')}';
    }
    emit(_closed().copyWith(
      busy: false,
      notice: PackingNotice(PackingNoticeKind.success, message),
    ));
    await _reloadPending(emit);
  }

  void _onCancelled(PackingCancelled event, Emitter<PackingState> emit) {
    if (state.busy) {
      return;
    }
    emit(_closed().copyWith(
      notice: PackingNotice(PackingNoticeKind.info, '이 박스를 취소했습니다 — 송장을 스캔하세요'),
    ));
  }

  Future<void> _onUnusedRequested(
    PackingUnusedRequested event,
    Emitter<PackingState> emit,
  ) async {
    final scan = state.scan;
    if (state.busy ||
        scan == null ||
        scan.parcel.status != ParcelStatus.pending) {
      return;
    }
    emit(state.copyWith(busy: true));
    final result = await markParcelUnusedUseCase(scan.parcel.id);
    final ok = result.fold((failure) {
      emit(state.copyWith(
        busy: false,
        notice: PackingNotice(PackingNoticeKind.error, failure.message),
      ));
      return false;
    }, (_) => true);
    if (!ok) {
      return;
    }
    emit(_closed().copyWith(
      busy: false,
      notice: PackingNotice(PackingNoticeKind.success, '송장을 미사용 처리했습니다'),
    ));
    await _reloadPending(emit);
  }

  Future<void> _onRestoreRequested(
    PackingRestoreRequested event,
    Emitter<PackingState> emit,
  ) async {
    final scan = state.scan;
    if (state.busy ||
        scan == null ||
        scan.parcel.status != ParcelStatus.unused) {
      return;
    }
    emit(state.copyWith(busy: true));
    final result = await restoreParcelUseCase(scan.parcel.id);
    final ok = result.fold((failure) {
      emit(state.copyWith(
        busy: false,
        notice: PackingNotice(PackingNoticeKind.error, failure.message),
      ));
      return false;
    }, (_) => true);
    if (!ok) {
      return;
    }
    emit(state.copyWith(
      busy: false,
      notice: PackingNotice(PackingNoticeKind.success, '미사용 처리를 되돌렸습니다'),
    ));
    // Same order as the web R7: open the same invoice, then the work list.
    await _open(scan.parcel.invoiceNumber, emit);
    await _reloadPending(emit);
  }

  /// Back to waiting for an invoice.
  PackingState _closed() => state.copyWith(
        clearScan: true,
        packed: const {},
        candidates: const [],
        candidatesLoading: false,
        clearSelectedBox: true,
      );
}

const String _nothingToPackMessage = '담을 물품이 없습니다 — [송장 미사용 처리] 로 닫으세요';
