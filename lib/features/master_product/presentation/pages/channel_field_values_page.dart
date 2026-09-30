import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_tool_args.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

bool _isReserved(String key) => kBuiltinFieldKeys.contains(key);

/// Per-channel (listing) field value override page — FEATURE_2609_80 / 08.
///
/// **File**: lib/features/master_product/presentation/pages/channel_field_values_page.dart
/// **Web original**: `master-products/[id]/components/ChannelFieldValuesModal.tsx` @09208a0
///
/// Only the fields defined by the default thumbnail template are editable (no
/// free keys). Built-in keys fall back to the listing value when blank, custom
/// keys to the template default. Blank keys are omitted on save.
///
/// Result: the saved `GeneratedProduct` (`null` = closed without saving).
/// ⚠️ Opened with `context.pushNamed<GeneratedProduct>(Routes.masterChannelFieldValues, extra: ChannelFieldValuesArgs(…))`.
class ChannelFieldValuesPage extends StatefulWidget {
  final ChannelFieldValuesArgs args;

  const ChannelFieldValuesPage({required this.args, super.key});

  @override
  State<ChannelFieldValuesPage> createState() => _ChannelFieldValuesPageState();
}

class _ChannelFieldValuesPageState extends State<ChannelFieldValuesPage> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();
  // One controller per field key (R2).
  final Map<String, TextEditingController> _controllers = {};

  List<TemplateField> _fields = [];
  Map<String, String> _values = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _error = '';
  GeneratedProduct? _result;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant ChannelFieldValuesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.args.listingId != widget.args.listingId) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String key) =>
      _controllers.putIfAbsent(key, TextEditingController.new);

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final generatedFuture = _useCase.getGenerated(widget.args.listingId);
    final templatesFuture = _useCase.listThumbnailTemplates();
    final generated = await generatedFuture;
    final templates = await templatesFuture;
    if (!mounted) {
      return;
    }
    final gen = generated.fold((_) => null, (g) => g);
    final list = templates.fold((_) => null, (t) => t);
    setState(() {
      if (gen == null || list == null) {
        _error = '필드값을 불러오지 못했습니다.';
      } else {
        final defaults = list.where((t) => t.isDefault);
        _fields = defaults.isEmpty ? [] : defaults.first.fields;
        _values = Map.of(gen.fieldValues);
        for (final f in _fields) {
          _controllerFor(f.key).text = _values[f.key] ?? '';
        }
      }
      _isLoading = false;
    });
  }

  void _close() => context.pop(_result);

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _error = '';
    });
    // Omit blank values so the backend falls back to product/template defaults.
    final fieldValues = <String, String>{
      for (final e in _values.entries)
        if (e.value.trim().isNotEmpty) e.key: e.value,
    };
    final res = await _useCase.updateListingFieldValues(
      widget.args.listingId,
      fieldValues,
    );
    if (!mounted) {
      return;
    }
    res.fold(
      (_) => setState(() {
        _error = '필드값 저장에 실패했습니다.';
        _isSaving = false;
      }),
      (generated) {
        _result = generated;
        _close();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _close();
        }
      },
      child: ScaffoldWithNavBar(
        title: '채널별 필드값 편집',
        navBarIndex: 2,
        onBackPressed: _close,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            kBottomNavigationBarHeight + 24,
          ),
          children: [
            if (_error.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            if (_isLoading)
              const SizedBox(
                height: 128,
                child: Center(child: _BusyLabel('불러오는 중...', size: 24)),
              )
            else if (_fields.isEmpty)
              Text(
                '기본 템플릿에 정의된 필드가 없습니다.',
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final f in _fields) ...[
                    Text(
                      f.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _controllerFor(f.key),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        isDense: true,
                        hintText:
                            _isReserved(f.key) ? '등록상품값 사용' : '템플릿 기본값 사용',
                      ),
                      onChanged: (next) =>
                          setState(() => _values = {..._values, f.key: next}),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : _close,
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isLoading || _isSaving ? null : _handleSave,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: _isSaving
                      ? const _BusyLabel('저장 중...')
                      : const Text('저장 후 재생성'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Spinner + label (web `<Spinner label=… />`).
class _BusyLabel extends StatelessWidget {
  final String label;
  final double size;

  const _BusyLabel(this.label, {this.size = 16});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      );
}
