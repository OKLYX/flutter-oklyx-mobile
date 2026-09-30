import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/entities/carrier_rate.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/category_meta_validation.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/measure_attributes.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/net_content_unit.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/option_meta_fields.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/option_notice_compose.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/category_meta_override_fields.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/quantity_stepper.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';

String _formatWon(num v) => '${koNumber(v)}원';

// Option lock hints (85). The lock is decided by the backend flag
// (marketRegistered) only.
const String _lockedRowTitle = '쿠팡에 등록돼 판매 중 — 삭제할 수 없습니다 (이름·구성 수량은 수정 가능)';
const String _lockedDeleteReason = '쿠팡에 등록돼 판매 중 — 삭제할 수 없습니다.';
// 2609_79 / UX D71: market mode — options mirror the market product, only
// component quantities are entered.
const String _marketDeleteReason = '마켓 상품의 옵션이라 삭제할 수 없습니다.';
const String _marketAddReason = '옵션은 마켓 상품 그대로 만듭니다 — 옵션을 추가할 수 없습니다.';
const String _lastOptionDeleteReason =
    '옵션은 1개 이상 있어야 합니다. 모든 옵션을 제거하기 위해서는 마스터 상품을 삭제해야 합니다.';

// 2609_61: time until the highlight is fully off (2s transition + start
// delay). A single transition, not a blink.
const int _highlightTotalMs = 2200;

// Sum of an option's component quantities (a missing entry counts as the
// displayed default 1).
int _sumQuantitiesOf(
    List<MasterComponent> components, Map<int, String> quantities) {
  var sum = 0;
  for (final c in components) {
    sum += int.tryParse(quantities[c.productId] ?? '1') ?? 0;
  }
  return sum;
}

// Union of two protected key sets (touched ∪ seeded).
Set<String> _unionKeys(Set<String> a, Set<String> b) {
  if (a.isEmpty) {
    return b;
  }
  if (b.isEmpty) {
    return a;
  }
  return {...a, ...b};
}

// Keys whose value is non-blank (stored values to protect = seeded).
Set<String> _filledKeys(Map<String, String> map) =>
    map.keys.where((k) => (map[k] ?? '').trim().isNotEmpty).toSet();

/// Result of [_applyQtyToMeta] — the next attribute / notice maps.
class _MetaFill {
  final Map<String, String> attrs;
  final Map<String, String> notices;

  const _MetaFill(this.attrs, this.notices);
}

/// Single injection point of component quantity / per-unit measure into the
/// category fields (101). Returns the next maps built from [attrValues] /
/// [noticeValues] (web: functional setState updaters).
///
/// - Quantity attributes (name has "수량"): sum of component quantities —
///   no guard.
/// - Per-unit measure attribute: [measured] into the [axis] attribute only,
///   protected by [skipAttrs].
/// - Measure notices: `${measured} ${total}개`, protected by [skipNotices]
///   only when they are user-input fields.
/// - Quantity-only notices: quantity sum (no guard).
_MetaFill _applyQtyToMeta({
  required int total,
  required List<CategoryAttribute> attrs,
  required List<CategoryNotice> ntcs,
  required Map<String, String> attrValues,
  required Map<String, String> noticeValues,
  bool hideCategoryAttrs = false,
  String measured = '',
  String axis = '',
  Set<String> skipAttrs = const {},
  Set<String> skipNotices = const {},
}) {
  final value = total > 0 ? '$total' : '';
  // Whether the measure notice is auto-composed = a composing source exists
  // and attributes are sent.
  final autoMeasureNotice = !hideCategoryAttrs && hasMeasureAttr(attrs);
  final attrNames = hideCategoryAttrs
      ? const <String>[]
      : attrs
          .where((a) => isTotalQuantityName(a.name))
          .map((a) => a.name)
          .toList();
  final measureName =
      !hideCategoryAttrs && measured.isNotEmpty && axis.isNotEmpty
          ? findMeasureAttrName(attrs, axis)
          : '';
  final injectMeasure =
      measureName.isNotEmpty && !skipAttrs.contains(measureName);
  var nextAttrs = attrValues;
  if (attrNames.isNotEmpty || injectMeasure) {
    nextAttrs = {...attrValues};
    for (final k in attrNames) {
      nextAttrs[k] = value; // quantity attribute — no guard
    }
    if (injectMeasure) {
      nextAttrs[measureName] = measured;
    }
  }
  // A measure notice key also contains "수량", so check isMeasureNotice first.
  final composed = composeMeasureNotice(measured, total);
  final noticeTargets = ntcs
      .where((n) => isMeasureNotice(n.key) || isTotalQuantityName(n.key))
      .toList();
  var nextNotices = noticeValues;
  if (noticeTargets.isNotEmpty) {
    nextNotices = {...noticeValues};
    for (final n in noticeTargets) {
      if (isMeasureNotice(n.key)) {
        if (autoMeasureNotice) {
          // Derived value (read-only on screen) → always overwrite, and
          // clear it when composing is no longer possible.
          nextNotices[n.key] = composed;
        } else if (composed.isNotEmpty && !skipNotices.contains(n.key)) {
          // Not composable = user-input field → keep the guard.
          nextNotices[n.key] = composed;
        }
      } else {
        nextNotices[n.key] = value;
      }
    }
  }
  return _MetaFill(nextAttrs, nextNotices);
}

