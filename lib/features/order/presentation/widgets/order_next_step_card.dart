import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// Order detail 「다음 단계」 card shell (FEATURE_2611_29 / D7 · D15 · R8).
///
/// **Purpose**: the amber card under the progress steps of the order detail —
/// a bold title line, an optional gray body line and the caller's widgets
/// (buttons · results · errors) below.
/// **File**: lib/features/order/presentation/widgets/order_next_step_card.dart
/// **Used by**: `order_detail_page.dart` · `ElevenstStockConfirmSection`.
///
/// **Usage**:
/// ```dart
/// OrderNextStepCard(title: title, body: body)
/// OrderNextStepCard(
///   title: title,
///   body: notice,
///   children: [buttons, if (error != null) errorText],
/// )
/// ```
///
/// ⚠️ Colors are `AppColors.warningSurface` / `warningBorder` only, inside
/// `AppCard.flush` — `app_card.dart` stays as it is.
/// ❌ Do not use it outside the order detail.
/// ❌ Do not rebuild the same card with a `Container` on a screen.
class OrderNextStepCard extends StatelessWidget {
  final String title;
  final String? body;
  final List<Widget> children;

  const OrderNextStepCard({
    super.key,
    required this.title,
    this.body,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final text = body;
    return AppCard.flush(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.warningSurface,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.warningBorder),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (text != null) ...[
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (children.isNotEmpty) const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
