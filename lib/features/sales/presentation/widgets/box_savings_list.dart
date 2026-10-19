import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/utils/sales_format.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/package_box_shape.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';

/// 「상자별 절약」 rows (FEATURE_2610_20 / D26) — the web `BoxSavingsTable`. A photo
/// when the box has one, otherwise [PackageBoxShape]; 「재활용」 tag for recycled
/// boxes.
class BoxSavingsList extends StatelessWidget {
  final List<BoxSaving> rows;
  final bool loading;
  final String error;

  const BoxSavingsList(
      {required this.rows,
      required this.loading,
      required this.error,
      super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    if (error.isNotEmpty) {
      return AppErrorBox(message: error);
    }
    if (loading && rows.isEmpty) {
      return const AppLoading();
    }
    if (rows.isEmpty) {
      return const AppEmpty('이 기간에 포장한 박스가 없습니다.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loading) Text('조회 중...', style: muted),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const AppRowGap(),
          _row(rows[i], scheme, muted),
        ],
      ],
    );
  }

  Widget _row(BoxSaving row, ColorScheme scheme, TextStyle muted) {
    final image = row.imageUrl;
    return AppCard.row(
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: image != null
                ? Image.network(image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2))
                : PackageBoxShape(
                    widthCm: row.widthCm,
                    lengthCm: row.lengthCm,
                    heightCm: row.heightCm),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                        child: Text(row.type,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                    if (row.boxKind == 'RECYCLED') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        color: AppColors.successSurface,
                        child: const Text('재활용',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.successForeground)),
                      ),
                    ],
                  ],
                ),
                Text.rich(
                  TextSpan(
                    style: muted,
                    children: [
                      TextSpan(
                          text: '박스 ${formatCount(row.parcelCount)} · 상자 '),
                      TextSpan(
                        text: formatSaving(row.boxSaving),
                        style: TextStyle(
                            color: savingColor(row.boxSaving, scheme)),
                      ),
                      const TextSpan(text: ' · 택배 '),
                      TextSpan(
                        text: formatSaving(row.deliverySaving),
                        style: TextStyle(
                            color: savingColor(row.deliverySaving, scheme)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatSaving(row.totalSaving),
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: savingColor(row.totalSaving, scheme)),
          ),
        ],
      ),
    );
  }
}
