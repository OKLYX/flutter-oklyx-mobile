// LotteON notice preview — port of web
// `domain/entities/LotteonNotice.ts` + `presentation/hooks/useLotteonNoticePreview.ts`
// (FEATURE_2610_24 / D38 · D56 · D63 · D68). The twin of `esm_notice.dart`.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';

/// D63 ①: a LotteON-only notice value lives in the master notice map under
/// this prefix (`LOTTEON:품목` = the LotteON item group ·
/// `LOTTEON:{group}:{item}` = a value).
const String kLotteonNoticePrefix = 'LOTTEON:';

/// Web `lotteonOwnNotices` — the non-blank `LOTTEON:*` values, saved next to
/// the chosen group's Coupang values (D68).
Map<String, String> lotteonOwnNotices(Map<String, String> values) => {
      for (final e in values.entries)
        if (e.key.startsWith(kLotteonNoticePrefix) && e.value.trim().isNotEmpty)
          e.key: e.value,
    };

/// What the notice fields show on the LotteON tab (null notification = not
/// known yet).
class LotteonNoticePreview {
  final LotteonNotification? notification;
  final bool failed;

  const LotteonNoticePreview({this.notification, this.failed = false});
}

/// Web `useLotteonNoticePreview` — asks the server for the LotteON view
/// 300 ms after the last change (D56).
///
/// **Purpose**: the container calls [update] on every build with the chosen
/// group's notices and the values; the request goes out only when its content
/// changed. [onChanged] runs after an answer (call `setState` there).
/// **File**: lib/features/master_product/presentation/logic/lotteon_notice.dart
///
/// **Usage**:
/// ```dart
/// final _lotteonPreviewer =
///     LotteonNoticePreviewer(onChanged: () => setState(() {}));
/// _lotteonPreviewer.update(useCase, group, groupNotices, noticeValues);
/// CategoryMetaFields(..., lotteonPreview: _lotteonPreviewer.preview)
/// _lotteonPreviewer.dispose();                          // in dispose
/// ```
///
/// ⚠️ A failed call does not throw — `preview.failed` becomes true and the
///    screen shows its own notice.
class LotteonNoticePreviewer {
  static const Duration _delay = Duration(milliseconds: 300);

  final void Function() onChanged;
  Timer? _timer;
  String? _requestKey;
  LotteonNoticePreview _preview = const LotteonNoticePreview();
  bool _disposed = false;

  LotteonNoticePreviewer({required this.onChanged});

  /// The last answer — kept while the next one is on its way so the fields do
  /// not flicker.
  LotteonNoticePreview get preview => _preview;

  void update(
    MasterProductUseCase useCase,
    String group,
    List<CategoryNotice> groupNotices,
    Map<String, String> values,
  ) {
    final notices = <String, String>{
      for (final n in groupNotices) n.key: values[n.key] ?? '',
      for (final e in values.entries)
        if (e.key.startsWith(kLotteonNoticePrefix)) e.key: e.value,
    };
    final key = jsonEncode({'group': group, 'notices': notices});
    if (key == _requestKey) {
      return;
    }
    _requestKey = key;
    _timer?.cancel();
    _timer = Timer(_delay, () => unawaited(_ask(useCase, key, group, notices)));
  }

  Future<void> _ask(
    MasterProductUseCase useCase,
    String key,
    String group,
    Map<String, String> notices,
  ) async {
    final result = await useCase.previewLotteonNotice(group, notices);
    if (_disposed || key != _requestKey) {
      return;
    }
    _preview = result.fold(
      (_) => LotteonNoticePreview(
          notification: _preview.notification, failed: true),
      (notification) => LotteonNoticePreview(notification: notification),
    );
    onChanged();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}
