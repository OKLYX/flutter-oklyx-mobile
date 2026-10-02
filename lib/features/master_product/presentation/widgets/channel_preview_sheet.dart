import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/detail_html_view.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_network_image.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_section_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';

/// What the channel preview sheet shows (web `ChannelPreviewData`).
class ChannelPreviewData {
  /// Thumbnail URL (`null` = none).
  final String? imageSrc;

  /// Generated detail page HTML (`null` = not generated yet).
  final String? html;
  final String title;

  /// `'image'` | `'detail'`.
  final String initialTab;

  const ChannelPreviewData({
    required this.title,
    required this.initialTab,
    this.imageSrc,
    this.html,
  });
}

/// Opens the channel preview sheet — thumbnail + generated detail page in one
/// place — FEATURE_2609_80 / 08.
///
/// **File**: lib/features/master_product/presentation/widgets/channel_preview_sheet.dart
/// **Web original**: `presentation/components/DetailHtmlPreview.tsx` (`ChannelPreviewModal`) @09208a0
///
/// Opened from a listing row's thumbnail or 「상세」 box. Two sections
/// (`이미지` / `상세페이지`) switched by the section bar.
///
/// **Usage**:
/// ```dart
/// await showChannelPreviewSheet(
///   context,
///   ChannelPreviewData(
///     imageSrc: gen?.thumbnailUrl,
///     html: gen?.detailHtml,
///     title: label,
///     initialTab: 'detail',
///   ),
/// );
/// ```
///
/// ⚠️ Read-only — not a confirmation dialog.
/// ⚠️ The detail page scrolls inside its own box (the web view wins the drag).
/// ❌ Do not build a web view per listing row (R13) — rows open this sheet.
Future<void> showChannelPreviewSheet(
  BuildContext context,
  ChannelPreviewData data,
) =>
    showAppSheet<void>(
      context,
      builder: (_) => _ChannelPreviewSheet(data: data),
    );

class _ChannelPreviewSheet extends StatefulWidget {
  final ChannelPreviewData data;

  const _ChannelPreviewSheet({required this.data});

  @override
  State<_ChannelPreviewSheet> createState() => _ChannelPreviewSheetState();
}

class _ChannelPreviewSheetState extends State<_ChannelPreviewSheet> {
  String _tab = 'image';

  @override
  void initState() {
    super.initState();
    _tab = widget.data.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = widget.data;
    final emptyStyle = TextStyle(fontSize: 14, color: scheme.onSurfaceVariant);
    Widget body;
    if (_tab == 'image') {
      final src = data.imageSrc;
      body = src != null && src.isNotEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: InteractiveViewer(
                child: MasterNetworkImage(
                  url: src,
                  width: MediaQuery.sizeOf(context).width,
                  height: 480,
                ),
              ),
            )
          : Center(child: Text('썸네일 이미지가 없습니다', style: emptyStyle));
    } else {
      final html = data.html;
      body = html != null && html.isNotEmpty
          ? SingleChildScrollView(
              child: DetailHtmlView(html: html, height: 560),
            )
          : Center(child: Text('상세페이지가 아직 생성되지 않았습니다', style: emptyStyle));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: MasterSectionBar(
            items: const [
              MasterSectionItem(key: 'image', label: '이미지'),
              MasterSectionItem(key: 'detail', label: '상세페이지'),
            ],
            selected: _tab,
            onSelected: (key) => setState(() => _tab = key),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            data.title,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Expanded(child: body),
      ],
    );
  }
}
