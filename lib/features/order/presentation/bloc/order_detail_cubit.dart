import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/order_detail.dart';
import '../../domain/usecases/order_usecase.dart';

/// State of the shared order detail (FEATURE_2611_07 / D18 · D23 · D28).
class OrderDetailState {
  /// A read is running.
  final bool loading;

  /// The order from the server — null until the first answer.
  final OrderDetail? detail;

  /// Failure text of the last read, blank when none.
  final String error;

  /// The picked parcel chip — null = the first chip (D28).
  final int? selectedParcelId;

  const OrderDetailState({
    this.loading = true,
    this.detail,
    this.error = '',
    this.selectedParcelId,
  });

  /// The parcel whose content is shown: the picked chip, otherwise the first
  /// chip (D28). Null when the order has no parcel (D26).
  OrderDetailParcel? get shownParcel {
    final parcels = detail?.parcels ?? const <OrderDetailParcel>[];
    if (parcels.isEmpty) {
      return null;
    }
    for (final parcel in parcels) {
      if (parcel.parcelId == selectedParcelId) {
        return parcel;
      }
    }
    return parcels.first;
  }

  OrderDetailState copyWith({
    bool? loading,
    OrderDetail? detail,
    String? error,
    int? selectedParcelId,
  }) =>
      OrderDetailState(
        loading: loading ?? this.loading,
        detail: detail ?? this.detail,
        error: error ?? this.error,
        selectedParcelId: selectedParcelId ?? this.selectedParcelId,
      );
}

/// Cubit of the shared order detail screen (FEATURE_2611_07 / D18 · D23 · D28).
///
/// **Purpose**: reads one order for `OrderDetailPage` — by the tapped order
/// line (「주문내역」) or by the tapped parcel (「포장 작업」 「오늘 완료」) —
/// and keeps the picked parcel chip.
/// **File**: lib/features/order/presentation/bloc/order_detail_cubit.dart
///
/// - [loadByLine] / [loadByParcel] = first open; the parcel read also picks
///   that parcel's chip (D28).
/// - [reload] = the same read again with the picked chip kept (D7) — the
///   drawn order stays until the new answer arrives.
/// - No checks or sums here — every value is the server's.
/// ⚠️ Registered by `getIt` as a factory — a new one for every open.
class OrderDetailCubit extends Cubit<OrderDetailState> {
  final OrderUseCase useCase;

  int? _orderLineId;
  int? _parcelId;

  OrderDetailCubit({required this.useCase}) : super(const OrderDetailState());

  /// First read by the tapped order line.
  Future<void> loadByLine(int orderLineId) {
    _orderLineId = orderLineId;
    _parcelId = null;
    return reload();
  }

  /// First read by the tapped parcel — its chip is picked (D28).
  Future<void> loadByParcel(int parcelId) {
    _parcelId = parcelId;
    _orderLineId = null;
    emit(state.copyWith(selectedParcelId: parcelId));
    return reload();
  }

  /// The same read again; the picked chip stays (D7 · D28).
  Future<void> reload() async {
    final lineId = _orderLineId;
    final parcelId = _parcelId;
    if (lineId == null && parcelId == null) {
      return;
    }
    emit(state.copyWith(loading: true, error: ''));
    final result = lineId != null
        ? await useCase.getOrderDetail(lineId)
        : await useCase.getParcelOrderDetail(parcelId!);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(loading: false, error: failure.message)),
      (detail) => emit(state.copyWith(loading: false, detail: detail)),
    );
  }

  /// A parcel chip was tapped.
  void selectParcel(int parcelId) {
    emit(state.copyWith(selectedParcelId: parcelId));
  }
}
