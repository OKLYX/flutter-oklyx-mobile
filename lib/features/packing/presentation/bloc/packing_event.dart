/// Events of `PackingBloc` (FEATURE_2611_03 / PLAN D23 · D26 · D27 ·
/// FEATURE_2611_06 / PLAN D21 · D22 · D24).
sealed class PackingEvent {}

/// The two tabs below the input field (FEATURE_2611_06 / D24).
enum PackingTab { done, pending }

/// Screen entry — loads the work list, today's packed boxes (「오늘 완료」)
/// and every box.
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

/// A tab was picked (FEATURE_2611_06 / D24).
class PackingTabSelected extends PackingEvent {
  final PackingTab tab;

  PackingTabSelected(this.tab);
}

/// The box sheet changed the box of a 「오늘 완료」 row to [boxName]
/// (FEATURE_2611_06 / D19 · D21).
class PackingDoneBoxChanged extends PackingEvent {
  final String boxName;

  PackingDoneBoxChanged(this.boxName);
}

/// The box sheet handed a box back for the box being packed — loads the box
/// list again so a box registered in the sheet is there (FEATURE_2611_06 /
/// D22).
class PackingPackagesReloaded extends PackingEvent {}
