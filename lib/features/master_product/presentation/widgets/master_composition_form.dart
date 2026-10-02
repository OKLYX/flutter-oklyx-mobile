import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/quantity_stepper.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/widgets/product_thumbnail.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';

// Option lock notice (85 -> 2609_74). The lock only blocks deletion; decided by
// the backend flag (marketRegistered) alone.
const String _lockedDeleteReason = '쿠팡에 등록돼 판매 중 — 삭제할 수 없습니다.';

const int _productSearchLimit = 50;

String _formatWon(int? v) => v == null ? '—' : '${koNumber(v)}원';

/// One option edit buffer row (web `OptionDraft`).
/// Existing options carry [optionId]; options added on screen do not (the
/// server creates them).
class _OptionDraft {
  /// Existing = `o{optionId}`, new = `n{seq}`.
  final String key;
  final int? optionId;
  final String name;

  /// master.options[].marketRegistered
  final bool locked;

  /// productId -> typed string.
  final Map<int, String> qty;

  const _OptionDraft({
    required this.key,
    required this.name,
    required this.locked,
    required this.qty,
    this.optionId,
  });

  _OptionDraft copyWith({String? name, Map<int, String>? qty}) => _OptionDraft(
        key: key,
        optionId: optionId,
        name: name ?? this.name,
        locked: locked,
        qty: qty ?? this.qty,
      );
}

/// Form that saves components + option quantities **at once**
/// (FEATURE_2609_80 / 05 — web
/// `master-products/[id]/composition/components/MasterCompositionForm.tsx`
/// @09208a0, 2609_64).
///
/// **File**: lib/features/master_product/presentation/widgets/master_composition_form.dart
///
/// The component set and each option's quantity vector validate each other
/// (set equality), so neither can be saved alone. This form buffers both and
/// sends them in one `PUT /{id}/composition`.
///
/// **Usage**:
/// ```dart
/// MasterCompositionForm(
///   master: master,
///   products: products,
///   onSaved: _toDetail,
///   onCancel: _toDetail,
/// )
/// ```
///
/// ⚠️ An edit state with 0 options is allowed (clearing and refilling is the
///    point of this screen). Only the save button is blocked.
/// ❌ Option shipping/box/category attributes/notices/stock are not edited
///    here — that belongs to the detail [옵션].
/// ❌ No horizontal-scroll grid — one card per option (PLAN R7).
class MasterCompositionForm extends StatefulWidget {
  final MasterProduct master;
  final List<Product> products;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  const MasterCompositionForm({
    required this.master,
    required this.products,
    required this.onSaved,
    required this.onCancel,
    super.key,
  });

  @override
  State<MasterCompositionForm> createState() => _MasterCompositionFormState();
}

