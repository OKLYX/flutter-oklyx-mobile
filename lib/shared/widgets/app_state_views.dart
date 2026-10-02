import 'package:flutter/material.dart';

/// Loading / empty / error views for the main content area of a page
/// (FEATURE_2610_02 · N5 / N6 / N7).
///
/// **File**: lib/shared/widgets/app_state_views.dart
///
/// **Usage**:
/// ```dart
/// if (isLoading) const AppLoading()
/// else if (items.isEmpty) const AppEmpty('조회 결과가 없습니다.')
///
/// // Failure with the retry button the page already had.
/// AppErrorBox(
///   message: state.message,
///   action: FilledButton(onPressed: _reload, child: const Text('다시 시도')),
/// )
/// ```
///
/// ⚠️ These are for the main content area only. Loading / empty / error
///    shown inside a sheet, dialog or section keep their current shape.
/// ⚠️ The retry label is always `다시 시도`.
/// ❌ Do not add a retry button where the page had none.

/// N5 — centered spinner, outer padding 32.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
}

/// N6 — centered muted text, outer padding 24. The message is the page's own.
class AppEmpty extends StatelessWidget {
  final String message;

  const AppEmpty(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
}

/// N7 — light red box (radius 4, padding 12 x 8) with red text; [action]
/// (the page's existing retry button) is centered 12 below the box.
class AppErrorBox extends StatelessWidget {
  final String message;
  final Widget? action;

  const AppErrorBox({required this.message, super.key, this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final box = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(message, style: TextStyle(color: scheme.error)),
    );
    final action = this.action;
    if (action == null) {
      return box;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        box,
        const SizedBox(height: 12),
        Center(child: action),
      ],
    );
  }
}
