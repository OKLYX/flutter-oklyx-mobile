/// Events of the 「채널별 매출」 BLoC (FEATURE_2610_20 / D26).
sealed class ChannelSalesEvent {
  const ChannelSalesEvent();
}

/// Screen entry — channels + per-channel products of the period, then the
/// chosen channel's order lines.
class ChannelSalesStarted extends ChannelSalesEvent {
  const ChannelSalesStarted();
}

/// Sale-date range `yyyy-MM-dd`.
class ChannelSalesPeriodChanged extends ChannelSalesEvent {
  final String from;
  final String to;
  const ChannelSalesPeriodChanged({required this.from, required this.to});
}

/// The channel chip — only the order lines are called again.
class ChannelSalesChannelChanged extends ChannelSalesEvent {
  final int accountId;
  const ChannelSalesChannelChanged(this.accountId);
}

/// [다시 시도].
class ChannelSalesRetried extends ChannelSalesEvent {
  const ChannelSalesRetried();
}

/// 「취소확정(환불완료) 제거」 checkbox — display only, never sent to the server.
class ChannelSalesHideCanceledChanged extends ChannelSalesEvent {
  final bool hide;
  const ChannelSalesHideCanceledChanged({required this.hide});
}

/// 「취소처리중(환불대기) 제거」 checkbox — display only.
class ChannelSalesHidePendingChanged extends ChannelSalesEvent {
  final bool hide;
  const ChannelSalesHidePendingChanged({required this.hide});
}
