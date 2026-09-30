import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Box that renders the server-built detail page HTML (FEATURE_2609_80 · D21 · PLAN R21).
///
/// **Purpose**: mobile counterpart of web `<div dangerouslySetInnerHTML={{ __html: html }} />` (preview,
/// direct-edit preview, channel preview window).
/// **File**: lib/features/master_product/presentation/widgets/detail_html_view.dart
///
/// **Usage**:
/// ```dart
/// DetailHtmlView(html: previewHtml, height: 480)
/// DetailHtmlView(html: draftHtml, height: 384)
/// ```
///
/// ⚠️ JavaScript is disabled (`JavaScriptMode.disabled`) — the web preview does not run scripts either.
/// ⚠️ Reloads when [html] changes. The caller sets the height (the web view does not know its content height).
/// ❌ Never open with `url_launcher` (D82 — external links only) · never build a web view other than this box.
class DetailHtmlView extends StatefulWidget {
  final String html;
  final double height;

  const DetailHtmlView({required this.html, required this.height, super.key});

  @override
  State<DetailHtmlView> createState() => _DetailHtmlViewState();
}

class _DetailHtmlViewState extends State<DetailHtmlView> {
  final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.disabled);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(DetailHtmlView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _load();
    }
  }

  void _load() {
    _controller.loadHtmlString(
      '<!DOCTYPE html><html><head><meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width, initial-scale=1">'
      '</head><body style="margin:0">${widget.html}</body></html>',
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: widget.height,
        // Lets a finger scroll inside the box even within a scrolling screen.
        child: WebViewWidget(
          controller: _controller,
          gestureRecognizers: const {
            Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
          },
        ),
      );
}
