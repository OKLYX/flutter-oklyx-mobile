import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_image_picker_sheet.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_network_image.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_pool_manage_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/zoomable_image_viewer.dart';
import 'package:image_picker/image_picker.dart';

// Field filter sentinels: "썸네일 템플릿 전체"(all cover groups) /
// "상세 템플릿 전체"(all detail templates).
const String _coverAll = '__cover_all__';
const String _detailAll = '__detail_all__';

// Create-mode token namespacing: file-buffer tokens are indices (0..n);
// product-reference tokens are _productOffset + productImageId so the two
// never collide in the unified token space.
const int _productOffset = 1000000000;

/// One image field (cover photo or a detail image group).
class ImageField {
  final String key;
  final String label;

  const ImageField({required this.key, required this.label});
}

/// Filter only — render order is always owned by the `fields` list.
/// [kind] = 'cover' | 'detail' (same as the web).
class ImageFieldFilter {
  final String label;
  final List<String> keys;
  final String kind;

  const ImageFieldFilter({
    required this.label,
    required this.keys,
    required this.kind,
  });
}

/// Web `MasterImageBuffer` — [files] = files to upload (order = pool order), [assignments] = field → file index,
/// [productAssignments] = field → product image id.
class MasterImageBuffer {
  final List<File> files; // dart:io
  final Map<String, List<int>> assignments;
  final Map<String, List<int>> productAssignments;

  const MasterImageBuffer({
    this.files = const [],
    this.assignments = const {},
    this.productAssignments = const {},
  });
}

/// One row of web `sourceProducts`.
class SourceProduct {
  final int id;
  final String name;

  const SourceProduct({required this.id, required this.name});
}

// A pool entry unified across modes. `token` = image id (edit) or buffer
// token (create). `file` = create-mode file entry (rendered with Image.file).
// `isReference` = the entry live-links a product gallery image.
class _PoolEntry {
  final int token;
  final String url;
  final File? file;
  final bool isReference;

  const _PoolEntry({
    required this.token,
    required this.url,
    required this.isReference,
    this.file,
  });
}

class _ProductSection {
  final int productId;
  final String name;
  final List<ProductGalleryImage> images;

  const _ProductSection({
    required this.productId,
    required this.name,
    required this.images,
  });
}

/// Master image pool + field (cover photo + detail zones) mapping — port of
/// web `app/dashboard/master-products/components/MasterImagePool.tsx`
/// (@09208a0), with the D84 interaction.
///
/// **Purpose**: shared image mapping UI of the create page, the master detail
/// 「이미지」 section and the detail editor 「구조 데이터」 tab.
/// **File**: lib/features/master_product/presentation/widgets/master_image_pool.dart
///
/// **Layout (top to bottom)**: source chips → source list (256 high, own
/// scroll) → images in use (max 176 high) → field filter row → field cards.
///
/// **Mapping (D84)**: tapping a photo (pool, product image, in use) opens a
/// field chooser sheet (R18); picking a field maps the photo there. A field
/// that already holds the photo shows a check and only closes the sheet.
/// Removing = the ✕ on the field card. The magnifier at the bottom-right of a
/// photo card opens the full-screen viewer.
///
/// **Modes**:
/// - edit ([masterId] != null): mappings and references go to the server
///   immediately.
/// - create ([masterId] == null): no server calls, only [buffer] /
///   [onBufferChange] (product photos are buffered as references and applied
///   on save by `commitMasterImageBuffer`).
///
/// **Usage**:
/// ```dart
/// // edit mode (master detail)
/// MasterImagePool(
///   masterId: master.id,
///   fields: imageFields.fields,
///   fieldFilters: imageFields.fieldFilters,
///   sourceProducts: [for (final c in master.components)
///     SourceProduct(id: c.productId, name: c.productName)],
/// )
///
/// // create mode (parent owns the buffer)
/// MasterImagePool(
///   masterId: null,
///   fields: imageFields.fields,
///   buffer: _imageBuffer,
///   onBufferChange: (next) => setState(() => _imageBuffer = next),
/// )
/// ```
///
/// ⚠️ [fields] comes from the parent (`deriveMasterImageFields` or the detail
///    editor's single template). Rendering always follows [fields] order;
///    [fieldFilters] only decides which cards are visible.
/// ⚠️ The 「제품 이미지」 tab shows only when [sourceProducts] is non-empty
///    (create mode too).
/// ❌ No per-field upload input — uploads go to the pool only.
/// ❌ No drag and drop (D84) and no sibling paging in the zoom view (R11).
class MasterImagePool extends StatefulWidget {
  final int? masterId; // null = create mode (buffer)
  final List<ImageField> fields;
  final List<ImageFieldFilter>? fieldFilters;
  final MasterImageBuffer? buffer;
  final ValueChanged<MasterImageBuffer>? onBufferChange;
  final VoidCallback? onDirty;
  final List<SourceProduct>?
      sourceProducts; // web `productImageUseCase` + `sourceProducts` — null = no 「제품 이미지」 tab

