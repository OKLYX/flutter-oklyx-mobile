import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/auto_preview_pane.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/detail_page_pane.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_section_bar.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/structured_data_pane.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/thumbnail_pane.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// Detail editor tab shell (4 sections). FEATURE_2609_80 / 06.
///
/// **File**: lib/features/master_product/presentation/widgets/detail_editor_tabs.dart
/// **Web original**: `master-products/[id]/detail/[listingId]/components/DetailEditorTabs.tsx` @09208a0
///
/// The page owns `generated`; children lift updates via [onGenerated].
/// `source` always derives from `generated.source` (no separate prop/state).
/// ⚠️ Only the selected pane is built — switching rebuilds it (same as the
///    web conditional render, not `Offstage`).
class DetailEditorTabs extends StatefulWidget {
  final int masterId;
  final int listingId;
  final GeneratedProduct generated;
  final DetailTemplate template;
  final ValueChanged<GeneratedProduct> onGenerated;

  /// When the template changes the page-owned template must be replaced too
  /// (the structure tab uses its blocks).
  final ValueChanged<DetailTemplate> onTemplateChanged;

  const DetailEditorTabs({
    required this.masterId,
    required this.listingId,
    required this.generated,
    required this.template,
    required this.onGenerated,
    required this.onTemplateChanged,
    super.key,
  });

  @override
  State<DetailEditorTabs> createState() => _DetailEditorTabsState();
}

class _DetailEditorTabsState extends State<DetailEditorTabs> {
  static const List<MasterSectionItem> _tabs = [
    MasterSectionItem(key: 'preview', label: '자동 미리보기'),
    MasterSectionItem(key: 'structure', label: '구조 데이터'),
    MasterSectionItem(key: 'detail', label: '상세 페이지'),
    MasterSectionItem(key: 'thumbnail', label: '썸네일'),
  ];

  String _tab = 'preview';

  @override
  Widget build(BuildContext context) => AppCard.flush(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: MasterSectionBar(
                items: _tabs,
                selected: _tab,
                onSelected: (key) => setState(() => _tab = key),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _pane(),
            ),
          ],
        ),
      );

  Widget _pane() {
    switch (_tab) {
      case 'structure':
        return StructuredDataPane(
          masterId: widget.masterId,
          listingId: widget.listingId,
          template: widget.template,
          generated: widget.generated,
          onGenerated: widget.onGenerated,
        );
      case 'detail':
        return DetailPagePane(
          listingId: widget.listingId,
          generated: widget.generated,
          template: widget.template,
          onGenerated: widget.onGenerated,
          onTemplateChanged: widget.onTemplateChanged,
        );
      case 'thumbnail':
        return ThumbnailPane(
          listingId: widget.listingId,
          generated: widget.generated,
          onGenerated: widget.onGenerated,
        );
      case 'preview':
      default:
        return AutoPreviewPane(
          listingId: widget.listingId,
          generated: widget.generated,
        );
    }
  }
}
