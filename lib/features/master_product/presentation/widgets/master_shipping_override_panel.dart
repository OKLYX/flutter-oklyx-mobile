import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/shipping_override.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_sheet.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/shipping_override_fields.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';

/// One registered channel cell of this master — the force-apply selection
/// unit (web `ForceApplyChannel`).
class ForceApplyChannel {
  final int listingId;

  /// 판매자 · 플랫폼 (matrix row label).
  final String label;

  /// The channel's own shipping override. `null` with [overrideLoaded] =
  /// loaded and none.
  final Map<String, String>? override;

  /// `false` = web `override === undefined` (not loaded / fetch failed) →
  /// excluded from the "이 저장이 닿지 않는 채널" hint so it never over-reports.
  final bool overrideLoaded;

  const ForceApplyChannel({
    required this.listingId,
    required this.label,
    this.override,
    this.overrideLoaded = false,
  });
}

/// Master shipping override panel on the master detail screen —
/// FEATURE_2609_80 / 07. Edits the override applied to **every channel** of
/// this master on top of the account shipping config.
///
/// **File**: lib/features/master_product/presentation/widgets/master_shipping_override_panel.dart
/// **Web original**: `master-products/[id]/components/MasterShippingOverridePanel.tsx` @09208a0
///
/// [선택한 채널에 강제 적용] overwrites the picked channels' shipping settings
/// with this master's (the unit is one listing cell — every cell of an
/// account, not the first). The picker is a bottom sheet that also serves as
/// the confirmation (D32).
///
/// ⚠️ Force-apply reads the **saved** master override → unsaved edits are
///    saved first. An empty master override makes force-apply **erase** the
///    channels' own settings; the sheet and banner say so.
/// ⚠️ Outbound/return places are per-account centers — hidden at master level.
/// ❌ Draws no card shell — the detail page places it (09).
class MasterShippingOverridePanel extends StatefulWidget {
  final int masterId;

  /// Registered cells, for the force-apply picker.
  final List<ForceApplyChannel> channels;

  /// Matrix reload so cells pick up the new override resolution.
  final VoidCallback onSaved;

  const MasterShippingOverridePanel({
    required this.masterId,
    required this.channels,
    required this.onSaved,
    super.key,
  });

  @override
  State<MasterShippingOverridePanel> createState() =>
      _MasterShippingOverridePanelState();
}

