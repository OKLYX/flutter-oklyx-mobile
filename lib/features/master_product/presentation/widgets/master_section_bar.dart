import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';

/// One section button.
/// [summary] = the web tab `title={t.summary}` (a one-liner shown only on hover).
class MasterSectionItem {
  final String key;
  final String label;
  final String? summary;

  const MasterSectionItem({required this.key, required this.label, this.summary});
}

/// Section button row at the top of mobile master screens (FEATURE_2609_80 · UX D27 · D54).
///
/// **Purpose**: ports the web tab bars (MasterSectionTabs · DetailEditorTabs · ChannelPreviewModal tabs; not MetaPlatformTabs) —
/// tapping shows only that section.
/// **File**: lib/features/master_product/presentation/widgets/master_section_bar.dart
///
/// **Usage**:
/// ```dart
/// MasterSectionBar(
///   items: const [
///     MasterSectionItem(key: 'preview', label: '자동 미리보기'),
///     MasterSectionItem(key: 'structure', label: '구조 데이터'),
///   ],
///   selected: _tab,
///   onSelected: (key) => setState(() => _tab = key),
/// )
/// ```
///
/// ⚠️ Overflow scrolls horizontally (no wrapping).
/// ⚠️ When `MasterSectionItem.summary` is set, a (!) follows the button — tapping shows a bubble (D30).
/// ❌ Never nest this row inside a section — the only exception is the product-relation 「마스터」 (PLAN R-f) (the channel preview sheet in 08 is a sheet, not a section).
class MasterSectionBar extends StatelessWidget {
  final List<MasterSectionItem> items;
  final String selected;
  final ValueChanged<String> onSelected;

  /// Button at the end of the row (`상품 관계` on the detail screen — 09).
  final Widget? trailing;

  const MasterSectionBar({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in items) ...[
              ChoiceChip(
                label: Text(item.label),
                selected: item.key == selected,
                onSelected: (_) => onSelected(item.key),
              ),
              if (item.summary != null && item.summary!.isNotEmpty)
                InfoBubbleIcon(message: item.summary!),
              const SizedBox(width: 8),
            ],
            if (trailing != null) trailing!,
          ],
        ),
      );
}
