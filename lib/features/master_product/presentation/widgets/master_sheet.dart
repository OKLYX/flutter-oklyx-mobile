import 'package:flutter/material.dart';

/// Shared bottom-sheet frame for the master product screens (FEATURE_2609_80 · PLAN R-d · R24).
///
/// **Purpose**: opens a web `ui/Modal` with fewer than 2 text inputs as a sheet sliding up from the bottom.
/// **File**: lib/features/master_product/presentation/widgets/master_sheet.dart
///
/// **Usage**:
/// ```dart
/// final picked = await showMasterSheet<List<int>>(
///   context,
///   builder: (sheetContext) => MasterImagePickerSheet(…),
/// );
/// ```
///
/// ⚠️ The sheet has its own `ScaffoldMessenger` — toasts shown while the sheet is open
///    (`showErrorToast(sheetContext, …)`) are not hidden behind it. Show toasts with the
///    context passed to [builder].
/// ⚠️ Height = 90% of the screen. Close = drag down, tap outside, back (same as web ✕ / ESC — result `null`).
/// ❌ Never open a sheet with `showModalBottomSheet` directly — toasts hide behind the sheet.
Future<T?> showMasterSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ScaffoldMessenger(
          child: Builder(
            builder: (inner) => Scaffold(
              backgroundColor: Theme.of(inner).colorScheme.surface,
              body: builder(inner),
            ),
          ),
        ),
      ),
    );
