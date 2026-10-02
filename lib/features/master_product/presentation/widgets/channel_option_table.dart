import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/copy_id_button.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';

// Same notation as the matrix price column (`12,900원`).
String _formatWon(num v) => '${koNumber(v)}원';

const String _noAccountLabel = '계정 없음';
const String _channelOnlyReason = '마스터 옵션이 없는 채널 전용 옵션입니다';
const String _optionIdPendingHint = '승인 후 부여';
const String _lockedHint = '쿠팡에 등록돼 판매 중 — 삭제할 수 없습니다 (이름·구성 수량은 수정 가능)';

/// One column of the web table = one channel cell.
class _OptionColumn {
  final int productListingId;

  /// 판매자 · 플랫폼 · 계정라벨 (`(2)`, `(3)` when an account has several cells).
  final String label;
  final String? platformProductId;
  final Map<int, ListingOptionSummary> byMasterOptionId;

  /// Options without a master counterpart — listed below the cards.
  final List<ListingOptionSummary> channelOnly;

  const _OptionColumn({
    required this.productListingId,
    required this.label,
    required this.platformProductId,
    required this.byMasterOptionId,
    required this.channelOnly,
  });
}

// A cell with no matrix row (its account was deleted).
bool _isOrphanColumn(String label) => label.startsWith(_noAccountLabel);

String _cellText(ListingOptionSummary option) => option.active
    ? '${_formatWon(option.sellingPrice)} / ${option.stockQuantity ?? option.maxStock}'
    : '미사용';

/// Option × channel view (read-only) on the master detail screen —
/// FEATURE_2609_80 / 07.
///
/// **File**: lib/features/master_product/presentation/widgets/channel_option_table.dart
/// **Web original**: `master-products/[id]/components/ChannelOptionTable.tsx` @09208a0
///
/// Mobile draws one card per master option (R7) instead of the wide table:
/// first line = option name + 🔒 + [옵션 수정], then one block per channel
/// cell (header + product ID + that cell's price / stock / option ID).
/// Channel-only options are gathered below, as on the web.
///
/// ⚠️ Data = the parent's single `getChannelOptions` call ([cells]); do not
///    refetch here. `null` = not loaded yet.
/// ⚠️ Cells missing from the matrix (deleted account) are kept at the end as
///    「계정 없음」.
/// ❌ This view only shows, copies and forwards to [onEditMasterOption] — do
///    not add edit points here.
class ChannelOptionTable extends StatelessWidget {
  final List<MatrixRow> rows;
  final List<MasterOption> masterOptions;
  final List<ChannelOptionCell>? cells;

  /// Fetch failure message; empty = no failure.
  final String error;
  final ValueChanged<int> onEditMasterOption;

  const ChannelOptionTable({
    required this.rows,
    required this.masterOptions,
    required this.cells,
    required this.error,
    required this.onEditMasterOption,
    super.key,
  });

  static _OptionColumn _column({
    required int productListingId,
    required String label,
    required String? platformProductId,
    required ChannelOptionCell? cell,
  }) {
    final byMasterOptionId = <int, ListingOptionSummary>{};
    final channelOnly = <ListingOptionSummary>[];
    for (final option in cell?.options ?? const <ListingOptionSummary>[]) {
      final masterOptionId = option.masterOptionId;
      if (masterOptionId != null) {
        byMasterOptionId[masterOptionId] = option;
      } else {
        channelOnly.add(option);
      }
    }
    return _OptionColumn(
      productListingId: productListingId,
      label: label,
      platformProductId: platformProductId,
      byMasterOptionId: byMasterOptionId,
      channelOnly: channelOnly,
    );
  }

