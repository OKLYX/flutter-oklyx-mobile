import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_filter_chip.dart';

/// 「정산 내역」 filter row — seller · channel · payout-date range (FEATURE_2610_20 /
/// D18), the mobile twin of the web `PayoutFilter`. Pure controlled: the BLoC
/// owns the values.
///
/// ⚠️ The range is the PAYOUT date (the label says 「지급일」); 「기간 고르기…」 opens the
/// date range picker and 「전체 기간」 clears it.
class PayoutFilterRow extends StatelessWidget {
  final List<Seller> sellers;
  final List<SettlementSyncTarget> channels;
  final int? sellerId;
  final int? accountId;
  final String from;
  final String to;
  final bool disabled;
  final ValueChanged<int?> onSellerChanged;
  final ValueChanged<int?> onChannelChanged;
  final void Function(String from, String to) onPeriodChanged;

  const PayoutFilterRow({
    required this.sellers,
    required this.channels,
    required this.from,
    required this.to,
    required this.disabled,
    required this.onSellerChanged,
    required this.onChannelChanged,
    required this.onPeriodChanged,
    super.key,
    this.sellerId,
    this.accountId,
  });

  @override
  Widget build(BuildContext context) {
    final seller = sellers.where((s) => s.id == sellerId).firstOrNull;
    final channel = channels.where((c) => c.accountId == accountId).firstOrNull;
    final hasRange = from.isNotEmpty || to.isNotEmpty;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppFilterChip<int?>(
          label: seller == null ? '판매자' : seller.sellerName,
          value: sellerId,
          options: [
            const AppFilterOption<int?>(null, '전체'),
            for (final s in sellers) AppFilterOption<int?>(s.id, s.sellerName),
          ],
          highlighted: sellerId != null,
          onSelected: disabled ? null : onSellerChanged,
        ),
        AppFilterChip<int?>(
          label: channel == null
              ? '채널'
              : channelLabel(
                  channel.platform, channel.accountAlias, channel.accountId),
          value: accountId,
          options: [
            const AppFilterOption<int?>(null, '전체'),
            for (final c in channels)
              AppFilterOption<int?>(c.accountId,
                  channelLabel(c.platform, c.accountAlias, c.accountId)),
          ],
          highlighted: accountId != null,
          onSelected: disabled ? null : onChannelChanged,
        ),
        AppFilterChip<bool>(
          label: hasRange ? '지급일 ${formatDateRange(from, to)}' : '지급일',
          value: hasRange,
          options: const [
            AppFilterOption(false, '전체 기간'),
            AppFilterOption(true, '기간 고르기…'),
          ],
          highlighted: hasRange,
          onSelected:
              disabled ? null : (pick) => _pickPeriod(context, pick: pick),
        ),
      ],
    );
  }

  Future<void> _pickPeriod(BuildContext context, {required bool pick}) async {
    if (!pick) {
      onPeriodChanged('', '');
      return;
    }
    final now = DateTime.now();
    final initial = from.isNotEmpty && to.isNotEmpty
        ? DateTimeRange(start: DateTime.parse(from), end: DateTime.parse(to))
        : null;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
    );
    if (range == null) {
      return;
    }
    onPeriodChanged(toDateText(range.start), toDateText(range.end));
  }
}
