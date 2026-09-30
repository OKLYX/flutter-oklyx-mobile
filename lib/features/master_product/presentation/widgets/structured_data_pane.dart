import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_image_pool.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_network_image.dart';

/// Tab 2 — structured data editing (plain block list, not WYSIWYG).
/// FEATURE_2609_80 / 06.
///
/// **File**: lib/features/master_product/presentation/widgets/structured_data_pane.dart
/// **Web original**: `master-products/[id]/detail/[listingId]/components/StructuredDataPane.tsx` @09208a0
///
/// ⚠️ Text values = channel (listing) override (updateListingFieldValues, this channel only).
/// ⚠️ Zone images = master-owned (shared by every channel of the master; a regenerate reflects them everywhere).
/// ⚠️ Zone images use [MasterImagePool] (D84 — tap a photo, pick the field in a bottom sheet).
class StructuredDataPane extends StatefulWidget {
  final int masterId;
  final int listingId;
  final DetailTemplate template;
  final GeneratedProduct generated;
  final ValueChanged<GeneratedProduct> onGenerated;

  const StructuredDataPane({
    required this.masterId,
    required this.listingId,
    required this.template,
    required this.generated,
    required this.onGenerated,
    super.key,
  });

  @override
  State<StructuredDataPane> createState() => _StructuredDataPaneState();
}

class _StructuredDataPaneState extends State<StructuredDataPane> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  Map<String, String> _draft = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _zoneDirty = false;
  bool _isSaving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _draft = {...widget.generated.fieldValues};
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant StructuredDataPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.template, widget.template)) {
      _syncControllers();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// One controller per bound text key (R2 — never created in build).
  void _syncControllers() {
    for (final block in widget.template.blocks) {
      final key = block.bind;
      if (block.type == 'text' &&
          key != null &&
          !_controllers.containsKey(key)) {
        _controllers[key] = TextEditingController(text: _draft[key] ?? '');
      }
    }
  }

  /// Web `JSON.stringify(a) !== JSON.stringify(b)` (key order included).
  bool _differs(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) {
      return true;
    }
    final ea = a.entries.toList();
    final eb = b.entries.toList();
    for (var i = 0; i < ea.length; i++) {
      if (ea[i].key != eb[i].key || ea[i].value != eb[i].value) {
        return true;
      }
    }
    return false;
  }

  bool get _textDirty => _differs(_draft, widget.generated.fieldValues);

  bool get _canSave => _textDirty || _zoneDirty;

  // Detail zones only (no cover-photo field — that lives in the master form).
  List<ImageField> get _zoneFields => [
        for (final b in widget.template.blocks)
          if (b.type == 'imageZone' && b.bind != null && b.bind!.isNotEmpty)
            ImageField(key: b.bind!, label: b.bind!),
      ];

  Future<void> _handleSave() async {
    if (!_canSave) {
      return;
    }
    if (widget.generated.source == GeneratedSourceCode.manualOverride) {
      final ok = await showMasterConfirmDialog(
        context,
        message: '수동 수정본이 유지되고 썸네일·판매가만 갱신됩니다. 계속하시겠습니까?',
        confirmText: '계속',
      );
      if (!ok || !mounted) {
        return;
      }
    }
    setState(() {
      _isSaving = true;
      _error = '';
    });
    final result = _textDirty
        // Omit blank keys so the backend keeps product/template fallbacks.
        // This call also regenerates, so pending zone changes are picked up too.
        ? await _useCase.updateListingFieldValues(
            widget.listingId,
            {
              for (final e in _draft.entries)
                if (e.value.trim().isNotEmpty) e.key: e.value,
            },
          )
        // Only zone images changed (already saved server-side) → regenerate to reflect.
        : await _useCase.regenerate(widget.listingId);
    if (!mounted) {
      return;
    }
    result.fold(
      (_) => setState(() {
        _error = '저장에 실패했습니다.';
        _isSaving = false;
      }),
      (res) {
        widget.onGenerated(res);
        setState(() {
          _draft = {...res.fieldValues};
          for (final entry in _controllers.entries) {
            final next = _draft[entry.key] ?? '';
            if (entry.value.text != next) {
              entry.value.text = next;
            }
          }
          _zoneDirty = false;
          _isSaving = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hintStyle = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    final zoneFields = _zoneFields;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('· 텍스트값은 이 채널에만 적용됩니다(다른 채널에 영향 없음).', style: hintStyle),
        const SizedBox(height: 4),
        Text(
          '· zone 이미지는 마스터 공유 → 재생성 시 같은 마스터의 다른 채널에도 반영됩니다.',
          style: hintStyle,
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
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
        ],
        for (final block in widget.template.blocks)
          ..._blockWidgets(block, scheme),
        if (zoneFields.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('상세페이지 이미지 (마스터 공유)', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          MasterImagePool(
            masterId: widget.masterId,
            fields: zoneFields,
            onDirty: () => setState(() => _zoneDirty = true),
          ),
        ],
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: !_canSave || _isSaving ? null : _handleSave,
          child:
              _isSaving ? const _BusyLabel('저장 중...') : const Text('저장 및 재생성'),
        ),
      ],
    );
  }

  List<Widget> _blockWidgets(DetailBlock block, ColorScheme scheme) {
    final key = block.bind;
    if (block.type == 'text' && key != null && key.isNotEmpty) {
      final controller = _controllers[key];
      if (controller == null) {
        return const [];
      }
      return [
        const SizedBox(height: 16),
        Text(key, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: block.defaultValue ?? '(상품정보에서 파생)',
          ),
          onChanged: (value) =>
              setState(() => _draft = {..._draft, key: value}),
        ),
      ];
    }
    // imageZone blocks render together in one MasterImagePool below.
    if (block.type == 'asset' && block.src != null && block.src!.isNotEmpty) {
      return [
        const SizedBox(height: 16),
        const Text('고정 요소 (읽기전용)', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        MasterNetworkImage(url: block.src, width: 160, height: 160),
      ];
    }
    return const [];
  }
}

/// Spinner + label inside a busy button (web `<Spinner label=… />`).
class _BusyLabel extends StatelessWidget {
  final String label;

  const _BusyLabel(this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      );
}
