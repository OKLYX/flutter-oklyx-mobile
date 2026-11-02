/// Events of `PackingBloc` (FEATURE_2611_03 / PLAN D23 · D26 · D27).
sealed class PackingEvent {}

/// Screen entry — loads the work list and every box.
class PackingStarted extends PackingEvent {}

/// The one input field was submitted (invoice number or product barcode).
class PackingInputSubmitted extends PackingEvent {
  final String value;

  PackingInputSubmitted(this.value);
}

/// A row of the work list was tapped.
class PackingParcelOpened extends PackingEvent {
  final String invoiceNumber;

  PackingParcelOpened(this.invoiceNumber);
}

/// −/+ of one line. [delta] = -1 or 1.
class PackingLineChanged extends PackingEvent {
  final int orderLineId;
  final int productId;
  final int delta;

  PackingLineChanged({
    required this.orderLineId,
    required this.productId,
    required this.delta,
  });
}

/// A box chip was picked.
class PackingBoxSelected extends PackingEvent {
  final int packageId;

  PackingBoxSelected(this.packageId);
}

/// [이 박스 완료].
class PackingCompleteRequested extends PackingEvent {}

/// [취소] · [다음 송장 스캔].
class PackingCancelled extends PackingEvent {}

/// [송장 미사용 처리] after the confirmation dialog.
class PackingUnusedRequested extends PackingEvent {}

/// [미사용 되돌리기] after the confirmation dialog (D26).
class PackingRestoreRequested extends PackingEvent {}