/// Option override payload: drop blanks and keys equal to the master value
/// (omit = inherit).
Map<String, String> _diffOverride(
    Map<String, String> values, Map<String, String> master) {
  final out = <String, String>{};
  values.forEach((k, v) {
    if (v.trim().isEmpty) {
      return; // empty = inherit master
    }
    if (v.trim() == (master[k] ?? '').trim()) {
      return; // same as master = inherit
    }
    out[k] = v;
  });
  return out;
}

class MasterDefaults {
  final int? deliveryId;
  final int? packageId;

  const MasterDefaults({this.deliveryId, this.packageId});
}

/// Web `focusOption: { optionId; nonce }`.
class FocusOptionSignal {
  final int optionId;
  final int nonce;

  const FocusOptionSignal({required this.optionId, required this.nonce});
}

/// Option form state → [MasterOptionRequest] (single source for create and
/// edit) — web `normalizeOptionPayload`.
///
/// ⚠️ Delivery / package override: `null` or equal to the master default →
///    omitted (inherit), so a later master default change reaches the option.
/// ⚠️ Stock (102) does not follow that rule: `null` (blank) = unset, `0` =
///    sold out.
MasterOptionRequest normalizeOptionPayload(
  String name,
  List<MasterComponent> components,
  Map<int, String> quantities,
  int? optDeliveryId,
  int? optPackageId,
  int? optStock,
  MasterDefaults masterDefaults, {
  Map<String, String> optAttrValues = const {},
  Map<String, String> optNoticeValues = const {},
  Map<String, String> masterAttrs = const {},
  Map<String, String> masterNotices = const {},
}) {
  final items = [
    for (final c in components)
      MasterOptionRequestItem(
        productId: c.productId,
        // Blank / missing → 0, rejected by the ≥ 1 check (web NaN).
        quantity: int.tryParse(quantities[c.productId] ?? '') ?? 0,
      ),
  ];
  final deliveryId =
      optDeliveryId == null || optDeliveryId == masterDefaults.deliveryId
          ? null
          : optDeliveryId;
  final packageId =
      optPackageId == null || optPackageId == masterDefaults.packageId
          ? null
          : optPackageId;
  // Category overrides: keep only keys that differ from the master value.
  final categoryAttributes = _diffOverride(optAttrValues, masterAttrs);
  final categoryNotices = _diffOverride(optNoticeValues, masterNotices);
  return MasterOptionRequest(
    name: name.trim(),
    items: items,
    deliveryId: deliveryId,
    packageId: packageId,
    stockQuantity: optStock,
    categoryAttributes:
        categoryAttributes.isNotEmpty ? categoryAttributes : null,
    categoryNotices: categoryNotices.isNotEmpty ? categoryNotices : null,
  );
}

// One option row (server option or create-mode buffer option).
class _OptionRow {
  final String key;
  final int? optionId;
  final String name;
  final List<({int productId, String? productName, int quantity})> items;
  final bool busy;
  final bool locked;
  final String? deleteBlockedReason;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OptionRow({
    required this.key,
    required this.optionId,
    required this.name,
    required this.items,
    required this.busy,
    required this.locked,
    required this.deleteBlockedReason,
    required this.onEdit,
    required this.onDelete,
  });
}

/// Option quantity-combination editor (core business logic) — port of web
/// `app/dashboard/master-products/components/MasterOptionEditor.tsx`
/// (@09208a0).
///
/// **Purpose**: one option = a name + a quantity for every master component.
/// Shared by the create page, the master detail edit section and the detail
/// editor.
/// **File**: lib/features/master_product/presentation/widgets/master_option_editor.dart
///
/// **Modes**:
/// - edit ([master] set): add / update / delete go to the server immediately
///   (M9 · M10 · M11), then [onChanged].
/// - create ([master] null): edits only the parent buffer through [options] /
///   [onOptionsChange] (no server call).
///
/// **Usage**:
/// ```dart
/// // edit mode
/// MasterOptionEditor(
///   carrierRates: _rates, packages: _boxes,
///   master: _master, onChanged: _reloadMaster,
///   masterDefaults: MasterDefaults(
///     deliveryId: _master.defaultDeliveryId,
///     packageId: _master.defaultPackageId),
///   categoryId: _categoryId,
/// )
///
/// // create mode
/// MasterOptionEditor(
///   carrierRates: _rates, packages: _boxes,
///   components: _components, options: _options,
///   onOptionsChange: (next) => setState(() => _options = next),
///   categoryId: _categoryId,
/// )
/// ```
///
/// ⚠️ [focusOption] only means something in edit mode; a new `nonce` opens
///    that option's form, scrolls to its row and highlights it once.
/// ⚠️ [marketLocked] only means something in create mode (UX D71).
/// ❌ No second implementation of the "required missing" check — the save
///    gate and the 「옵션별 설정」 title both call
///    `computeMissingOptionRequired`.
class MasterOptionEditor extends StatefulWidget {
  final List<CarrierRate>
      carrierRates; // features/carrier_rate/domain/entities/carrier_rate.dart
  final List<MasterBox> packages; // 01 master_support.dart
  final MasterProduct?
      master; // set = edit mode (saves to the server immediately)
  final Future<void> Function()? onChanged;
  final List<MasterComponent>? components; // create mode
  final List<MasterOptionRequest>? options;
  final ValueChanged<List<MasterOptionRequest>>? onOptionsChange;
  final MasterDefaults masterDefaults;
  final int? categoryId;
  final String platform;
  final Map<String, String> masterAttrValues;
  final Map<String, String> masterNoticeValues;
  final String? masterNoticeGroup;
  final bool hideCategoryAttrs;
  final ValueChanged<bool>? onFormOpenChange;
  final FocusOptionSignal? focusOption;
  final bool marketLocked;

