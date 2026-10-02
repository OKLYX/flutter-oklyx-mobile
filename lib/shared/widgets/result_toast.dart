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
/// showInputNoticeToast(context, '카테고리명을 입력해주세요.');     // 3 s
/// showNoticeToast(context, '입고 대기 중인 구매기록이 없습니다.');  // 3 s
/// ```
///
/// ⚠️ Four kinds (FEATURE_2610_02 · N13): success · error · input notice
///    (asks the user to fill something in) · notice (neither success nor
///    failure, or a message whose outcome the screen cannot tell).
/// ⚠️ Input notice and notice look like success today; their colors live only
///    in [_toastBackground] / [_toastForeground] so they can be changed later
///    in one place.
/// ⚠️ Durations live only in [kResultToastDuration] (error 6 s, others 3 s — D33).
/// ⚠️ While a finger is held on it the notice stays; on release it shows for
///    the remaining time (D33).
/// ⚠️ A new notice immediately hides the one on screen (one at a time).
/// ❌ Do not replace per-item batch result tables with this (D31 exception).
/// ❌ Do not call `ScaffoldMessenger.showSnackBar` in a page or widget.
enum ResultToastTone { success, error, inputNotice, notice }

/// D33: error 6 s, others 3 s.
const Map<ResultToastTone, Duration> kResultToastDuration = {
  ResultToastTone.success: Duration(seconds: 3),
  ResultToastTone.error: Duration(seconds: 6),
  ResultToastTone.inputNotice: Duration(seconds: 3),
  ResultToastTone.notice: Duration(seconds: 3),
};

void showSuccessToast(BuildContext context, String message) =>
    _showResultToast(context, message, ResultToastTone.success);

void showErrorToast(BuildContext context, String message) =>
    _showResultToast(context, message, ResultToastTone.error);

/// Input notice — tells the user what to fill in or pick.
void showInputNoticeToast(BuildContext context, String message) =>
    _showResultToast(context, message, ResultToastTone.inputNotice);

/// Notice — neither success nor failure.
void showNoticeToast(BuildContext context, String message) =>
    _showResultToast(context, message, ResultToastTone.notice);

// The only place that maps a kind to its colors.
Color _toastBackground(ResultToastTone tone, ColorScheme scheme) =>
    switch (tone) {
      ResultToastTone.error => scheme.error,
      ResultToastTone.success => scheme.inverseSurface,
      ResultToastTone.inputNotice => scheme.inverseSurface,
      ResultToastTone.notice => scheme.inverseSurface,
    };

Color _toastForeground(ResultToastTone tone, ColorScheme scheme) =>
    switch (tone) {
      ResultToastTone.error => scheme.onError,
      ResultToastTone.success => scheme.onInverseSurface,
      ResultToastTone.inputNotice => scheme.onInverseSurface,
      ResultToastTone.notice => scheme.onInverseSurface,
    };

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
      backgroundColor: _toastBackground(tone, scheme),
      content: _ResultToastBody(
        message: message,
        duration: kResultToastDuration[tone]!,
        textColor: _toastForeground(tone, scheme),
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