class _MasterCompositionFormState extends State<MasterCompositionForm> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();
  final TextEditingController _productFilterController =
      TextEditingController();

  /// Option name controllers keyed by draft key (PLAN R2).
  final Map<String, TextEditingController> _nameControllers = {};

  List<int> _selectedIds = [];
  List<_OptionDraft> _drafts = [];
  int _newOptionSeq = 0;

  String _productQuery = '';
  bool _productHasSearched = false;

  bool _isSaving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.master.components.map((c) => c.productId).toList();
    _drafts = widget.master.options
        .map((o) => _OptionDraft(
              key: 'o${o.id}',
              optionId: o.id,
              name: o.name,
              locked: o.marketRegistered == true,
              qty: {
                for (final it in o.items) it.productId: '${it.quantity}',
              },
            ))
        .toList();
    for (final d in _drafts) {
      _nameControllers[d.key] = TextEditingController(text: d.name);
    }
  }

  @override
  void dispose() {
    _productFilterController.dispose();
    for (final c in _nameControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Display names. Newly picked products are in `products`; original
  // components are in master.components.
  Map<int, String> get _nameMap {
    final map = <int, String>{};
    for (final c in widget.master.components) {
      map[c.productId] = c.productName;
    }
    for (final p in widget.products) {
      map[p.id] = p.productName;
    }
    return map;
  }

  String _nameOf(int id) => _nameMap[id] ?? '#$id';

  Map<int, Product> get _productById =>
      {for (final p in widget.products) p.id: p};

  List<Product> get _filteredProducts {
    final q = _productQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return widget.products;
    }
    return widget.products
        .where((p) => p.productName.toLowerCase().contains(q))
        .toList();
  }

  // Search results = not yet picked only (picked ones show below).
  List<Product> get _searchMatches {
    final selected = _selectedIds.toSet();
    return _filteredProducts.where((p) => !selected.contains(p.id)).toList();
  }

  // Existing options missing from the request = deleted on save. Keep the
  // originals so they can be restored.
  List<MasterOption> get _removedOptions => widget.master.options
      .where((o) => !_drafts.any((d) => d.optionId == o.id))
      .toList();

  void _handleProductSearch() {
    final filter = _productFilterController.text;
    if (filter.trim().isEmpty) {
      return;
    }
    setState(() {
      _productQuery = filter;
      _productHasSearched = true;
    });
  }

  // Adding/removing a component must also update every draft's quantity
  // vector — otherwise the backend returns 400 (an option must cover the whole
  // component set).
  void _addComponent(int productId) {
    setState(() {
      if (!_selectedIds.contains(productId)) {
        _selectedIds = [..._selectedIds, productId];
      }
      _drafts = _drafts
          .map((d) => d.qty[productId] == null
              ? d.copyWith(qty: {...d.qty, productId: '1'})
              : d)
          .toList();
      _error = '';
    });
  }

  void _removeComponent(int productId) {
    setState(() {
      _selectedIds = _selectedIds.where((x) => x != productId).toList();
      _drafts = _drafts.map((d) {
        final qty = {...d.qty}..remove(productId);
        return d.copyWith(qty: qty);
      }).toList();
      _error = '';
    });
  }

  void _setDraftName(String key, String name) {
    setState(() {
      _drafts = _drafts
          .map((d) => d.key == key ? d.copyWith(name: name) : d)
          .toList();
    });
  }

  void _setDraftQty(String key, int productId, String value) {
    setState(() {
      _drafts = _drafts
          .map((d) =>
              d.key == key ? d.copyWith(qty: {...d.qty, productId: value}) : d)
          .toList();
    });
  }

  void _removeDraft(String key) {
    setState(() {
      _drafts = _drafts.where((d) => d.key != key).toList();
    });
    _nameControllers.remove(key)?.dispose();
  }

  void _addDraft() {
    final key = 'n$_newOptionSeq';
    _nameControllers[key] = TextEditingController();
    setState(() {
      _drafts = [
        ..._drafts,
        _OptionDraft(
          key: key,
          name: '',
          locked: false,
          qty: {for (final pid in _selectedIds) pid: '1'},
        ),
      ];
      _newOptionSeq += 1;
    });
  }

  // Restore an option marked for deletion — quantities are rebuilt on the
  // **current component set** (remaining products keep their original
  // quantity, new ones get '1').
  void _restoreOption(int optionId) {
    final matches = widget.master.options.where((o) => o.id == optionId);
    if (matches.isEmpty) {
      return;
    }
    final original = matches.first;
    final originalQty = {
      for (final it in original.items) it.productId: it.quantity,
    };
    final key = 'o${original.id}';
    _nameControllers[key]?.dispose();
    _nameControllers[key] = TextEditingController(text: original.name);
    setState(() {
      _drafts = [
        ..._drafts,
        _OptionDraft(
          key: key,
          optionId: original.id,
          name: original.name,
          locked: original.marketRegistered == true,
          qty: {
            for (final pid in _selectedIds) pid: '${originalQty[pid] ?? 1}',
          },
        ),
      ];
    });
  }

  String get _blockReason {
    if (_selectedIds.isEmpty) {
      return '구성상품을 1개 이상 선택하세요.';
    }
    if (_drafts.isEmpty) {
      return '옵션을 1개 이상 남겨야 저장할 수 있습니다.';
    }
    if (_drafts.any((d) => d.name.trim() == '')) {
      return '옵션 이름을 입력하세요.';
    }
    if (_drafts.any((d) =>
        _selectedIds.any((pid) => (int.tryParse(d.qty[pid] ?? '') ?? 0) < 1))) {
      return '모든 수량은 1 이상이어야 합니다.';
    }
    return '';
  }

  Future<void> _openConfirm() async {
    final originalNames =
        widget.master.components.map((c) => c.productName).toList();
    final nextNames = _selectedIds.map(_nameOf).toList();
    final deletedNames = _removedOptions.map((o) => o.name).toList();
    final originalText =
        originalNames.isEmpty ? '없음' : originalNames.join(', ');
    final nextText = nextNames.isEmpty ? '없음' : nextNames.join(', ');
    final deletedText = deletedNames.isNotEmpty
        ? ' 옵션 ${deletedNames.join(', ')} 가 삭제됩니다 — 채널에서는 꺼지고 기록은 남습니다.'
        : '';
    final ok = await showAppConfirmDialog(
      context,
      title: '구성상품 변경',
      confirmText: '저장',
      message: '구성상품이 $originalText → $nextText 로 바뀝니다.\n\n'
          '옵션 ${_drafts.length}개의 구성 수량이 함께 저장됩니다.$deletedText\n\n'
          '이 마스터에 연결된 판매상품의 구성·원가·판매가가 다시 계산됩니다. '
          '쿠팡에는 자동으로 전송되지 않습니다 — 필요하면 상세에서 [수정 요청]을 누르세요.',
    );
    if (!ok || !mounted) {
      return;
    }
    await _handleSave();
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _error = '';
    });
    final result = await _useCase.updateComposition(
      widget.master.id,
      MasterCompositionRequest(
        componentProductIds: _selectedIds,
        options: _drafts
            .map((d) => MasterCompositionOptionSpec(
                  optionId: d.optionId,
                  name: d.name.trim(),
                  items: _selectedIds
                      .map((pid) => MasterOptionRequestItem(
                            productId: pid,
                            quantity: int.parse(d.qty[pid]!),
                          ))
                      .toList(),
                ))
            .toList(),
      ),
    );
    if (!mounted) {
      return;
    }
    result.fold(
      // Show the backend text as-is — locked options, duplicate component
      // sets and quantity mismatches explain themselves there.
      (f) => setState(() {
        _error = failureText(f, '저장에 실패했습니다.');
        _isSaving = false;
      }),
      (_) => widget.onSaved(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blockReason = _blockReason;
    final canSave = blockReason == '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _error,
              style: TextStyle(fontSize: 14, color: scheme.error),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildComponentSection(scheme),
        const SizedBox(height: 24),
        _buildOptionSection(scheme),
        const SizedBox(height: 24),
        _buildSaveSection(scheme, canSave, blockReason),
      ],
    );
  }

  Widget _buildComponentSection(ColorScheme scheme) {
    final searchMatches = _searchMatches;
    final searchResults = searchMatches.take(_productSearchLimit).toList();
    final productById = _productById;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '구성상품 (${_selectedIds.length}개 선택)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _productFilterController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _handleProductSearch(),
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '상품명으로 검색',
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _productFilterController,
              builder: (context, value, _) => FilledButton(
                onPressed:
                    value.text.trim().isEmpty ? null : _handleProductSearch,
                child: const Text('검색'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_productHasSearched) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: searchResults.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Text(
                            '검색 결과가 없습니다.',
                            style: TextStyle(
                              fontSize: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: searchResults.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final p = searchResults[index];
                            return ListTile(
                              dense: true,
                              leading:
                                  ProductThumbnail(productId: p.id, size: 40),
                              title: Text(p.productName),
                              subtitle: Text(
                                '${p.brand ?? '—'} · ${_formatWon(p.price)}',
                              ),
                              onTap: () => _addComponent(p.id),
                            );
                          },
                        ),
                ),
                if (searchMatches.length > searchResults.length) ...[
                  const Divider(height: 1),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      '${searchMatches.length}개 중 ${searchResults.length}개 표시 — 더 구체적으로 검색하세요.',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          '검색 결과에서 선택하면 아래 목록에 추가됩니다. 추가·제거하면 모든 옵션의 수량 칸이 함께 바뀝니다.',
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (_selectedIds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '선택된 상품이 없습니다.',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          )
        else
          for (final pid in _selectedIds)
            _buildSelectedCard(pid, productById[pid], scheme),
      ],
    );
  }

  Widget _buildSelectedCard(int pid, Product? p, ColorScheme scheme) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (p != null)
                ProductThumbnail(productId: pid, size: 40)
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameOf(pid),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text('브랜드: ${p?.brand ?? '—'}'),
                    Text('가격: ${_formatWon(p?.price)}'),
                  ],
                ),
              ),
              IconButton(
                tooltip: '구성상품 제거',
                icon: Icon(Icons.close, size: 18, color: scheme.error),
                onPressed: () => _removeComponent(pid),
              ),
            ],
          ),
        ),
      );

  Widget _buildOptionSection(ColorScheme scheme) {
    final removedOptions = _removedOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '옵션 × 구성상품 수량 (${_drafts.length}개 옵션)',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '쿠팡에 등록돼 판매 중인 옵션은 이름 수정·삭제가 막혀 있고, 구성 수량은 수정할 수 있습니다.',
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (_drafts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '옵션이 없습니다. [옵션 추가]로 만드세요.',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          )
        else
          for (final d in _drafts) _buildDraftCard(d),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              onPressed: _addDraft,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('옵션 추가', style: TextStyle(fontSize: 12)),
            ),
            Text(
              '여기서 추가한 옵션은 이름과 수량만 갖습니다. 배송·박스·카테고리 속성·고시·재고는 저장 후 상세의 [옵션 (수량조합)]에서 채우세요.',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        if (removedOptions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '삭제될 옵션: ${removedOptions.map((o) => o.name).join(' · ')} — 저장하면 채널에서 꺼지고(행·기록은 유지) 마스터에서 사라집니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in removedOptions)
                      OutlinedButton(
                        onPressed: () => _restoreOption(o.id),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          '${o.name} 되돌리기',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDraftCard(_OptionDraft d) {
    final controller = _nameControllers[d.key];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: (v) => _setDraftName(d.key, v),
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: '옵션명',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '옵션 제거',
                  icon: const Icon(Icons.close, size: 18),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: d.locked ? null : () => _removeDraft(d.key),
                ),
                if (d.locked)
                  const InfoBubbleIcon(message: _lockedDeleteReason),
              ],
            ),
            for (final pid in _selectedIds) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(_nameOf(pid))),
                  const SizedBox(width: 8),
                  // Locked options keep editable quantities — quantity is our
                  // ledger, not owned by the marketplace.
                  QuantityStepper(
                    value: d.qty[pid] ?? '',
                    onChanged: (next) => _setDraftQty(d.key, pid, next),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveSection(
          ColorScheme scheme, bool canSave, String blockReason) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(
                onPressed: !canSave || _isSaving ? null : _openConfirm,
                child: _isSaving
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('저장 중…'),
                        ],
                      )
                    : const Text('저장'),
              ),
              OutlinedButton(
                onPressed: _isSaving ? null : widget.onCancel,
                child: const Text('취소'),
              ),
            ],
          ),
          if (!canSave) ...[
            const SizedBox(height: 4),
            Text(
              blockReason,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.warningForeground,
              ),
            ),
          ],
          if (_isSaving) ...[
            const SizedBox(height: 4),
            Text(
              '연결된 판매상품의 구성·원가·판매가와 상세·썸네일을 다시 만드는 중입니다. 채널이 많으면 몇 초 걸립니다.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      );
}
