import 'package:flutter/material.dart';

/// The one bottom sheet frame of the app (FEATURE_2610_02 · N10; moved here
/// from the master screens).
///
/// **Purpose**: every bottom sheet is 90% of the screen height and has its
/// own `ScaffoldMessenger`, so a toast shown while the sheet is open is not
/// hidden behind it.
/// **File**: lib/shared/widgets/app_sheet.dart
///
/// **Usage**:
/// ```dart
/// final picked = await showAppSheet<List<int>>(
///   context,
///   builder: (sheetContext) => MasterImagePickerSheet(…),
/// );
/// ```
///
/// ⚠️ Show toasts with the context passed to [builder]
///    (`showErrorToast(sheetContext, …)`).
/// ⚠️ Close = drag down, tap outside, back (result `null`).
/// ❌ Never call `showModalBottomSheet` in a page or widget.
/// ❌ Do not make a short sheet shrink to its content — all sheets are 90%.
Future<T?> showAppSheet<T>(
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
