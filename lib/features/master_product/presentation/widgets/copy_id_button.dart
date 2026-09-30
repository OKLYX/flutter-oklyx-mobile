import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copies a marketplace identifier (product ID / option ID) to the clipboard
/// on the master detail screen — FEATURE_2609_80 / 07.
///
/// **Purpose**: sits next to a numeric ID the user compares with WING and
/// copies exactly the value (no spaces, no line breaks). The label switches
/// to `복사됨` for 2 seconds.
/// **File**: lib/features/master_product/presentation/widgets/copy_id_button.dart
/// **Web original**: `master-products/[id]/components/CopyIdButton.tsx` @09208a0
///
/// **Usage**:
/// ```dart
/// CopyIdButton(value: col.platformProductId!)
/// CopyIdButton(value: option.platformOptionId!)
/// ```
///
/// ⚠️ A clipboard failure is silently ignored (same as the web) — the value
///    stays visible on screen, so this is not worth an error toast.
/// ⚠️ Inside a card `InkWell` the button receives the tap first — no event
///    propagation handling is needed.
/// ❌ Do not re-implement inline — two copies of the same behavior drift.
/// ❌ Do not transform [value] (prefix, formatting) — it must be the raw text.
class CopyIdButton extends StatefulWidget {
  final String value;

  const CopyIdButton({required this.value, super.key});

  @override
  State<CopyIdButton> createState() => _CopyIdButtonState();
}

class _CopyIdButtonState extends State<CopyIdButton> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleCopy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.value));
    } on PlatformException {
      // Clipboard unavailable — stay silent on purpose.
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: _handleCopy,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        foregroundColor: scheme.onSurfaceVariant,
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(_copied ? '복사됨' : '복사'),
    );
  }
}