  const MasterImagePool({
    required this.masterId,
    required this.fields,
    super.key,
    this.fieldFilters,
    this.buffer,
    this.onBufferChange,
    this.onDirty,
    this.sourceProducts,
  });

  @override
  State<MasterImagePool> createState() => _MasterImagePoolState();
}

class _MasterImagePoolState extends State<MasterImagePool> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  // ---- Edit-mode server state ----
  List<MasterPoolImage> _pool = [];
  bool _isLoading = false;
  bool _busy = false;
  String _error = '';

  // Tapping an in-use card's field tag highlights that field card for 2s.
  String? _highlightedField;
  Timer? _highlightTimer;
  final Map<String, GlobalKey> _fieldCardKeys = {};

  // ---- Source tab ----
  String _activeTab = 'master'; // 'product' | 'master'
  List<_ProductSection> _productSections = [];
  bool _productLoading = false;

  // ---- Group filter (null = 전체) ----
  String? _activeGroup;

  // Drops results of superseded loads (web `alive` flag).
  int _poolLoadSeq = 0;
  int _productLoadSeq = 0;

  bool get _isEdit => widget.masterId != null;

  bool get _canUseProducts => (widget.sourceProducts?.length ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    _isLoading = _isEdit;
    _activeTab = _canUseProducts ? 'product' : 'master';
    unawaited(_loadPool(initial: true));
    unawaited(_loadProducts(initial: true));
  }

  @override
  void didUpdateWidget(covariant MasterImagePool oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.masterId != widget.masterId) {
      unawaited(_loadPool());
    }
    if (oldWidget.masterId != widget.masterId ||
        !_sameProducts(oldWidget.sourceProducts, widget.sourceProducts)) {
      unawaited(_loadProducts());
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  bool _sameProducts(List<SourceProduct>? a, List<SourceProduct>? b) {
    if (a == null || b == null) {
      return a == b;
    }
    return listEquals(a.map((p) => '${p.id}:${p.name}').toList(),
        b.map((p) => '${p.id}:${p.name}').toList());
  }

  List<MasterPoolImage> _sorted(List<MasterPoolImage> list) =>
      [...list]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  // [initial] = called from initState, where setState is not allowed yet.
  Future<void> _loadPool({bool initial = false}) async {
    final masterId = widget.masterId;
    if (masterId == null) {
      return;
    }
    final seq = ++_poolLoadSeq;
    void start() {
      _isLoading = true;
      _error = '';
    }

    if (initial) {
      start();
    } else {
      setState(start);
    }
    final result = await _useCase.listPoolImages(masterId);
    if (!mounted || seq != _poolLoadSeq) {
      return;
    }
    setState(() {
      result.fold(
        (_) => _error = '이미지 풀을 불러오지 못했습니다.',
        (list) => _pool = _sorted(list),
      );
      _isLoading = false;
    });
  }

  // ---- Load the BOM products' galleries for the "제품 이미지" tab ----
  Future<void> _loadProducts({bool initial = false}) async {
    if (!_canUseProducts) {
      return;
    }
    final seq = ++_productLoadSeq;
    if (initial) {
      _productLoading = true;
    } else {
      setState(() => _productLoading = true);
    }
    final loaded = await Future.wait(
      (widget.sourceProducts ?? const <SourceProduct>[]).map((p) async {
        final result = await _useCase.listProductImages(p.id);
        return _ProductSection(
          productId: p.id,
          name: p.name,
          images: result.fold((_) => const <ProductGalleryImage>[], (r) => r),
        );
      }),
    );
    if (!mounted || seq != _productLoadSeq) {
      return;
    }
    setState(() {
      _productSections = loaded;
      _productLoading = false;
    });
  }

  // Returns the failure (web: `reload` throws to the caller's catch).
  Future<Failure?> _reload() async {
    final masterId = widget.masterId;
    if (masterId == null) {
      return null;
    }
    final result = await _useCase.listPoolImages(masterId);
    return result.fold((f) => f, (list) {
      if (mounted) {
        setState(() => _pool = _sorted(list));
      }
      return null;
    });
  }

  // productImageId → gallery url (create-mode product refs render from this).
  Map<int, String> get _productUrlById => {
        for (final s in _productSections)
          for (final img in s.images) img.id: img.imageUrl,
      };

  // Create-mode product-reference ids mapped to any field.
  List<int> get _mappedProductIds => {
        for (final ids
            in (widget.buffer?.productAssignments ?? const {}).values)
          ...ids,
      }.toList();

  // ---- Unified pool entries ----
  List<_PoolEntry> _entriesFor(MasterImageBuffer? buffer) {
    if (_isEdit) {
      return [
        for (final img in _pool)
          _PoolEntry(
            token: img.id,
            url: img.imageUrl,
            isReference: img.productImageId != null,
          ),
      ];
    }
    // Create mode: file-buffer entries (index tokens) + mapped product refs
    // (offset tokens).
    final files = buffer?.files ?? const <File>[];
    final urls = _productUrlById;
    final productIds = {
      for (final ids in (buffer?.productAssignments ?? const {}).values) ...ids,
    };
    return [
      for (var i = 0; i < files.length; i++)
        _PoolEntry(token: i, url: '', file: files[i], isReference: false),
      for (final id in productIds)
        _PoolEntry(
          token: _productOffset + id,
          url: urls[id] ?? '',
          isReference: true,
        ),
    ];
  }

  List<_PoolEntry> get _entries => _entriesFor(widget.buffer);

  // productImageId → its pool reference entry.
  Map<int, MasterPoolImage> get _refByProductImageId => {
        for (final img in _pool)
          if (img.productImageId != null) img.productImageId!: img,
      };

  // Tokens currently mapped to a field (in mapping order).
  List<int> _fieldTokens(String fieldKey) {
    if (!_isEdit) {
      final fileToks = widget.buffer?.assignments[fieldKey] ?? const <int>[];
      final prodToks =
          (widget.buffer?.productAssignments[fieldKey] ?? const <int>[])
              .map((id) => _productOffset + id);
      return [...fileToks, ...prodToks];
    }
    if (fieldKey == kSourceZone) {
      return [
        for (final i in _pool)
          if (i.isSource) i.id,
      ];
    }
    return [
      for (final i in _pool)
        if (i.assignedZones.contains(fieldKey)) i.id,
    ];
  }

  // Fields this token is mapped to (in-use tags link to these field cards).
  List<ImageField> _fieldsForToken(int token) =>
      widget.fields.where((f) => _fieldTokens(f.key).contains(token)).toList();

  bool _inUse(int token) => _fieldsForToken(token).isNotEmpty;

  // ---- Auto-cleanup: delete product references no longer mapped anywhere ----
  Future<void> _sweepOrphanReferences() async {
    final masterId = widget.masterId;
    if (masterId == null) {
      return;
    }
    // Best-effort; leave the reference if cleanup fails.
    final fresh = await _useCase.listPoolImages(masterId);
    final orphans = fresh.fold(
      (_) => const <MasterPoolImage>[],
      (list) => list
          .where((i) =>
              i.productImageId != null &&
              !i.isSource &&
              i.assignedZones.isEmpty)
          .toList(),
    );
    if (orphans.isEmpty) {
      return;
    }
    for (final o in orphans) {
      final deleted = await _useCase.deletePoolImage(masterId, o.id);
      if (deleted.isLeft()) {
        return;
      }
    }
    await _reload();
  }

  // ---- Commit a field's mapping (edit → server, create → buffer) ----
  Future<void> _commit(String fieldKey, List<int> tokens) async {
    final isSource = fieldKey == kSourceZone;
    final capped = isSource ? tokens.take(1).toList() : tokens;
    if (!_isEdit) {
      // Split the unified tokens back into file indices and product image ids.
      final fileToks = capped.where((t) => t < _productOffset).toList();
      final prodIds = capped
          .where((t) => t >= _productOffset)
          .map((t) => t - _productOffset)
          .toList();
      final buffer = widget.buffer;
      widget.onBufferChange?.call(MasterImageBuffer(
        files: buffer?.files ?? const [],
        assignments: {...?buffer?.assignments, fieldKey: fileToks},
        productAssignments: {...?buffer?.productAssignments, fieldKey: prodIds},
      ));
      return;
    }
    final masterId = widget.masterId;
    if (masterId == null) {
      return;
    }
    setState(() {
      _error = '';
      _busy = true;
    });
    final Failure? failure;
    if (isSource) {
      failure = (await _useCase.setSourceImage(
              masterId, capped.isEmpty ? null : capped.first))
          .fold((f) => f, (_) => null);
    } else {
      failure = (await _useCase.setZoneImages(masterId, fieldKey, capped))
          .fold((f) => f, (_) => null);
    }
    final reloadFailure = failure ?? await _reload();
    if (reloadFailure == null) {
      await _sweepOrphanReferences();
      widget.onDirty?.call();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      if (reloadFailure != null) {
        _error = '매핑 변경에 실패했습니다.';
      }
      _busy = false;
    });
  }

  void _addToField(String fieldKey, int token) {
    if (fieldKey == kSourceZone) {
      unawaited(_commit(fieldKey, [token]));
      return;
    }
    final current = _fieldTokens(fieldKey);
    if (current.contains(token)) {
      return; // dedup
    }
    unawaited(_commit(fieldKey, [...current, token]));
  }

  void _removeFromField(String fieldKey, int token) {
    unawaited(_commit(
      fieldKey,
      _fieldTokens(fieldKey).where((t) => t != token).toList(),
    ));
  }

  // ---- A-flow: map a product image → auto-import a reference (if needed)
  //      then map it ----
  Future<void> _importThenMap(String fieldKey, int productImageId) async {
    final masterId = widget.masterId;
    if (masterId == null) {
      return;
    }
    setState(() {
      _error = '';
      _busy = true;
    });
    final ok = await _importThenMapSteps(masterId, fieldKey, productImageId);
    if (ok) {
      widget.onDirty?.call();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      if (!ok) {
        _error = '상품 이미지 매핑에 실패했습니다.';
      }
      _busy = false;
    });
  }

  Future<bool> _importThenMapSteps(
      int masterId, String fieldKey, int productImageId) async {
    var ref = _refByProductImageId[productImageId];
    var freshPool = _pool;
    if (ref == null) {
      final imported =
          await _useCase.importProductImages(masterId, [productImageId]);
      if (imported.isLeft()) {
        return false;
      }
      final listed = await _useCase.listPoolImages(masterId);
      final list = listed.fold((_) => null, (r) => r);
      if (list == null) {
        return false;
      }
      freshPool = _sorted(list);
      if (mounted) {
        setState(() => _pool = freshPool);
      }
      for (final i in freshPool) {
        if (i.productImageId == productImageId) {
          ref = i;
          break;
        }
      }
    }
    if (ref == null) {
      return false; // reference not found after import
    }
    // Map using the fresh pool (avoid stale field tokens after import).
    if (fieldKey == kSourceZone) {
      final set = await _useCase.setSourceImage(masterId, ref.id);
      if (set.isLeft()) {
        return false;
      }
    } else {
      final currentZoneIds = [
        for (final i in freshPool)
          if (i.assignedZones.contains(fieldKey)) i.id,
      ];
      final nextIds = currentZoneIds.contains(ref.id)
          ? currentZoneIds
          : [...currentZoneIds, ref.id];
      final set = await _useCase.setZoneImages(masterId, fieldKey, nextIds);
      if (set.isLeft()) {
        return false;
      }
    }
    if (await _reload() != null) {
      return false;
    }
    // Replacing the cover photo can orphan a previous product reference.
    await _sweepOrphanReferences();
    return true;
  }

  // ---- Upload into the master pool ----
  Future<void> _handleUpload() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty || !mounted) {
      return;
    }
    final selected = [for (final x in picked) File(x.path)];
    if (!_isEdit) {
      final buffer = widget.buffer;
      widget.onBufferChange?.call(MasterImageBuffer(
        files: [...?buffer?.files, ...selected],
        assignments: buffer?.assignments ?? const {},
        productAssignments: buffer?.productAssignments ?? const {},
      ));
      return;
    }
    final masterId = widget.masterId;
    if (masterId == null) {
      return;
    }
    setState(() {
      _error = '';
      _busy = true;
    });
    var failed = false;
    for (final file in selected) {
      final uploaded = await _useCase.uploadPoolImage(masterId, file);
      if (uploaded.isLeft()) {
        failed = true;
        break;
      }
    }
    if (!failed) {
      failed = await _reload() != null;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      if (failed) {
        _error = '이미지 업로드에 실패했습니다.';
      }
      _busy = false;
    });
  }

  // ---- Delete master-owned pool images (multi, from the manage sheet).
  //      References are auto-managed, never deleted here. Returns the fresh
  //      manage list for the open sheet. ----
  Future<List<ManageImage>> _handleDeletePoolImages(List<int> tokens) async {
    if (tokens.isEmpty) {
      return _manageImagesFor(widget.buffer);
    }
    if (!_isEdit) {
      // Buffer mode: drop the selected file indices and reindex the
      // remaining assignments.
      final remove = tokens.toSet();
      final buffer = widget.buffer;
      final files = buffer?.files ?? const <File>[];
      final kept = [
        for (var i = 0; i < files.length; i++)
          if (!remove.contains(i)) i,
      ];
      final remap = {
        for (var newIdx = 0; newIdx < kept.length; newIdx++)
          kept[newIdx]: newIdx,
      };
      final next = MasterImageBuffer(
        files: [for (final i in kept) files[i]],
        assignments: {
          for (final e in (buffer?.assignments ?? const {}).entries)
            e.key: [
              for (final t in e.value)
                if (!remove.contains(t)) remap[t]!,
            ],
        },
        // Product refs are keyed by productImageId (not file index) →
        // unaffected by file removal.
        productAssignments: buffer?.productAssignments ?? const {},
      );
      widget.onBufferChange?.call(next);
      return _manageImagesFor(next);
    }
    final masterId = widget.masterId;
    if (masterId == null) {
      return _manageImagesFor(widget.buffer);
    }
    setState(() {
      _error = '';
      _busy = true;
    });
    var failed = false;
    for (final token in tokens) {
      final deleted = await _useCase.deletePoolImage(masterId, token);
      if (deleted.isLeft()) {
        failed = true;
        break;
      }
    }
    if (!failed) {
      failed = await _reload() != null;
      if (!failed) {
        widget.onDirty?.call();
      }
    }
    if (mounted) {
      setState(() {
        if (failed) {
          _error = '이미지 삭제에 실패했습니다.';
        }
        _busy = false;
      });
    }
    return _manageImagesFor(widget.buffer);
  }

  // Master-owned entries for the manage sheet. In create mode `inUse` reads
  // the given buffer's assignments.
  List<ManageImage> _manageImagesFor(MasterImageBuffer? buffer) {
    bool inUse(int token) {
      if (_isEdit) {
        return _inUse(token);
      }
      return widget.fields.any(
          (f) => (buffer?.assignments[f.key] ?? const <int>[]).contains(token));
    }

    return [
      for (final e in _entriesFor(buffer))
        if (!e.isReference)
          ManageImage(
            token: e.token,
            url: e.url,
            file: e.file,
            inUse: inUse(e.token),
          ),
    ];
  }

  // ---- D84: pick the field a photo goes into ----
  Future<void> _chooseField({
    required bool Function(String fieldKey) alreadyIn,
    required void Function(String fieldKey) onPick,
  }) async {
    final picked = await showAppSheet<String>(
      context,
      builder: (sheetContext) => _FieldChooserSheet(
        fields: widget.fields,
        alreadyIn: alreadyIn,
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    onPick(picked);
  }

  void _choosePoolEntryField(_PoolEntry entry) {
    unawaited(_chooseField(
      alreadyIn: (key) => _fieldTokens(key).contains(entry.token),
      onPick: (key) => _addToField(key, entry.token),
    ));
  }

  void _chooseProductImageField(ProductGalleryImage pi) {
    if (!_isEdit) {
      final token = _productOffset + pi.id;
      unawaited(_chooseField(
        alreadyIn: (key) => _fieldTokens(key).contains(token),
        onPick: (key) => _addToField(key, token),
      ));
      return;
    }
    // Edit reuses an existing reference's pool id when present; otherwise
    // import a reference then map it.
    final ref = _refByProductImageId[pi.id];
    unawaited(_chooseField(
      alreadyIn: (key) => ref != null && _fieldTokens(key).contains(ref.id),
      onPick: (key) {
        final current = _refByProductImageId[pi.id];
        if (current != null) {
          _addToField(key, current.id);
        } else {
          unawaited(_importThenMap(key, pi.id));
        }
      },
    ));
  }

  // ---- [선택] picker (pool entries only) ----
  Future<void> _openPicker(ImageField field) async {
    final tokens = await showAppSheet<List<int>>(
      context,
      builder: (sheetContext) => MasterImagePickerSheet(
        fieldLabel: field.label,
        single: field.key == kSourceZone,
        images: [
          for (final e in _entries)
            PickerImage(token: e.token, url: e.url, file: e.file),
        ],
        initialSelected: _fieldTokens(field.key),
      ),
    );
    if (tokens == null || !mounted) {
      return;
    }
    await _commit(field.key, tokens);
  }

  // ---- [이미지 관리] sheet ----
  Future<void> _openManage() async {
    await showAppSheet<void>(
      context,
      builder: (sheetContext) => MasterPoolManageSheet(
        images: _manageImagesFor(widget.buffer),
        onDelete: _handleDeletePoolImages,
      ),
    );
  }

  // ---- Field filter ----
  List<ImageFieldFilter> get _coverFilters => (widget.fieldFilters ?? const [])
      .where((f) => f.kind == 'cover')
      .toList();

  List<ImageFieldFilter> get _detailFilters => (widget.fieldFilters ?? const [])
      .where((f) => f.kind == 'detail')
      .toList();

  Set<String>? get _visibleKeys {
    Set<String> keysOf(Iterable<ImageFieldFilter> filters) =>
        {for (final f in filters) ...f.keys};
    final group = _activeGroup;
    if (group == null) {
      return null; // 전체
    }
    if (group == _coverAll) {
      return keysOf(_coverFilters);
    }
    if (group == _detailAll) {
      return keysOf(_detailFilters);
    }
    return keysOf(
        (widget.fieldFilters ?? const []).where((f) => f.label == group));
  }

  // Reveal a field card (switch the filter to 전체 when it is hidden),
  // scroll to it and highlight it for 2s.
  void _highlightField(String fieldKey) {
    final visible = _visibleKeys;
    setState(() {
      if (visible != null && !visible.contains(fieldKey)) {
        _activeGroup = null; // 전체 → ensure the target card is rendered
      }
      _highlightedField = fieldKey;
    });
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _highlightedField = null);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _fieldCardKeys[fieldKey]?.currentContext;
      if (target != null && target.mounted) {
        unawaited(Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 300),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ));
      }
    });
  }

  ImageProvider? _providerOf(String url, File? file) {
    if (file != null) {
      return FileImage(file);
    }
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    return null;
  }

  Widget _photo(BuildContext context, String url, File? file, {double? size}) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: file != null
          ? Image.file(
              file,
              width: size ?? double.infinity,
              height: size ?? double.infinity,
              fit: BoxFit.contain,
            )
          : MasterNetworkImage(
              url: url,
              width: size ?? double.infinity,
              height: size ?? double.infinity,
            ),
    );
  }

  // Square photo: tap = field chooser sheet, magnifier = full-screen view.
  Widget _tappablePhoto(BuildContext context,
      {required String url,
      required File? file,
      required VoidCallback onTap,
      String? badge}) {
    final provider = _providerOf(url, file);
    final tappable = GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: _photo(context, url, file),
        ),
      ),
    );
    return Stack(
      children: [
        if (provider != null)
          ImageWithZoomButton(
            image: provider,
            tapImageToZoom: false,
            child: tappable,
          )
        else
          tappable,
        if (badge != null)
          Positioned(
            top: 4,
            left: 4,
            child: _inUseBadge(badge),
          ),
      ],
    );
  }

  Widget _inUseBadge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.infoForeground,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style:
              const TextStyle(fontSize: 10, color: AppColors.backgroundLight),
        ),
      );

  // One pool card. Deletion lives in the [이미지 관리] sheet, not per card.
  //  - fieldTags = true: field-location chips (in-use view).
  //  - fieldTags = false: single "사용중" badge (마스터 이미지 풀 tab).
  Widget _poolCard(BuildContext context, _PoolEntry entry,
      {required bool fieldTags}) {
    final scheme = Theme.of(context).colorScheme;
    final tagFields = _fieldsForToken(entry.token);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tappablePhoto(
            context,
            url: entry.url,
            file: entry.file,
            onTap: () => _choosePoolEntryField(entry),
            badge: !fieldTags && tagFields.isNotEmpty ? '사용중' : null,
          ),
          if (fieldTags && tagFields.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final f in tagFields)
                  GestureDetector(
                    onTap: () => _highlightField(f.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.infoSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        f.label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.infoForeground,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // One product-gallery image card (제품 이미지 tab).
  Widget _productImageCard(BuildContext context, ProductGalleryImage pi) {
    final scheme = Theme.of(context).colorScheme;
    final bool inUse;
    if (_isEdit) {
      final ref = _refByProductImageId[pi.id];
      inUse = ref != null && (ref.isSource || ref.assignedZones.isNotEmpty);
    } else {
      inUse = _mappedProductIds.contains(pi.id);
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: _tappablePhoto(
        context,
        url: pi.imageUrl,
        file: null,
        onTap: () => _chooseProductImageField(pi),
        badge: inUse ? '사용중' : null,
      ),
    );
  }

  // Cards with content under the photo: fixed-width cards in a Wrap (R27 ③).
  Widget _cardWrap(List<Widget> cards, {int columns = 3, double gap = 8}) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final w = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final c in cards) SizedBox(width: w, child: c),
            ],
          );
        },
      );

  Widget _chip(BuildContext context, String label, bool selected,
          VoidCallback onTap) =>
      ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
        selectedColor: AppColors.infoSurface,
      );

  Widget _loadingRow(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _emptyText(BuildContext context, String text, {double pad = 24}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: pad),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _sourceBox(BuildContext context, List<_PoolEntry> masterEntries) {
    final scheme = Theme.of(context).colorScheme;
    final productEmpty = _productSections.every((s) => s.images.isEmpty);
    final Widget list;
    if (_activeTab == 'product') {
      if (_productLoading) {
        list = _loadingRow(context, '상품 이미지 불러오는 중...');
      } else if (productEmpty) {
        list = _emptyText(context, '구성상품에 등록된 이미지가 없습니다.');
      } else {
        list = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _productSections.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Text(
                _productSections[i].name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              if (_productSections[i].images.isEmpty)
                Text('이미지 없음',
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))
              else
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    for (final pi in _productSections[i].images)
                      _productImageCard(context, pi),
                  ],
                ),
            ],
          ],
        );
      }
    } else if (masterEntries.isEmpty) {
      list = _emptyText(context, '[이미지 업로드]로 마스터 전용 이미지를 추가하세요.');
    } else {
      list = _cardWrap([
        for (final e in masterEntries) _poolCard(context, e, fieldTags: false),
      ]);
    }
    return Container(
      height: 256,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_activeTab == 'master') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _busy || masterEntries.isEmpty
                      ? null
                      : () => unawaited(_openManage()),
                  style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                  child: const Text('이미지 관리', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: _busy ? null : () => unawaited(_handleUpload()),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.infoForeground,
                  ),
                  child: const Text('이미지 업로드', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Expanded(child: SingleChildScrollView(child: list)),
        ],
      ),
    );
  }

  Widget _activeBox(BuildContext context, List<_PoolEntry> activeEntries) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '사용 중인 이미지',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 176),
            child: SingleChildScrollView(
              child: activeEntries.isEmpty
                  ? _emptyText(
                      context,
                      '사용중인 이미지가 없습니다. 위 소스의 사진을 눌러 칸을 고르세요.',
                      pad: 16,
                    )
                  : _cardWrap([
                      for (final e in activeEntries)
                        _poolCard(context, e, fieldTags: true),
                    ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown(BuildContext context,
      {required String hint,
      required String allValue,
      required String allLabel,
      required List<ImageFieldFilter> filters,
      required bool current}) {
    final scheme = Theme.of(context).colorScheme;
    final labels = <String>[];
    for (final f in filters) {
      if (!labels.contains(f.label)) {
        labels.add(f.label);
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: current ? AppColors.infoSurface : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: current ? AppColors.infoForeground : scheme.outline,
        ),
      ),
      child: DropdownButton<String>(
        value: current ? _activeGroup : null,
        hint: Text(hint, style: const TextStyle(fontSize: 11)),
        underline: const SizedBox.shrink(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: current ? AppColors.infoForeground : scheme.onSurface,
        ),
        items: [
          DropdownMenuItem(value: allValue, child: Text(allLabel)),
          for (final l in labels) DropdownMenuItem(value: l, child: Text(l)),
        ],
        onChanged: (v) => setState(() => _activeGroup = v),
      ),
    );
  }

  Widget _filterRow(BuildContext context) {
    final coverFilters = _coverFilters;
    final detailFilters = _detailFilters;
    final group = _activeGroup;
    final coverCurrent =
        group == _coverAll || coverFilters.any((f) => f.label == group);
    final detailCurrent =
        group == _detailAll || detailFilters.any((f) => f.label == group);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _chip(context, '전체', group == null,
            () => setState(() => _activeGroup = null)),
        if (coverFilters.isNotEmpty)
          _filterDropdown(
            context,
            hint: '썸네일 템플릿',
            allValue: _coverAll,
            allLabel: '썸네일 템플릿 전체',
            filters: coverFilters,
            current: coverCurrent,
          ),
        if (detailFilters.isNotEmpty)
          _filterDropdown(
            context,
            hint: '상세 템플릿',
            allValue: _detailAll,
            allLabel: '상세 템플릿 전체',
            filters: detailFilters,
            current: detailCurrent,
          ),
      ],
    );
  }

  // One field card.
  Widget _fieldCard(BuildContext context, ImageField field,
      Map<int, _PoolEntry> entryByToken) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = _fieldTokens(field.key);
    final isSource = field.key == kSourceZone;
    final highlighted = field.key == _highlightedField;
    final key = _fieldCardKeys.putIfAbsent(field.key, GlobalKey.new);
    final mapped = [
      for (final t in tokens)
        if (entryByToken[t] != null) entryByToken[t]!,
    ];
    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.warningSurface : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted ? AppColors.warningBorder : scheme.outlineVariant,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: field.label,
                    children: [
                      if (isSource)
                        TextSpan(
                          text: ' (단일)',
                          style: TextStyle(color: scheme.outline),
                        ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: _busy ? null : () => unawaited(_openPicker(field)),
                style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact),
                child: const Text('선택', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (tokens.isEmpty)
            _emptyText(context, '사진을 눌러 칸을 고르거나 [선택]으로 매핑하세요.', pad: 12)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in mapped)
                  _mappedThumb(context, field.key, entry),
              ],
            ),
        ],
      ),
    );
  }

  Widget _mappedThumb(BuildContext context, String fieldKey, _PoolEntry entry) {
    final scheme = Theme.of(context).colorScheme;
    final provider = _providerOf(entry.url, entry.file);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: provider == null
                    ? null
                    : () => unawaited(
                        ZoomableImageViewer.show(context, image: provider)),
                child: _photo(context, entry.url, entry.file),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Material(
                color: scheme.error,
                child: InkWell(
                  onTap: _busy
                      ? null
                      : () => _removeFromField(fieldKey, entry.token),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: Center(
                      child: Text(
                        '✕',
                        style: TextStyle(fontSize: 10, color: scheme.onError),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_isEdit && _isLoading) {
      return Container(
        constraints: const BoxConstraints(minHeight: 96),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Center(child: _loadingRow(context, '이미지 풀 불러오는 중...')),
      );
    }

    final entries = _entries;
    final entryByToken = {for (final e in entries) e.token: e};
    final activeEntries = entries.where((e) => _inUse(e.token)).toList();
    final masterEntries = entries.where((e) => !e.isReference).toList();
    final visibleKeys = _visibleKeys;
    final visibleFields = visibleKeys == null
        ? widget.fields
        : widget.fields.where((f) => visibleKeys.contains(f.key)).toList();
    final hasFilters = (widget.fieldFilters?.length ?? 0) > 0;

    final children = <Widget>[
      if (_error.isNotEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child:
              Text(_error, style: TextStyle(fontSize: 12, color: scheme.error)),
        ),
      // Source chips.
      Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (_canUseProducts)
            _chip(context, '제품 이미지', _activeTab == 'product',
                () => setState(() => _activeTab = 'product')),
          _chip(context, '마스터 이미지 풀', _activeTab == 'master',
              () => setState(() => _activeTab = 'master')),
        ],
      ),
      _sourceBox(context, masterEntries),
      _activeBox(context, activeEntries),
      if (hasFilters) _filterRow(context),
      // Field cards stay in the parent's scroll flow.
      for (var i = 0; i < visibleFields.length; i++)
        _fieldCard(context, visibleFields[i], entryByToken),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          children[i],
        ],
      ],
    );
  }
}

// D84 sheet: one row per field; a field already holding the photo shows a
// check and only closes the sheet.
class _FieldChooserSheet extends StatelessWidget {
  final List<ImageField> fields;
  final bool Function(String fieldKey) alreadyIn;

  const _FieldChooserSheet({required this.fields, required this.alreadyIn});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            '넣을 칸 고르기',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Expanded(
          child: ListView(
            children: [
              for (final f in fields)
                ListTile(
                  title: Text(f.label + (f.key == kSourceZone ? ' (단일)' : '')),
                  trailing: alreadyIn(f.key) ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context)
                      .pop(alreadyIn(f.key) ? null : f.key),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