class _MasterShippingOverridePanelState
    extends State<MasterShippingOverridePanel> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  ShippingSettings _override = kEmptyShippingOverride;
  bool _isLoading = true;
  bool _isSaving = false;
  String _error = '';
  bool _saved = false;
  Timer? _savedTimer;
  // What the server currently holds — force-apply reads the SAVED master.
  ShippingSettings _savedOverride = kEmptyShippingOverride;
  bool _isApplying = false;
  String _applyBanner = '';
  // Channels picked in the sheet (seeded each time it opens).
  Set<int> _selectedIds = {};
  // Channels that hold their own settings and did NOT receive the last save.
  List<int> _staleIds = [];

  bool get _busy => _isSaving || _isApplying;

  // Serialized override maps — "is the form still what the server holds?"
  bool get _isDirty =>
      jsonEncode(overrideToMap(_override)) !=
      jsonEncode(overrideToMap(_savedOverride));

  // Empty master override = force-apply ERASES the channels' own settings.
  bool get _masterIsEmpty => overrideToMap(_override).isEmpty;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant MasterShippingOverridePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.masterId != widget.masterId) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _savedTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final result = await _useCase.getMaster(widget.masterId);
    if (!mounted) {
      return;
    }
    setState(() {
      result.fold(
        (_) => _error = '배송 설정을 불러오지 못했습니다.',
        (master) {
          final loaded = mapToOverride(master.shippingOverride);
          _override = loaded;
          _savedOverride = loaded;
        },
      );
      _isLoading = false;
    });
  }

  // Returns the failure message, or null on success.
  Future<String?> _persist(String fallback) async {
    final snapshot = _override;
    final result = await _useCase.updateMasterShippingOverride(
      widget.masterId,
      overrideToMap(snapshot),
    );
    return result.fold(
      (failure) => failureText(failure, fallback),
      (_) {
        _savedOverride = snapshot;
        return null;
      },
    );
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _error = '';
      _saved = false;
    });
    final failure = await _persist('배송 설정 저장에 실패했습니다.');
    if (!mounted) {
      return;
    }
    if (failure != null) {
      setState(() {
        _error = failure;
        _isSaving = false;
      });
      return;
    }
    // A channel that owns these keys keeps its own values — the save does
    // not reach it. Surface that here.
    final savedMap = overrideToMap(_override);
    setState(() {
      _saved = true;
      _staleIds = widget.channels
          .where(
            (c) =>
                c.overrideLoaded &&
                channelDivergesFromMaster(c.override, savedMap),
          )
          .map((c) => c.listingId)
          .toList();
      _isSaving = false;
    });
    // Transient confirmation — auto-dismiss.
    _savedTimer?.cancel();
    _savedTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _saved = false);
      }
    });
    widget.onSaved();
  }

  Future<void> _openPicker({List<int>? preselect}) async {
    // Default to every channel; opened from the hint = only those channels.
    setState(() {
      _applyBanner = '';
      _error = '';
    });
    final picked = <int>{
      ...preselect ?? widget.channels.map((c) => c.listingId),
    };
    final confirmed = await showMasterSheet<bool>(
      context,
      builder: (sheetContext) => _ForceApplySheet(
        channels: widget.channels,
        initialSelected: picked,
        pickerFromHint: preselect != null,
        masterIsEmpty: _masterIsEmpty,
        isDirty: _isDirty,
        onConfirm: (selected) => _selectedIds = selected,
      ),
    );
    if (confirmed == true && mounted) {
      await _handleForceApply();
    }
  }

  Future<void> _handleForceApply() async {
    final listingIds = widget.channels
        .map((c) => c.listingId)
        .where(_selectedIds.contains)
        .toList();
    final masterIsEmpty = _masterIsEmpty;
    setState(() {
      _isApplying = true;
      _error = '';
      _applyBanner = '';
    });
    // Force-apply reads the SAVED master override — persist on-screen
    // edits first.
    if (_isDirty) {
      final failure = await _persist('강제 적용에 실패했습니다.');
      if (!mounted) {
        return;
      }
      if (failure != null) {
        setState(() {
          _error = failure;
          _isApplying = false;
        });
        return;
      }
    }
    final result = await _useCase.applyShippingOverrideToChannels(
      widget.masterId,
      listingIds,
    );
    if (!mounted) {
      return;
    }
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      setState(() {
        _error = failureText(failure, '강제 적용에 실패했습니다.');
        _isApplying = false;
      });
      return;
    }
    final affected = result.fold((_) => 0, (res) => res.affectedChannels);
    // 0 = idempotent no-op (normal). Empty master = the apply ERASED the
    // channels' own settings — say that instead of "덮어썼습니다".
    setState(() {
      _applyBanner = masterIsEmpty
          ? affected > 0
              ? '$affected개 채널의 개별 배송 설정을 지웠습니다 — 마스터에 배송 설정이 없어 계정 기본값을 따릅니다'
              : '변경된 채널이 없습니다 — 마스터에 배송 설정이 없습니다'
          : affected > 0
              ? '$affected개 채널의 배송 설정을 이 마스터 설정으로 덮어썼습니다'
              : '선택한 채널은 이미 이 마스터 설정과 같습니다 — 변경된 채널이 없습니다';
      _staleIds = [];
      _isApplying = false;
    });
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '전 채널 배송',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '비운 값은 판매채널의 기본 배송 설정을 그대로 쓰고, 채워진 값은 이 마스터의 전 채널에 적용됩니다. '
            '(출고지·반품지는 채널에서만 지정)',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (_error.isNotEmpty) ...[
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
            const SizedBox(height: 12),
          ],
          if (_isLoading)
            const SizedBox(
              height: 64,
              child: Center(child: _BusyLabel('불러오는 중...', size: 20)),
            )
          else
            _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const green = TextStyle(fontSize: 14, color: AppColors.successForeground);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShippingOverrideFields(
          level: ShippingOverrideLevel.master,
          value: _override,
          onChanged: (next) => setState(() {
            _override = next;
            _saved = false;
          }),
          platform: 'COUPANG',
          disabled: _busy,
        ),
        if (_saved && _error.isEmpty) ...[
          const SizedBox(height: 16),
          const Text('배송 설정을 저장했습니다.', style: green),
        ],
        if (_applyBanner.isNotEmpty && _error.isEmpty) ...[
          const SizedBox(height: 16),
          Text(_applyBanner, style: green),
        ],
        if (_staleIds.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${_staleIds.length}개 채널이 개별 배송 설정을 갖고 있어 이 변경이 반영되지 않습니다.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.infoForeground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed:
                      _busy ? null : () => _openPicker(preselect: _staleIds),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.infoForeground,
                    backgroundColor: scheme.surface,
                    side: const BorderSide(color: AppColors.infoBorder),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('해당 채널에 적용'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton(
              onPressed: _busy ? null : _handleSave,
              child: _isSaving ? const _BusyLabel('저장 중...') : const Text('저장'),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: _busy || widget.channels.isEmpty
                      ? null
                      : () => _openPicker(),
                  child: _isApplying
                      ? const _BusyLabel('적용 중...')
                      : const Text('채널에 강제 적용'),
                ),
                if (widget.channels.isEmpty)
                  const InfoBubbleIcon(message: '연결된 채널이 없습니다.'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '저장은 개별 설정이 없는 채널에 자동 반영됩니다. 강제 적용은 선택한 채널의 배송 설정을 이 마스터 '
          '설정으로 덮어씁니다(그 채널은 이후 마스터 변경을 따르지 않습니다).',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Force-apply channel picker = the confirmation (web `ConfirmDialog` body).
/// Pops `true` after handing the picked ids to [onConfirm].
class _ForceApplySheet extends StatefulWidget {
  final List<ForceApplyChannel> channels;
  final Set<int> initialSelected;
  final bool pickerFromHint;
  final bool masterIsEmpty;
  final bool isDirty;
  final ValueChanged<Set<int>> onConfirm;

  const _ForceApplySheet({
    required this.channels,
    required this.initialSelected,
    required this.pickerFromHint,
    required this.masterIsEmpty,
    required this.isDirty,
    required this.onConfirm,
  });

  @override
  State<_ForceApplySheet> createState() => _ForceApplySheetState();
}

class _ForceApplySheetState extends State<_ForceApplySheet> {
  Set<int> _selected = {};
  String _pickerError = '';

  bool get _allSelected =>
      widget.channels.isNotEmpty && _selected.length == widget.channels.length;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelected};
  }

  void _toggleChannel(int listingId) {
    setState(() {
      final next = {..._selected};
      if (!next.remove(listingId)) {
        next.add(listingId);
      }
      _selected = next;
      _pickerError = '';
    });
  }

  void _toggleAll() {
    setState(() {
      _selected = _allSelected
          ? <int>{}
          : widget.channels.map((c) => c.listingId).toSet();
      _pickerError = '';
    });
  }

  void _confirm() {
    if (_selected.isEmpty) {
      // Keep the sheet open — an empty apply is a mis-click, not a request.
      setState(() => _pickerError = '적용할 채널을 하나 이상 선택하세요.');
      return;
    }
    widget.onConfirm(_selected);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '선택한 채널에 강제 적용',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '선택한 채널의 배송 설정이 이 마스터 설정으로 덮어써집니다(되돌릴 수 없습니다). 출고지·반품지는 '
                      '계정별 설정이라 그대로 유지됩니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (widget.pickerFromHint) ...[
                      const SizedBox(height: 12),
                      Text(
                        '이 변경이 반영되지 않는 채널만 선택했습니다.',
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (widget.masterIsEmpty) ...[
                      const SizedBox(height: 12),
                      const _Notice(
                        text:
                            '⚠️ 이 마스터에는 배송 설정이 없습니다. 지금 적용하면 선택한 채널의 개별 배송 설정이 지워지고 '
                            '계정 기본값을 따르게 됩니다.',
                        background: AppColors.warningSurface,
                        foreground: AppColors.warningForeground,
                      ),
                    ],
                    if (widget.isDirty) ...[
                      const SizedBox(height: 12),
                      const _Notice(
                        text: '저장하지 않은 변경이 있습니다 — 먼저 저장한 뒤 적용합니다.',
                        background: AppColors.infoSurface,
                        foreground: AppColors.infoForeground,
                      ),
                    ],
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _allSelected,
                      onChanged: (_) => _toggleAll(),
                      title: Text(
                        '전체 선택 (${_selected.length}/${widget.channels.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(height: 1),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 256),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final c in widget.channels)
                            CheckboxListTile(
                              value: _selected.contains(c.listingId),
                              onChanged: (_) => _toggleChannel(c.listingId),
                              title: Text(
                                c.label,
                                style: const TextStyle(fontSize: 14),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ),
                    if (_pickerError.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _pickerError,
                        style: TextStyle(fontSize: 14, color: scheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _confirm,
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                  child: const Text('강제 적용'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Colored notice line (web `rounded bg-… px-3 py-2 text-sm text-…`).
class _Notice extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Notice({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: TextStyle(fontSize: 14, color: foreground)),
      );
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
