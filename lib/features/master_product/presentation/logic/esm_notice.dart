// Gmarket · Auction (ESM) notice preview — port of web
// `domain/entities/EsmNotice.ts` + `presentation/hooks/useEsmNoticePreview.ts`
// (FEATURE_2610_26 / D17 · D46 · D56). The twin of `elevenst_notice.dart`.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';

/// D17: an ESM-only notice value lives in the master notice map under this
/// prefix + the ESM item code.
const String kEsmNoticePrefix = 'ESM:';

/// Web `esmOwnNotices` — the non-blank `ESM:*` values, saved next to the
/// chosen group's Coupang values.
Map<String, String> esmOwnNotices(Map<String, String> values) => {
      for (final e in values.entries)
        if (e.key.startsWith(kEsmNoticePrefix) && e.value.trim().isNotEmpty)
          e.key: e.value,
    };

/// What the notice fields show on the Gmarket · Auction tab (null notification
/// = not known yet).
class EsmNoticePreview {
  final EsmNotification? notification;
  final bool failed;

  const EsmNoticePreview({this.notification, this.failed = false});
}

/// Web `useEsmNoticePreview` — asks the server for the ESM view 300 ms after
/// the last change.
///
/// **Purpose**: the container calls [update] on every build with the chosen
/// group's notices and the values; the request goes out only when its content
/// changed. [onChanged] runs after an answer (call `setState` there).
/// **File**: lib/features/master_product/presentation/logic/esm_notice.dart
///
/// **Usage**:
/// ```dart
/// final _esmPreviewer = EsmNoticePreviewer(onChanged: () => setState(() {}));
/// _esmPreviewer.update(useCase, group, groupNotices, noticeValues);
/// CategoryMetaFields(..., esmPreview: _esmPreviewer.preview)
/// _esmPreviewer.dispose();                              // in dispose
/// ```
///
/// ⚠️ A failed call does not throw — `preview.failed` becomes true and the
///    screen shows its own notice.
class EsmNoticePreviewer {
  static const Duration _delay = Duration(milliseconds: 300);

  final void Function() onChanged;
  Timer? _timer;
  String? _requestKey;
  EsmNoticePreview _preview = const EsmNoticePreview();
  bool _disposed = false;

  EsmNoticePreviewer({required this.onChanged});

  /// The last answer — kept while the next one is on its way so the fields do
  /// not flicker.
  EsmNoticePreview get preview => _preview;

  void update(
    MasterProductUseCase useCase,
    String group,
    List<CategoryNotice> groupNotices,
    Map<String, String> values,
  ) {
    final notices = <String, String>{
      for (final n in groupNotices) n.key: values[n.key] ?? '',
      for (final e in values.entries)
        if (e.key.startsWith(kEsmNoticePrefix)) e.key: e.value,
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
    final result = await useCase.previewEsmNotice(group, notices);
    if (_disposed || key != _requestKey) {
      return;
    }
    _preview = result.fold(
      (_) =>
          EsmNoticePreview(notification: _preview.notification, failed: true),
      (notification) => EsmNoticePreview(notification: notification),
    );
    onChanged();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}