  // Columns = matrix order, then cells with no matrix row (deleted account).
  List<_OptionColumn> get _columns {
    final all = cells;
    if (all == null) {
      return [];
    }
    final byListingId = {for (final c in all) c.productListingId: c};
    final used = <int>{};
    final ordered = <_OptionColumn>[];

    for (final row in rows) {
      final single = row.cell;
      final rowCells =
          row.cells ?? (single != null ? [single] : const <MatrixCell>[]);
      for (var index = 0; index < rowCells.length; index++) {
        final matrixCell = rowCells[index];
        final cell = byListingId[matrixCell.productListingId];
        used.add(matrixCell.productListingId);
        final suffix = rowCells.length > 1 ? ' (${index + 1})' : '';
        ordered.add(
          _column(
            productListingId: matrixCell.productListingId,
            label:
                '${row.sellerName} · ${row.platform} · ${row.accountLabel}$suffix',
            platformProductId:
                cell?.platformProductId ?? matrixCell.platformProductId,
            cell: cell,
          ),
        );
      }
    }

    for (final cell in all) {
      if (used.contains(cell.productListingId)) {
        continue;
      }
      ordered.add(
        _column(
          productListingId: cell.productListingId,
          label: '$_noAccountLabel · 상품ID ${cell.platformProductId ?? '–'}',
          platformProductId: cell.platformProductId,
          cell: cell,
        ),
      );
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 14, color: scheme.onSurfaceVariant);
    final isLoading = cells == null && error.isEmpty;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          height: 96,
          child: Center(child: AppBusyLabel('불러오는 중...', size: 20)),
        ),
      );
    }
    if (error.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child:
              Text(error, style: TextStyle(fontSize: 14, color: scheme.error)),
        ),
      );
    }
    if (masterOptions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('등록된 옵션이 없습니다.', style: muted),
      );
    }
    final columns = _columns;
    if (columns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('이 마스터에 연결된 판매채널이 없습니다.', style: muted),
      );
    }
    final channelOnlyColumns =
        columns.where((c) => c.channelOnly.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final opt in masterOptions) ...[
            _OptionCard(
              option: opt,
              columns: columns,
              onEdit: () => onEditMasterOption(opt.id),
            ),
            const SizedBox(height: 8),
          ],
          if (channelOnlyColumns.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text(
              '채널 전용 옵션',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            for (final col in channelOnlyColumns) ...[
              const SizedBox(height: 8),
              _ChannelOnlyBlock(column: col),
            ],
          ],
        ],
      ),
    );
  }
}

/// One master option = one card (R7).
class _OptionCard extends StatelessWidget {
  final MasterOption option;
  final List<_OptionColumn> columns;
  final VoidCallback onEdit;

  const _OptionCard({
    required this.option,
    required this.columns,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        option.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (option.marketRegistered == true) ...[
                        const SizedBox(width: 8),
                        const Text('🔒'),
                        const InfoBubbleIcon(message: _lockedHint),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // One [옵션 수정] per option (web: row header only).
                OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.infoForeground,
                    side: const BorderSide(color: AppColors.infoBorder),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('옵션 수정'),
                ),
              ],
            ),
            for (final col in columns) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _ColumnHeader(column: col),
              const SizedBox(height: 4),
              _cellContent(scheme, col.byMasterOptionId[option.id]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cellContent(ColorScheme scheme, ListingOptionSummary? cellOption) {
    if (cellOption == null) {
      return Text(
        '–',
        style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _cellText(cellOption),
          style: TextStyle(
            fontSize: 14,
            color: cellOption.active ? null : scheme.onSurfaceVariant,
          ),
        ),
        _OptionIdCell(value: cellOption.platformOptionId),
      ],
    );
  }
}

/// Channel block header (web `<th>` of one column).
class _ColumnHeader extends StatelessWidget {
  final _OptionColumn column;

  const _ColumnHeader({required this.column});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final productId = column.platformProductId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          column.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _isOrphanColumn(column.label)
                ? AppColors.warningForeground
                : scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        // A product ID appears only after market registration — no warning color.
        if (productId != null && productId.isNotEmpty)
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '상품ID $productId',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              CopyIdButton(value: productId),
            ],
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '상품ID –',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const InfoBubbleIcon(message: '마켓 등록 후 부여', size: 14),
            ],
          ),
      ],
    );
  }
}

/// Channel-only options of one cell (web bordered box below the table).
class _ChannelOnlyBlock extends StatelessWidget {
  final _OptionColumn column;

  const _ChannelOnlyBlock({required this.column});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            column.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
          for (final option in column.channelOnly) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  option.optionName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _cellText(option),
                  style: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                _OptionIdCell(value: option.platformOptionId),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('옵션 수정'),
                    ),
                    const InfoBubbleIcon(message: _channelOnlyReason),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            _channelOnlyReason,
            style: TextStyle(fontSize: 11, color: AppColors.warningForeground),
          ),
        ],
      ),
    );
  }
}

/// One option ID line. Before approval = `–` + reason icon (no warning color).
class _OptionIdCell extends StatelessWidget {
  final String? value;

  const _OptionIdCell({required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final id = value;
    if (id == null || id.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '옵션ID –',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const InfoBubbleIcon(message: _optionIdPendingHint, size: 14),
        ],
      );
    }
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '옵션ID $id',
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            fontFeatures: const [FontFeature.tabularFigures()],
            color: scheme.onSurfaceVariant,
          ),
        ),
        CopyIdButton(value: id),
      ],
    );
  }
}
