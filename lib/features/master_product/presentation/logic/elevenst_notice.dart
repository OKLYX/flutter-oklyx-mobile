// 11st notice preview — port of web `domain/entities/ElevenstNotice.ts` + `presentation/hooks/useElevenstNoticePreview.ts`
// (FEATURE_2610_13 / D97 · D99 · D100 · D101).
import 'dart:async';
import 'dart:convert';

import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';

/// D101: an 11st-only notice value lives in the master notice map under this prefix + the 11st item code.
const String kElevenstNoticePrefix = 'ELEVENST:';

/// Web `elevenstOwnNotices` — the non-blank `ELEVENST:*` values, saved next to the chosen group's Coupang values.
Map<String, String> elevenstOwnNotices(Map<String, String> values) => {
      for (final e in values.entries)
        if (e.key.startsWith(kElevenstNoticePrefix) &&
            e.value.trim().isNotEmpty)
          e.key: e.value,
    };

/// What the notice fields show on the 11st tabs (null notification = not known yet).
class ElevenstNoticePreview {
  final ElevenstNotification? notification;
  final bool failed;

  const ElevenstNoticePreview({this.notification, this.failed = false});
}

/// Web `useElevenstNoticePreview` — asks the server for the 11st view 300 ms after the last change.
///
/// **Purpose**: the container calls [update] on every build with the chosen group's notices and the values; the
/// request goes out only when its content changed. [onChanged] runs after an answer (call `setState` there).
/// **File**: lib/features/master_product/presentation/logic/elevenst_notice.dart
///
/// **Usage**:
/// ```dart
/// final _previewer = ElevenstNoticePreviewer(onChanged: () => setState(() {}));
/// _previewer.update(useCase, group, groupNotices, noticeValues);   // in build, when 11st is active
/// CategoryMetaFields(..., elevenstPreview: _previewer.preview)
/// _previewer.dispose();                                              // in dispose
/// ```
///
/// ⚠️ A failed call does not throw — `preview.failed` becomes true and the screen shows its own notice.
class ElevenstNoticePreviewer {
  static const Duration _delay = Duration(milliseconds: 300);

  final void Function() onChanged;
  Timer? _timer;
  String? _requestKey;
  ElevenstNoticePreview _preview = const ElevenstNoticePreview();
  bool _disposed = false;

  ElevenstNoticePreviewer({required this.onChanged});

  /// The last answer — kept while the next one is on its way so the fields do not flicker.
  ElevenstNoticePreview get preview => _preview;

  void update(
    MasterProductUseCase useCase,
    String group,
    List<CategoryNotice> groupNotices,
    Map<String, String> values,
  ) {
    final notices = <String, String>{
      for (final n in groupNotices) n.key: values[n.key] ?? '',
      for (final e in values.entries)
        if (e.key.startsWith(kElevenstNoticePrefix)) e.key: e.value,
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
    final result = await useCase.previewElevenstNotice(group, notices);
    if (_disposed || key != _requestKey) {
      return;
    }
    _preview = result.fold(
      (_) => ElevenstNoticePreview(
          notification: _preview.notification, failed: true),
      (notification) => ElevenstNoticePreview(notification: notification),
    );
    onChanged();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}
