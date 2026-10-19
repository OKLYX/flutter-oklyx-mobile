/// Events of the payout detail BLoC (FEATURE_2610_20 / D22 · D23 · D34 · D39).
sealed class PayoutDetailEvent {
  const PayoutDetailEvent();
}

/// Screen entry — report + every line (lookups only).
class PayoutDetailStarted extends PayoutDetailEvent {
  const PayoutDetailStarted();
}

/// [다시 시도].
class PayoutDetailRetried extends PayoutDetailEvent {
  const PayoutDetailRetried();
}

/// A cause label tapped — opens it, or closes it when it is already open (one
/// at a time).
class PayoutLabelToggled extends PayoutDetailEvent {
  final String label;
  const PayoutLabelToggled(this.label);
}

/// [미분류만 보기] toggle.
class PayoutUnmatchedToggled extends PayoutDetailEvent {
  const PayoutUnmatchedToggled();
}

/// Block A [보기] — always turns 「미분류」 on.
class PayoutUnmatchedShown extends PayoutDetailEvent {
  const PayoutUnmatchedShown();
}

/// [엑셀 다운로드].
class PayoutExportRequested extends PayoutDetailEvent {
  const PayoutExportRequested();
}

/// [지급 완료] with the picked arrival date `yyyy-MM-dd` (D38).
class PayoutMarkPaidRequested extends PayoutDetailEvent {
  final String paidOn;
  const PayoutMarkPaidRequested(this.paidOn);
}

/// [지급 완료 취소] (D39).
class PayoutUnmarkPaidRequested extends PayoutDetailEvent {
  const PayoutUnmarkPaidRequested();
}
