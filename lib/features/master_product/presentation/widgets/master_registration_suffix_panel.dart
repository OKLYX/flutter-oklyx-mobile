import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/option_check_suffix_control.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// Master registration-name "옵션확인" suffix override panel on the master
/// detail screen — FEATURE_2609_80 / 07.
///
/// **File**: lib/features/master_product/presentation/widgets/master_registration_suffix_panel.dart
/// **Web original**: `master-products/[id]/components/MasterRegistrationSuffixPanel.tsx` @09208a0
///
/// Resolution = channel ?? master ?? seller default ?? system (옵션확인). This
/// panel edits only the **master** override ([OptionCheckSuffixControl]).
/// Save success calls [onSaved] (matrix reload) so the registration-name
/// sub-rows pick up the new suffix.
///
/// ⚠️ The web wraps this panel in its own `Card` with a heading; mobile keeps
///    the heading and drops the card shell (the detail page places it, 09).
class MasterRegistrationSuffixPanel extends StatefulWidget {
  final int masterId;
  final VoidCallback onSaved;

  const MasterRegistrationSuffixPanel({
    required this.masterId,
    required this.onSaved,
    super.key,
  });

  @override
  State<MasterRegistrationSuffixPanel> createState() =>
      _MasterRegistrationSuffixPanelState();
}

class _MasterRegistrationSuffixPanelState
    extends State<MasterRegistrationSuffixPanel> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  OptionCheckSuffixConfig _config = const OptionCheckSuffixConfig();
  bool _isLoading = true;
  bool _isSaving = false;
  String _error = '';
  bool _saved = false;
  Timer? _savedTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant MasterRegistrationSuffixPanel oldWidget) {
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
        (_) => _error = '추가 문구를 불러오지 못했습니다.',
        (master) => _config = OptionCheckSuffixConfig(
          optionCheckSuffixEnabled: master.optionCheckSuffixEnabled,
          optionCheckSuffix: master.optionCheckSuffix,
        ),
      );
      _isLoading = false;
    });
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _error = '';
      _saved = false;
    });
    final result = await _useCase.updateRegistrationNameSuffix(
      widget.masterId,
      enabled: _config.optionCheckSuffixEnabled,
      suffix: _config.optionCheckSuffix,
    );
    if (!mounted) {
      return;
    }
    if (result.isLeft()) {
      setState(() {
        _error = '추가 문구 저장에 실패했습니다.';
        _isSaving = false;
      });
      return;
    }
    setState(() {
      _saved = true;
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '등록상품명 추가 문구',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
          else ...[
            OptionCheckSuffixControl(
              value: _config,
              onChanged: (next) => setState(() {
                _config = next;
                _saved = false;
              }),
              inheritedHint: '채널/판매자 설정을 사용합니다.',
              disabled: _isSaving,
            ),
            if (_saved && _error.isEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                '추가 문구를 저장했습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.successForeground,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving ? const _BusyLabel('저장 중...') : const Text('저장'),
            ),
          ],
        ],
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