  const MasterOptionEditor({
    required this.carrierRates,
    required this.packages,
    super.key,
    this.master,
    this.onChanged,
    this.components,
    this.options,
    this.onOptionsChange,
    this.masterDefaults = const MasterDefaults(),
    this.categoryId,
    this.platform = 'COUPANG',
    this.masterAttrValues = const {},
    this.masterNoticeValues = const {},
    this.masterNoticeGroup,
    this.hideCategoryAttrs = false,
    this.onFormOpenChange,
    this.focusOption,
    this.marketLocked = false,
  });

  @override
  State<MasterOptionEditor> createState() => _MasterOptionEditorState();
}

class _MasterOptionEditorState extends State<MasterOptionEditor> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  bool _showForm = false;
  // Edit mode: option id. Create mode: array index. null = adding.
  int? _editingKey;
  final TextEditingController _nameController = TextEditingController();
  Map<int, String> _quantities = {};
  int? _optDeliveryId;
  int? _optPackageId;
  // Master option stock (102). '' = unset (backend default 9999), 0 = sold
  // out — different values.
  final TextEditingController _stockController = TextEditingController();
  // Per-option category attribute / notice overrides (60). Empty = inherit.
  Map<String, String> _optAttrValues = {};
  Map<String, String> _optNoticeValues = {};
  // Auto-fill protection (101 D5): touched = edited by the user this
  // session (always protected); seeded = had a stored value when the form
  // opened (protected on open / schema arrival, yields to quantity changes).
  Set<String> _touchedAttrs = {};
  Set<String> _touchedNotices = {};
  Set<String> _seededAttrKeys = {};
  Set<String> _seededNoticeKeys = {};
  String _formError = '';
  // List-level error (delete failures) — the form error only renders while
  // the form is open.
  String _listError = '';
  // 102/D6: notice when lowering the master stock also lowered channel
  // overrides (not a failure; stays after the form closes).
  String _clampNotice = '';
  bool _isSubmitting = false;
  int? _busyOptionId;
  // 2609_61: single on → off highlight of the focused option row.
  int? _highlightOptionId;
  bool _highlightFading = false;
  Timer? _fadeTimer;
  Timer? _clearTimer;
  final Map<int, GlobalKey> _rowKeys = {};

  // Category attribute + notice schema. categoryId == null → hidden.
  List<CategoryAttribute> _attributes = [];
  List<CategoryNotice> _notices = [];
  bool _attrLoading = false;
  String _attrLoadError = '';
  int _schemaSeq = 0;

  // 2609_73: 「옵션별 설정」 — expanded once when the save gate blocks.
  final ExpansibleController _metaController = ExpansibleController();

  bool get _isEdit => widget.master != null;

  List<MasterComponent> get _components =>
      widget.master?.components ?? widget.components ?? const [];

  @override
  void initState() {
    super.initState();
    // Web effect runs on mount too.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onFormOpenChange?.call(_showForm);
      }
    });
    unawaited(_loadSchema(initial: true));
    if (widget.focusOption != null) {
      _scheduleFocus();
    }
  }

  @override
  void didUpdateWidget(covariant MasterOptionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId ||
        oldWidget.platform != widget.platform) {
      unawaited(_loadSchema());
    }
    final nonce = widget.focusOption?.nonce;
    if (nonce != null && nonce != oldWidget.focusOption?.nonce) {
      _scheduleFocus();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _fadeTimer?.cancel();
    _clearTimer?.cancel();
    _metaController.dispose();
    super.dispose();
  }

  void _setShowForm(bool open) {
    if (_showForm == open) {
      return;
    }
    _showForm = open;
    widget.onFormOpenChange?.call(open);
  }

  // [initial] = called from initState, where setState is not allowed yet.
  Future<void> _loadSchema({bool initial = false}) async {
    final seq = ++_schemaSeq;
    final categoryId = widget.categoryId;
    void start() {
      if (categoryId == null) {
        _attributes = [];
        _notices = [];
        _attrLoadError = '';
        _attrLoading = false;
        return;
      }
      _attrLoading = true;
      _attrLoadError = '';
    }

    if (initial) {
      start();
    } else {
      setState(start);
    }
    if (categoryId == null) {
      return;
    }
    final result =
        await _useCase.getCategorySchema(categoryId, widget.platform);
    if (!mounted || seq != _schemaSeq) {
      return;
    }
    setState(() {
      result.fold(
        (f) {
          _attributes = [];
          _notices = [];
          _attrLoadError = failureText(
              f, '카테고리 필수속성을 불러오지 못했습니다. 옵션별 값을 지정하지 않고 진행할 수 있습니다.');
        },
        (schema) {
          _attributes = schema.attributes;
          _notices = schema.notices;
          // Form already open when the schema arrives → reflect the current
          // quantity total now (measure names need the schema).
          if (_showForm) {
            final comps = _components;
            final measured =
                readMeasureValue(schema.attributes, _optAttrValues).isNotEmpty
                    ? readMeasureValue(schema.attributes, _optAttrValues)
                    : deriveMeasured(comps);
            final fill = _applyQtyToMeta(
              total: _sumQuantitiesOf(comps, _quantities),
              attrs: schema.attributes,
              ntcs: schema.notices,
              attrValues: _optAttrValues,
              noticeValues: _optNoticeValues,
              hideCategoryAttrs: widget.hideCategoryAttrs,
              measured: measured,
              axis: derivedAxis(comps),
              skipAttrs: _unionKeys(_touchedAttrs, _seededAttrKeys),
              skipNotices: _unionKeys(_touchedNotices, _seededNoticeKeys),
            );
            _optAttrValues = fill.attrs;
            _optNoticeValues = fill.notices;
          }
        },
      );
      _attrLoading = false;
    });
  }

  int _sumQuantities(Map<int, String> q) => _sumQuantitiesOf(_components, q);

  /// Quantity / per-unit measure auto-fill with the loaded schema. Must be
  /// called inside setState. [values] = the attribute map to read the
  /// effective measure from (the caller's value, not stale state).
  void _applyItemQtyToMeta(
    int total, {
    required Map<String, String> values,
    required Set<String> skipAttrs,
    required Set<String> skipNotices,
  }) {
    final read = readMeasureValue(_attributes, values);
    final measured = read.isNotEmpty ? read : deriveMeasured(_components);
    final fill = _applyQtyToMeta(
      total: total,
      attrs: _attributes,
      ntcs: _notices,
      attrValues: _optAttrValues,
      noticeValues: _optNoticeValues,
      hideCategoryAttrs: widget.hideCategoryAttrs,
      measured: measured,
      axis: derivedAxis(_components),
      skipAttrs: skipAttrs,
      skipNotices: skipNotices,
    );
    _optAttrValues = fill.attrs;
    _optNoticeValues = fill.notices;
  }

  void _seedForm({
    required String name,
    required List<({int productId, int quantity})> items,
    required int? deliveryId,
    required int? packageId,
    required int? stockQuantity,
    required Map<String, String>? categoryAttributes,
    required Map<String, String>? categoryNotices,
  }) {
    setState(() {
      _nameController.text = name;
      final byId = {for (final it in items) it.productId: it.quantity};
      final seededQuantities = {
        for (final c in _components) c.productId: '${byId[c.productId] ?? 1}',
      };
      _quantities = seededQuantities;
      _optDeliveryId = deliveryId ?? widget.masterDefaults.deliveryId;
      _optPackageId = packageId ?? widget.masterDefaults.packageId;
      // A stored 0 (sold out) must stay 0, not blank.
      _stockController.text = stockQuantity == null ? '' : '$stockQuantity';
      final seededAttrs = {...?categoryAttributes};
      final seededNotices = {...?categoryNotices};
      _optAttrValues = seededAttrs;
      _optNoticeValues = seededNotices;
      final seededA = _filledKeys(seededAttrs);
      final seededN = _filledKeys(seededNotices);
      _touchedAttrs = {}; // new form = reset the user edit history
      _touchedNotices = {};
      _seededAttrKeys = seededA; // stored values protected
      _seededNoticeKeys = seededN;
      // Reflect quantity / measure on open without overwriting stored values
      // (101 D7).
      _applyItemQtyToMeta(
        _sumQuantities(seededQuantities),
        values: seededAttrs,
        skipAttrs: seededA,
        skipNotices: seededN,
      );
      _formError = '';
      _setShowForm(true);
    });
  }

  void _openAdd() {
    _editingKey = null;
    _seedForm(
      name: '',
      items: const [],
      deliveryId: null,
      packageId: null,
      stockQuantity: null,
      categoryAttributes: null,
      categoryNotices: null,
    );
  }

  void _openEditServer(MasterOption opt) {
    _editingKey = opt.id;
    _seedForm(
      name: opt.name,
      items: [
        for (final it in opt.items)
          (productId: it.productId, quantity: it.quantity),
      ],
      deliveryId: opt.deliveryId,
      packageId: opt.packageId,
      stockQuantity: opt.stockQuantity,
      categoryAttributes: opt.categoryAttributes,
      categoryNotices: opt.categoryNotices,
    );
  }

  void _openEditBuffer(MasterOptionRequest opt, int index) {
    _editingKey = index;
    _seedForm(
      name: opt.name,
      items: [
        for (final it in opt.items)
          (productId: it.productId, quantity: it.quantity),
      ],
      deliveryId: opt.deliveryId,
      packageId: opt.packageId,
      stockQuantity: opt.stockQuantity,
      categoryAttributes: opt.categoryAttributes,
      categoryNotices: opt.categoryNotices,
    );
  }

  /// 2609_61: arrival from 「옵션 수정」 elsewhere — ① open that option's
  /// form ② scroll to its row ③ highlight once. A deleted option does
  /// nothing (no error).
  void _scheduleFocus() {
    final target = widget.focusOption;
    if (target == null) {
      return;
    }
    _fadeTimer?.cancel();
    _clearTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      MasterOption? opt;
      for (final o in widget.master?.options ?? const <MasterOption>[]) {
        if (o.id == target.optionId) {
          opt = o;
          break;
        }
      }
      if (opt == null) {
        return; // deleted option — skip silently
      }
      final id = opt.id;
      _openEditServer(opt);
      setState(() {
        _highlightOptionId = id;
        _highlightFading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _rowKeys[id]?.currentContext;
        if (ctx != null && ctx.mounted) {
          unawaited(Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
          ));
        }
      });
      _fadeTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() => _highlightFading = true);
        }
      });
      _clearTimer = Timer(const Duration(milliseconds: _highlightTotalMs), () {
        if (mounted) {
          setState(() {
            _highlightOptionId = null;
            _highlightFading = false;
          });
        }
      });
    });
  }

  // A picked measure unit clears the other side of the pair.
  void _handleOptMeasureUnit(MeasurePair p, String unit) {
    final clearName = unit == '중량'
        ? p.volume.name
        : unit == '용량'
            ? p.weight.name
            : '';
    setState(() {
      if (clearName.isNotEmpty) {
        _optAttrValues = {..._optAttrValues, clearName: ''};
      }
      // Picking the axis is a user edit — protect both sides of the pair.
      _touchedAttrs = {..._touchedAttrs, p.weight.name, p.volume.name};
    });
  }

  /// Option attribute edit. A measure attribute change re-composes the
  /// measure notice (unless the user edited the notice).
  void _handleAttrChange(String name, String value) {
    setState(() {
      final nextValues = {..._optAttrValues, name: value};
      _optAttrValues = nextValues;
      final prevTouched = _touchedAttrs;
      if (!_touchedAttrs.contains(name)) {
        _touchedAttrs = {..._touchedAttrs, name};
      }
      if (axisOfAttrName(name).isNotEmpty) {
        _applyItemQtyToMeta(
          _sumQuantities(_quantities),
          values: nextValues,
          skipAttrs: {...prevTouched, name},
          skipNotices: _touchedNotices,
        );
      }
    });
  }

  // Component quantity change → re-sum → auto-fill the 수량 meta fields.
  void _handleQuantityChange(int productId, String value) {
    setState(() {
      final nextQuantities = {..._quantities, productId: value};
      _quantities = nextQuantities;
      // Quantity is the SSOT → re-compose (protect touched only — D7).
      _applyItemQtyToMeta(
        _sumQuantities(nextQuantities),
        values: _optAttrValues,
        skipAttrs: _touchedAttrs,
        skipNotices: _touchedNotices,
      );
    });
  }

  void _closeForm() {
    setState(() {
      _setShowForm(false);
      _formError = '';
    });
    // The web <details> unmounts with the form → closed on the next open.
    _metaController.collapse();
  }

  bool get _optionMetaMissing =>
      widget.categoryId != null &&
      !_attrLoading &&
      computeMissingOptionRequired(
        _attributes,
        _optAttrValues,
        widget.hideCategoryAttrs,
        OptionNoticeCtx(
          notices: _notices,
          optNoticeValues: _optNoticeValues,
          masterNoticeValues: widget.masterNoticeValues,
          noticeGroup: widget.masterNoticeGroup,
        ),
      );

  Future<void> _handleSubmit() async {
    setState(() {
      _formError = '';
      // Cleared at the next save start (not on close) so the notice
      // survives the form closing.
      _clampNotice = '';
    });
    if (_nameController.text.trim().isEmpty) {
      setState(() => _formError = '옵션 이름을 입력하세요.');
      return;
    }
    if (_optionMetaMissing) {
      setState(() => _formError = '이 옵션의 필수 항목(카테고리가 요구하는 속성·고시)을 입력하세요.');
      // 2609_73: 「옵션별 설정」 is collapsed by default — open it once.
      _metaController.expand();
      return;
    }

    final stockText = _stockController.text;
    final payload = normalizeOptionPayload(
      _nameController.text,
      _components,
      _quantities,
      _optDeliveryId,
      _optPackageId,
      stockText.isEmpty ? null : int.tryParse(stockText),
      widget.masterDefaults,
      optAttrValues: _optAttrValues,
      optNoticeValues: _optNoticeValues,
      masterAttrs: widget.masterAttrValues,
      masterNotices: widget.masterNoticeValues,
    );
    if (payload.items.isEmpty) {
      setState(() => _formError = '구성상품을 먼저 선택하세요.');
      return;
    }
    if (payload.items.any((it) => it.quantity < 1)) {
      setState(() => _formError = '각 구성상품 수량은 1 이상이어야 합니다.');
      return;
    }

    final master = widget.master;
    if (master != null) {
      setState(() => _isSubmitting = true);
      final editingKey = _editingKey;
      final result = editingKey == null
          ? await _useCase.addOption(master.id, payload)
          : await _useCase.updateOption(master.id, editingKey, payload);
      if (!mounted) {
        return;
      }
      final failure = result.fold((f) => f, (res) {
        // 102/D6: lowering the master stock lowered channel overrides too.
        // Market sync needs [수정 요청] — never sent automatically here.
        final clamped = res.clampedChannels;
        if (clamped != null && clamped > 0) {
          setState(() => _clampNotice =
              '채널 $clamped곳의 재고가 마스터 값으로 낮춰졌습니다. 마켓 반영은 [수정 요청]이 필요합니다.');
        }
        return null;
      });
      if (failure != null) {
        final status = failure is ServerFailure ? failure.statusCode : null;
        // Show the 400 reason (locked option edit, duplicate name …).
        setState(() {
          _formError = failureText(
              failure, status == 400 ? '입력값을 확인하세요.' : '저장에 실패했습니다.');
          _isSubmitting = false;
        });
        return;
      }
      await widget.onChanged?.call();
      if (!mounted) {
        return;
      }
      _closeForm();
      setState(() => _isSubmitting = false);
      return;
    }

    // Create mode: mutate the parent buffer only (no server call).
    final next = [...?widget.options];
    final editingKey = _editingKey;
    if (editingKey == null) {
      next.add(payload);
    } else {
      next[editingKey] = payload;
    }
    widget.onOptionsChange?.call(next);
    _closeForm();
  }

  Future<void> _handleDeleteServer(MasterOption opt) async {
    final ok = await showMasterConfirmDialog(
      context,
      message: '옵션 "${opt.name}" 을(를) 삭제하시겠습니까?',
      confirmText: '삭제',
      isDangerous: true,
    );
    final master = widget.master;
    if (!ok || !mounted || master == null) {
      return;
    }
    setState(() {
      _listError = '';
      _busyOptionId = opt.id;
    });
    final result = await _useCase.deleteOption(master.id, opt.id);
    if (!mounted) {
      return;
    }
    final failure = result.fold((f) => f, (_) => null);
    if (failure == null) {
      await widget.onChanged?.call();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      if (failure != null) {
        _listError = failureText(failure, '옵션 삭제에 실패했습니다.');
      }
      _busyOptionId = null;
    });
  }

  void _handleDeleteBuffer(int index) {
    final next = [...?widget.options]..removeAt(index);
    widget.onOptionsChange?.call(next);
  }

  // Item name of an option row (response name → component list → `#id`).
  String _itemName(int productId, String? productName) {
    if (productName != null) {
      return productName;
    }
    for (final c in _components) {
      if (c.productId == productId) {
        return c.productName;
      }
    }
    return '#$productId';
  }

  List<_OptionRow> get _rows {
    final master = widget.master;
    if (master != null) {
      // The master's last option cannot be deleted (options ≥ 1).
      final isLastServerOption = master.options.length <= 1;
      return [
        for (final opt in master.options)
          _OptionRow(
            key: 's-${opt.id}',
            optionId: opt.id,
            name: opt.name,
            items: [
              for (final it in opt.items)
                (
                  productId: it.productId,
                  productName: it.productName,
                  quantity: it.quantity,
                ),
            ],
            busy: _busyOptionId == opt.id,
            locked: opt.marketRegistered ?? false,
            deleteBlockedReason: (opt.marketRegistered ?? false)
                ? _lockedDeleteReason
                : isLastServerOption
                    ? _lastOptionDeleteReason
                    : null,
            onEdit: () => _openEditServer(opt),
            onDelete: () => unawaited(_handleDeleteServer(opt)),
          ),
      ];
    }
    final options = widget.options ?? const <MasterOptionRequest>[];
    return [
      for (var index = 0; index < options.length; index++)
        _OptionRow(
          key: 'b-$index',
          optionId: null,
          name: options[index].name,
          items: [
            for (final it in options[index].items)
              (
                productId: it.productId,
                productName: null,
                quantity: it.quantity,
              ),
          ],
          busy: false,
          // Buffer options are not registered anywhere → no lock. Only
          // market mode blocks deletion (UX D71).
          locked: false,
          deleteBlockedReason: widget.marketLocked ? _marketDeleteReason : null,
          onEdit: () => _openEditBuffer(options[index], index),
          onDelete: () => _handleDeleteBuffer(index),
        ),
    ];
  }

  Widget _errorBox(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 14, color: scheme.error)),
    );
  }

  Widget _amberText(String text) => Text(
        text,
        style:
            const TextStyle(fontSize: 11, color: AppColors.warningForeground),
      );

  Widget _rowTile(BuildContext context, _OptionRow row) {
    final scheme = Theme.of(context).colorScheme;
    final components = _components;
    final highlighted =
        row.optionId != null && _highlightOptionId == row.optionId;
    final Color? bg;
    final Color border;
    if (highlighted && !_highlightFading) {
      bg = AppColors.warningSurface;
      border = AppColors.warningBorder;
    } else {
      bg = scheme.surface.withValues(alpha: 0);
      border = scheme.outlineVariant;
    }
    final key = row.optionId == null
        ? null
        : _rowKeys.putIfAbsent(row.optionId!, GlobalKey.new);
    return AnimatedContainer(
      key: key,
      duration: highlighted && _highlightFading
          ? const Duration(milliseconds: 2000)
          : Duration.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  row.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (row.locked) ...[
                  const Text('🔒'),
                  const InfoBubbleIcon(message: _lockedRowTitle, size: 14),
                ],
                // 2609_78/D48: set (2+ components) = per-item quantity chips ·
                // single component = 「· 수량 N」.
                if (components.length >= 2)
                  for (final it in row.items)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_itemName(it.productId, it.productName)} '
                        '${it.quantity}',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    )
                else
                  Text(
                    '· 수량 ${row.items.isEmpty ? 0 : row.items.first.quantity}',
                    style:
                        TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: row.busy ? null : row.onEdit,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.infoForeground,
                ),
                child: const Text('수정', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: row.busy || row.deleteBlockedReason != null
                    ? null
                    : row.onDelete,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: scheme.error,
                ),
                child: const Text('삭제', style: TextStyle(fontSize: 12)),
              ),
              if (row.deleteBlockedReason != null)
                InfoBubbleIcon(message: row.deleteBlockedReason!, size: 14),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labeled(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          field,
        ],
      );

  Widget _deliverySelect() {
    final defaults = widget.masterDefaults;
    final ids = widget.carrierRates.map((r) => r.id).toSet();
    return DropdownButtonFormField<int?>(
      initialValue: ids.contains(_optDeliveryId) ? _optDeliveryId : null,
      isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: [
        const DropdownMenuItem<int?>(child: Text('마스터 기본값 사용')),
        for (final r in widget.carrierRates)
          DropdownMenuItem<int?>(
            value: r.id,
            child: Text(
              '${r.carrier} ${r.type} · ${_formatWon(r.cost)}'
              '${r.id == defaults.deliveryId ? ' (마스터 기본값)' : ''}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) => setState(() => _optDeliveryId = v),
    );
  }

  Widget _packageSelect() {
    final defaults = widget.masterDefaults;
    final ids = widget.packages.map((p) => p.id).toSet();
    return DropdownButtonFormField<int?>(
      initialValue: ids.contains(_optPackageId) ? _optPackageId : null,
      isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: [
        const DropdownMenuItem<int?>(child: Text('마스터 기본값 사용')),
        for (final p in widget.packages)
          DropdownMenuItem<int?>(
            value: p.id,
            child: Text(
              '${p.type} · ${_formatWon(p.cost)}'
              '${p.id == defaults.packageId ? ' (마스터 기본값)' : ''}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) => setState(() => _optPackageId = v),
    );
  }

  Widget _optionMetaTile(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget body;
    if (_attrLoading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('불러오는 중...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_attrLoadError.isNotEmpty) ...[
            _errorBox(context, _attrLoadError),
            const SizedBox(height: 12),
          ],
          if (_attributes.isNotEmpty || _notices.isNotEmpty) ...[
            Text.rich(
              TextSpan(
                text: '개당 용량/중량·수량은 옵션마다 다르므로 마스터가 아닌 이 옵션에서 입력합니다.',
                children: [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: scheme.error),
                  ),
                  const TextSpan(text: ' 표시는 카테고리(쿠팡 메타)가 요구하는 필수 항목입니다.'),
                ],
              ),
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            CategoryMetaOverrideFields(
              attributes: _attributes,
              notices: _notices,
              attrValues: _optAttrValues,
              noticeValues: _optNoticeValues,
              onAttrChange: _handleAttrChange,
              onNoticeChange: (key, value) => setState(() {
                _optNoticeValues = {..._optNoticeValues, key: value};
                if (!_touchedNotices.contains(key)) {
                  _touchedNotices = {..._touchedNotices, key};
                }
              }),
              onMeasureUnit: _handleOptMeasureUnit,
              disabled: _isSubmitting,
              hideCategoryAttrs: widget.hideCategoryAttrs,
              noticeGroup: widget.masterNoticeGroup,
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '이 카테고리에는 옵션별로 설정할 항목(용량/중량·수량)이 없습니다.',
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ExpansionTile(
        controller: _metaController,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '옵션별 설정 — 개당 용량/중량·수량',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (_optionMetaMissing)
              const Text(
                '· 필수 미입력',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.warningForeground,
                ),
              ),
          ],
        ),
        children: [body],
      ),
    );
  }

  Widget _form(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final master = widget.master;
    final editingKey = _editingKey;
    // Editing an option on sale at Coupang (hint only — inputs are not
    // locked, 2609_74/D4).
    final lockedEditing = master != null &&
        editingKey != null &&
        master.options
            .any((o) => o.id == editingKey && o.marketRegistered == true);
    final marketLocked = widget.marketLocked;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                editingKey == null ? '옵션 추가' : '옵션 수정',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (lockedEditing)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '🔒 쿠팡 판매 중',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.warningForeground,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_formError.isNotEmpty) ...[
            _errorBox(context, _formError),
            const SizedBox(height: 8),
          ],
          _labeled(
            '옵션 이름 *',
            TextField(
              controller: _nameController,
              enabled: !marketLocked,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          if (marketLocked) ...[
            const SizedBox(height: 4),
            Text(
              '마켓 상품의 옵션명이라 바꿀 수 없습니다.',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          // ⚠️ Not an 84 lock target — stock stays editable on sale.
          _labeled(
            '재고수량',
            SizedBox(
              width: 128,
              child: TextField(
                controller: _stockController,
                enabled: !marketLocked,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            marketLocked
                ? '마켓 상품의 재고는 판매상품 옵션에만 들어갑니다 — 마스터 옵션 재고는 비워 둡니다.'
                : '비우면 9999개, 0은 품절로 전송됩니다. 채널에서 더 낮게 조정할 수 있습니다.',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _components.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _components[i].productName,
                    style:
                        TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 8),
                // ⚠️ Not an 84 lock target — the only way to fix a quantity
                // entered wrong at registration.
                QuantityStepper(
                  value: _quantities[_components[i].productId] ?? '1',
                  onChanged: (next) =>
                      _handleQuantityChange(_components[i].productId, next),
                ),
              ],
            ),
          ],
          if (lockedEditing) ...[
            const SizedBox(height: 8),
            _amberText(
              '쿠팡에 등록된 옵션입니다. 이름과 구성 수량은 고칠 수 있고, 삭제는 할 수 없습니다. 이름을 '
              '바꾸면 이 이름을 따라 쓰는 채널 옵션명도 함께 바뀝니다(채널에서 직접 정한 이름은 그대로). '
              '구성 수량을 고치면 쿠팡에 표시된 수량·고시 문구와 달라집니다. 어느 쪽이든 쿠팡에는 '
              '[수정 요청]을 눌러야 전송됩니다.',
            ),
          ],
          const SizedBox(height: 12),
          _labeled('택배비', _deliverySelect()),
          const SizedBox(height: 8),
          _labeled('상자비', _packageSelect()),
          const SizedBox(height: 8),
          Text(
            '비우거나 마스터 기본값과 같으면 마스터 기본 택배/박스를 그대로 사용합니다.',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          // 2609_73: collapsed by default; the title shows 「· 필수 미입력」 and
          // a blocked save expands it (same check as the save gate).
          if (widget.categoryId != null) ...[
            const SizedBox(height: 12),
            _optionMetaTile(context),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(
                onPressed:
                    _isSubmitting ? null : () => unawaited(_handleSubmit()),
                child: _isSubmitting
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('저장 중...'),
                        ],
                      )
                    : const Text('저장'),
              ),
              OutlinedButton(
                onPressed: _isSubmitting ? null : _closeForm,
                child: const Text('취소'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final components = _components;
    final rows = _rows;

    // Visible hint under the list — one reason: locked first, then last
    // option.
    var listBlockedReason = '';
    for (final r in rows) {
      if (r.locked && r.deleteBlockedReason != null) {
        listBlockedReason = r.deleteBlockedReason!;
        break;
      }
    }
    if (listBlockedReason.isEmpty) {
      for (final r in rows) {
        if (r.deleteBlockedReason != null) {
          listBlockedReason = r.deleteBlockedReason!;
          break;
        }
      }
    }

    // Create mode requires both a component set and a category; edit mode's
    // master already carries a category, so only components matter.
    final categoryRequired = !_isEdit;
    final canAddOption = !widget.marketLocked &&
        components.isNotEmpty &&
        (!categoryRequired || widget.categoryId != null);
    final addBlockedReason = widget.marketLocked
        ? _marketAddReason
        : components.isEmpty
            ? '구성상품을 먼저 선택하면 옵션을 추가할 수 있습니다.'
            : '카테고리를 먼저 선택하면 옵션을 추가할 수 있습니다.';

    // Mobile = one column: list, then the form below it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              '옵션',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: canAddOption ? _openAdd : null,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.infoForeground,
              ),
              child: const Text('옵션 추가', style: TextStyle(fontSize: 12)),
            ),
            if (!canAddOption)
              InfoBubbleIcon(message: addBlockedReason, size: 14),
          ],
        ),
        const SizedBox(height: 12),
        if (!canAddOption) ...[
          _amberText(addBlockedReason),
          const SizedBox(height: 12),
        ],
        if (_listError.isNotEmpty) ...[
          _errorBox(context, _listError),
          const SizedBox(height: 8),
        ],
        if (_clampNotice.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _clampNotice,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.successForeground),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (rows.isEmpty) ...[
          Text(
            '등록된 옵션이 없습니다.',
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
        ] else ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 384),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _rowTile(context, rows[i]),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (listBlockedReason.isNotEmpty) ...[
          _amberText(listBlockedReason),
          const SizedBox(height: 12),
        ],
        if (_showForm) ...[
          const SizedBox(height: 16),
          _form(context),
        ],
      ],
    );
  }
}
