import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/elevenst_shipping.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/platform_category_block.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/shipping_override.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/elevenst_shipping_fields.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/shipping_override_fields.dart';

/// The 「통합」 tab key; the other tab keys are the platforms themselves.
const String kAllShippingTab = 'ALL';

/// Web `shippingPlatformsOf` — Coupang always, 11st with a switched-on 11st channel (D98 · D104).
List<String> shippingPlatformsOf(List<String> activePlatforms) =>
    activePlatforms.contains('ELEVENST')
        ? const ['COUPANG', 'ELEVENST']
        : const ['COUPANG'];

/// Web `masterShippingMapOf` — the one master override map: Coupang keys as they are + the `elevenst.*` keys.
Map<String, String> masterShippingMapOf(
  ShippingSettings coupang,
  Map<String, String> elevenst,
) =>
    {...overrideToMap(coupang), ...cleanElevenstMap(elevenst)};

/// Master shipping fields with the 「통합」 tab + one tab per platform — port of web
/// `master-products/[id]/components/MasterShippingTabs.tsx` (FEATURE_2610_13 / D104 · D105), shared by the master
/// detail panel and the master create form.
///
/// **File**: lib/features/master_product/presentation/widgets/master_shipping_tabs.dart
///
/// **Usage**:
/// ```dart
/// MasterShippingTabs(
///   platforms: shippingPlatformsOf(_activePlatforms), tab: _tab, onTabChanged: (t) => setState(() => _tab = t),
///   coupang: _override, onCoupangChanged: _setCoupang, elevenst: _elevenst, onElevenstChanged: _setElevenst,
/// )
/// ```
///
/// One platform → no tab chips, the Coupang fields as before. Two or more → 「통합」 (every platform's fields,
/// grouped under its name, no shared field) and one tab per platform (only that platform's fields, editable).
/// ⚠️ Saving must send BOTH platforms' keys ([masterShippingMapOf]) — the server keeps one map.
class MasterShippingTabs extends StatelessWidget {
  final List<String> platforms;
  final String tab;
  final ValueChanged<String> onTabChanged;
  final ShippingSettings coupang;
  final ValueChanged<ShippingSettings> onCoupangChanged;
  final Map<String, String> elevenst;
  final ValueChanged<Map<String, String>> onElevenstChanged;
  final bool disabled;

  const MasterShippingTabs({
    required this.platforms,
    required this.tab,
    required this.onTabChanged,
    required this.coupang,
    required this.onCoupangChanged,
    required this.elevenst,
    required this.onElevenstChanged,
    super.key,
    this.disabled = false,
  });

  Widget _platformFields(String platform) => platform == 'ELEVENST'
      ? ElevenstShippingFields(
          level: ShippingOverrideLevel.master,
          value: elevenst,
          onChanged: onElevenstChanged,
          disabled: disabled,
        )
      : ShippingOverrideFields(
          level: ShippingOverrideLevel.master,
          value: coupang,
          onChanged: onCoupangChanged,
          platform: 'COUPANG',
          disabled: disabled,
        );

  @override
  Widget build(BuildContext context) {
    if (platforms.length < 2) {
      return _platformFields('COUPANG');
    }
    final tabs = [kAllShippingTab, ...platforms];
    final active = tabs.contains(tab) ? tab : kAllShippingTab;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final t in tabs)
              ChoiceChip(
                label: Text(
                    t == kAllShippingTab ? '통합' : categoryPlatformLabel(t)),
                selected: active == t,
                onSelected: (_) => onTabChanged(t),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (active == kAllShippingTab)
          for (var i = 0; i < platforms.length; i++) ...[
            if (i > 0) const SizedBox(height: 24),
            Text(
              categoryPlatformLabel(platforms[i]),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _platformFields(platforms[i]),
          ]
        else
          _platformFields(active),
      ],
    );
  }
}
