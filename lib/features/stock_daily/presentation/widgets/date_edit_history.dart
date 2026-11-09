import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import '../../domain/entities/stock_daily.dart';

/// The day corrections of one daily row, newest first (FEATURE_2611_21 D24),
/// at the bottom of the row sheet and the 「날짜 바꾸기」 sheet:
/// 「{고친 시각} · {고친 사람} · {옛 날짜} → {새 날짜}」. Nothing is drawn for a
/// row never corrected.
class DateEditHistory extends StatelessWidget {
  final List<StockDateEdit> edits;

  const DateEditHistory({required this.edits, super.key});

  @override
  Widget build(BuildContext context) {
    if (edits.isEmpty) {
      return const SizedBox.shrink();
    }
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('날짜 고친 이력', style: TextStyle(fontWeight: FontWeight.w500)),
        for (final edit in edits)
          Text(
            '${formatOrderDateTime(edit.editedAt)} · ${edit.editedBy ?? '-'} · '
            '${edit.oldMovedOn} → ${edit.newMovedOn}',
            style: TextStyle(fontSize: 12, color: muted),
          ),
      ],
    );
  }
}
