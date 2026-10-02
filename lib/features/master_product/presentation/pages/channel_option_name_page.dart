import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_tool_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';

/// Per-channel (cell) option name page (2609_22/D3) — FEATURE_2609_80 / 08.
///
/// **File**: lib/features/master_product/presentation/pages/channel_option_name_page.dart
/// **Web original**: `master-products/[id]/components/ChannelOptionNameModal.tsx` @09208a0
///
/// Option names follow the master option names by default; this page renames
/// them for **this channel only**.
/// - [기본값으로 변경] = the row is sent as `null` → back to the master name.
/// - ⚠️ Channel-only options get no [기본값으로 변경] (no master name to go
///   back to — the server also answers 400).
///
/// Result: `true` once saved (`null` = closed without saving).
class ChannelOptionNamePage extends StatefulWidget {
  final ChannelOptionsArgs args;

  const ChannelOptionNamePage({required this.args, super.key});

  @override
  State<ChannelOptionNamePage> createState() => _ChannelOptionNamePageState();
}

class _ChannelOptionNamePageState extends State<ChannelOptionNamePage> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();
  // One controller per option id (R2).
  final Map<int, TextEditingController> _controllers = {};

  List<ListingOptionSummary> _rows = [];
  // Per-row input buffer (option name).
  Map<int, String> _draft = {};
  // Rows where [기본값으로 변경] is on — saved as optionName: null.
  Set<int> _restore = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _error = '';
  bool? _result;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant ChannelOptionNamePage oldWidget) {
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

  TextEditingController _controllerFor(int optionId) =>
      _controllers.putIfAbsent(optionId, TextEditingController.new);

  // Server response → reseed. Also used right after saving.
  void _applyOptions(List<ListingOptionSummary> options) {
    _rows = options;
    _draft = {for (final o in options) o.optionId: o.optionName};
    for (final o in options) {
      _controllerFor(o.optionId).text = o.optionName;
    }
    _restore = {};
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final res = await _useCase.getListingOptions(widget.args.listingId);
    if (!mounted) {
      return;
    }
    setState(() {
      res.fold(
        (_) => _error = '옵션명을 불러오지 못했습니다.',
        (listing) => _applyOptions(listing.options),
      );
      _isLoading = false;
    });
  }

  void _close() => context.pop(_result);

  String _raw(int id) => _draft[id] ?? '';

  void _toggleRestore(int optionId) => setState(() {
        final next = {..._restore};
        if (!next.remove(optionId)) {
          next.add(optionId);
        }
        _restore = next;
      });

  bool get _invalid => _rows.any(
        (r) => !_restore.contains(r.optionId) && _raw(r.optionId).trim() == '',
      );

  List<ListingOptionSummary> get _dirty => _rows
      .where(
        (r) =>
            _restore.contains(r.optionId) ||
            _raw(r.optionId).trim() != r.optionName,
      )
      .toList();

  Future<void> _handleSave() async {
    final dirty = _dirty;
    if (dirty.isEmpty) {
      _close();
      return;
    }
    setState(() {
      _isSaving = true;
      _error = '';
    });
    final res = await _useCase.setOptionNames(
      widget.args.listingId,
      [
        for (final r in dirty)
          OptionNameChange(
            optionId: r.optionId,
            optionName: _restore.contains(r.optionId)
                ? null
                : _raw(r.optionId).trim(),
          ),
      ],
    );
    if (!mounted) {
      return;
    }
    res.fold(
      // Duplicate names inside the cell → server 400; keep the form.
      (failure) => setState(() {
        _error = failureText(failure, '옵션명 저장에 실패했습니다.');
        _isSaving = false;
      }),
      (listing) {
        setState(() {
          _applyOptions(listing.options);
          _isSaving = false;
        });
        _result = true;
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
        title: '채널별 옵션명',
        navBarIndex: 2,
        onBackPressed: _close,
        body: AppPageBody(
          children: [
            Text(
              widget.args.channelLabel,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            if (_error.isNotEmpty) ...[
              AppErrorBox(message: _error),
              const SizedBox(height: 16),
            ],
            if (_isLoading)
              const SizedBox(
                height: 128,
                child: Center(child: AppBusyLabel('불러오는 중...', size: 24)),
              )
            else if (_rows.isEmpty)
              const AppEmpty('이 채널에 옵션이 없습니다.')
            else ...[
              Text(
                '입력한 이름은 이 채널에만 적용됩니다. 마스터 옵션명으로 되돌리려면 [기본값으로 변경]을 '
                '누르세요.',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              for (final r in _rows) ...[
                _row(context, r),
                const SizedBox(height: 8),
              ],
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : _close,
                  child: const Text('취소'),
                ),
                if (_rows.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ||
                            _isSaving ||
                            _invalid ||
                            _dirty.isEmpty
                        ? null
                        : _handleSave,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: _isSaving
                        ? const AppBusyLabel('저장 중...')
                        : const Text('저장'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, ListingOptionSummary r) {
    final scheme = Theme.of(context).colorScheme;
    final willRestore = _restore.contains(r.optionId);
    final empty = !willRestore && _raw(r.optionId).trim() == '';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controllerFor(r.optionId),
            enabled: !willRestore && !_isSaving,
            onChanged: (next) => setState(
              () => _draft = {..._draft, r.optionId: next},
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (r.channelOnly == true)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '채널 전용',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (r.optionNameSource == GeneratedSourceCode.manualOverride)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outline),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '이름 직접 지정',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              // Channel-only options have no master name to go back to.
              if (r.channelOnly != true)
                OutlinedButton(
                  onPressed:
                      _isSaving ? null : () => _toggleRestore(r.optionId),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500),
                    foregroundColor:
                        willRestore ? AppColors.infoForeground : null,
                    backgroundColor: willRestore ? AppColors.infoSurface : null,
                  ),
                  child: const Text('기본값으로 변경'),
                ),
            ],
          ),
          if (willRestore) ...[
            const SizedBox(height: 4),
            Text(
              '저장하면 마스터 옵션명으로 돌아갑니다',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
          if (empty) ...[
            const SizedBox(height: 4),
            Text(
              '이름을 입력하거나 [기본값으로 변경]을 누르세요',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
