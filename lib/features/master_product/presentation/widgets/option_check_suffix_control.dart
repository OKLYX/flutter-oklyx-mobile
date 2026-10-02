import 'package:flutter/material.dart';

/// Web `OptionCheckSuffixConfig` (`domain/entities/OptionCheckSuffix.ts`):
/// this level's override; both null = inherit from the level above.
class OptionCheckSuffixConfig {
  final bool? optionCheckSuffixEnabled;
  final String? optionCheckSuffix;

  const OptionCheckSuffixConfig({
    this.optionCheckSuffixEnabled,
    this.optionCheckSuffix,
  });
}

/// Registration-name "옵션확인" suffix editor (seller / channel / master) —
/// port of web `presentation/components/OptionCheckSuffixControl.tsx`
/// (@09208a0).
///
/// **Purpose**: with 2+ options, ` - {문구}` is appended to the registration
/// name. Typing a phrase applies it at this level
/// (`enabled: true, suffix: 문구`); clearing it inherits (`null, null`).
/// **File**: lib/features/master_product/presentation/widgets/option_check_suffix_control.dart
///
/// **Usage**:
/// ```dart
/// OptionCheckSuffixControl(value: _cfg, onChanged: (next) => setState(() => _cfg = next))
/// OptionCheckSuffixControl(
///   value: _cfg, onChanged: _setCfg,
///   inheritedHint: '입력하지 않으면 추가 문구가 붙지 않습니다.', disabled: _saving,
/// )
/// ```
///
/// ⚠️ Controlled: the parent owns [value]; the text syncs from it only when
///    they differ (cursor/IME kept).
/// ❌ No ON/OFF toggle — a value means applied, blank means inherit.
class OptionCheckSuffixControl extends StatefulWidget {
  final OptionCheckSuffixConfig value;
  final ValueChanged<OptionCheckSuffixConfig> onChanged;

  /// Shown while blank (inherited) — the effective value hint.
  final String? inheritedHint;
  final bool disabled;

  const OptionCheckSuffixControl({
    required this.value,
    required this.onChanged,
    super.key,
    this.inheritedHint,
    this.disabled = false,
  });

  @override
  State<OptionCheckSuffixControl> createState() =>
      _OptionCheckSuffixControlState();
}

class _OptionCheckSuffixControlState extends State<OptionCheckSuffixControl> {
  final TextEditingController _controller = TextEditingController();

  String get _suffix => widget.value.optionCheckSuffix ?? '';

  @override
  void initState() {
    super.initState();
    _controller.text = _suffix;
  }

  @override
  void didUpdateWidget(covariant OptionCheckSuffixControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_suffix != _controller.text) {
      _controller.text = _suffix;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChange(String next) {
    if (next.trim() == '') {
      // Blank = inherit (override cleared).
      widget.onChanged(const OptionCheckSuffixConfig());
    } else {
      widget.onChanged(OptionCheckSuffixConfig(
        optionCheckSuffixEnabled: true,
        optionCheckSuffix: next,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hintStyle = TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final suffix = _suffix;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: !widget.disabled,
          maxLength: 50,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            hintText: '예: 옵션확인',
            counterText: '',
          ),
          onChanged: _handleChange,
        ),
        const SizedBox(height: 4),
        if (suffix.trim() == '')
          Text(
            widget.inheritedHint ?? '비워두면 추가 문구가 붙지 않습니다.',
            style: hintStyle,
          )
        else
          Text.rich(
            TextSpan(
              text: '옵션 2개 이상 등록상품명에 ',
              children: [
                TextSpan(
                  text: ' - $suffix',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const TextSpan(text: ' 접미사가 붙습니다.'),
              ],
            ),
            style: hintStyle,
          ),
      ],
    );
  }
}
