import 'dart:async';

import 'package:flutter/material.dart';

/// Shared transient result notice shown just above the bottom nav bar
/// (FEATURE_2609_80, UX D26/D33).
///
/// **Purpose**: mobile counterpart of the web `toast.success` / `toast.error`
/// (`toastStore.ts`).
/// **File**: lib/shared/widgets/result_toast.dart
///
/// **Usage**:
/// ```dart
/// showSuccessToast(context, '마스터를 만들었습니다.');            // 3 s
/// showErrorToast(context, failureText(failure, '저장하지 못했습니다.')); // 6 s
/// ```
///
/// ⚠️ Durations live only in [kResultToastDuration] (success 3 s, error 6 s — D33).
/// ⚠️ While a finger is held on it the notice stays; on release it shows for
///    the remaining time (D33).
/// ⚠️ A new notice immediately hides the one on screen (one at a time).
/// ❌ Do not replace per-item batch result tables with this (D31 exception).
/// ❌ Do not convert existing SnackBars outside the six master screens (D23 scope).
enum ResultToastTone { success, error }

/// D33: success 3 s, error 6 s.
const Map<ResultToastTone, Duration> kResultToastDuration = {
  ResultToastTone.success: Duration(seconds: 3),
  ResultToastTone.error: Duration(seconds: 6),
};

void showSuccessToast(BuildContext context, String message) =>
    _showResultToast(context, message, ResultToastTone.success);

void showErrorToast(BuildContext context, String message) =>
    _showResultToast(context, message, ResultToastTone.error);

void _showResultToast(
  BuildContext context,
  String message,
  ResultToastTone tone,
) {
  final messenger = ScaffoldMessenger.of(context);
  final scheme = Theme.of(context).colorScheme;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
      // The body owns the timer (hold-to-pause); this only has to outlive it.
      duration: const Duration(days: 1),
      backgroundColor:
          tone == ResultToastTone.error ? scheme.error : scheme.inverseSurface,
      content: _ResultToastBody(
        message: message,
        duration: kResultToastDuration[tone]!,
        textColor: tone == ResultToastTone.error
            ? scheme.onError
            : scheme.onInverseSurface,
        onElapsed: messenger.hideCurrentSnackBar,
      ),
    ),
  );
}

class _ResultToastBody extends StatefulWidget {
  final String message;
  final Duration duration;
  final Color textColor;
  final VoidCallback onElapsed;

  const _ResultToastBody({
    required this.message,
    required this.duration,
    required this.textColor,
    required this.onElapsed,
  });

  @override
  State<_ResultToastBody> createState() => _ResultToastBodyState();
}

class _ResultToastBodyState extends State<_ResultToastBody> {
  final Stopwatch _shown = Stopwatch();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resume();
  }

  void _resume() {
    final remaining = widget.duration - _shown.elapsed;
    if (remaining <= Duration.zero) {
      widget.onElapsed();
      return;
    }
    _shown.start();
    _timer = Timer(remaining, widget.onElapsed);
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    _shown.stop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _pause(),
        onPointerUp: (_) => _resume(),
        onPointerCancel: (_) => _resume(),
        child: Text(widget.message, style: TextStyle(color: widget.textColor)),
      );
}
