import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/raw_html_pane.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/template_switch_pane.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';

/// Tab 3 — "상세 페이지" shell (2609_20). Sub tabs `템플릿 변경` / `HTML 직접수정`.
/// FEATURE_2609_80 / 06.
///
/// **File**: lib/features/master_product/presentation/widgets/detail_page_pane.dart
/// **Web original**: `master-products/[id]/detail/[listingId]/components/DetailPagePane.tsx` @09208a0
///
/// ⚠️ Sub panes are conditionally rendered (mount swap). [RawHtmlPane] seeds its
/// state from `generated.detailHtml` at mount, and a template save replaces
/// that HTML entirely — keeping it mounted would let the stale HTML overwrite
/// the new template result on the next save (D7). The cost: unsaved edits are
/// lost when switching sub tabs → warned by the (!) bubble.
class DetailPagePane extends StatefulWidget {
  final int listingId;
  final GeneratedProduct generated;
  final DetailTemplate template;
  final ValueChanged<GeneratedProduct> onGenerated;
  final ValueChanged<DetailTemplate> onTemplateChanged;

  const DetailPagePane({
    required this.listingId,
    required this.generated,
    required this.template,
    required this.onGenerated,
    required this.onTemplateChanged,
    super.key,
  });

  @override
  State<DetailPagePane> createState() => _DetailPagePaneState();
}

class _DetailPagePaneState extends State<DetailPagePane> {
  String _sub = 'template'; // 'template' | 'raw'

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'template', label: Text('템플릿 변경')),
                    ButtonSegment(value: 'raw', label: Text('HTML 직접수정')),
                  ],
                  selected: {_sub},
                  showSelectedIcon: false,
                  onSelectionChanged: (next) =>
                      setState(() => _sub = next.first),
                ),
              ),
              const InfoBubbleIcon(message: '편집 중인 내용은 저장하지 않으면 사라집니다'),
            ],
          ),
          const SizedBox(height: 16),
          if (_sub == 'template')
            TemplateSwitchPane(
              listingId: widget.listingId,
              generated: widget.generated,
              template: widget.template,
              onGenerated: widget.onGenerated,
              onTemplateChanged: widget.onTemplateChanged,
            )
          else
            RawHtmlPane(
              listingId: widget.listingId,
              generated: widget.generated,
              onGenerated: widget.onGenerated,
            ),
        ],
      );
}
