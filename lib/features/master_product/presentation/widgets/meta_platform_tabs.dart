import 'package:flutter/material.dart';

/// Real platforms today = COUPANG only (web `META_PLATFORMS`). Add here when
/// a second mall's adapter lands.
const List<String> kMetaPlatforms = ['COUPANG'];

/// Category meta (required attributes / notices) platform tabs — shared by
/// detail and create. Port of web
/// `app/dashboard/master-products/[id]/components/MetaPlatformTabs.tsx`
/// (@09208a0).
///
/// **Purpose**: one chip per platform + the active platform's container.
/// Switching rebuilds the container from scratch (keyed by platform) so each
/// tab loads lazily and one platform's failure never affects another.
/// **File**: lib/features/master_product/presentation/widgets/meta_platform_tabs.dart
///
/// **Usage**:
/// ```dart
/// MetaPlatformTabs(builder: (platform) => CategoryMetaPanel(platform: platform))
/// MetaPlatformTabs(
///   builder: (platform) => CategoryMetaCreateFields(
///     categoryId: _categoryId, platform: platform, value: _meta[platform]!, ...),
/// )
/// ```
///
/// ⚠️ The chip bar shows even with a single platform (same as the web).
/// ❌ Do not keep platform state outside — the active tab lives here.
class MetaPlatformTabs extends StatefulWidget {
  final Widget Function(String platform) builder;

  const MetaPlatformTabs({required this.builder, super.key});

  @override
  State<MetaPlatformTabs> createState() => _MetaPlatformTabsState();
}

class _MetaPlatformTabsState extends State<MetaPlatformTabs> {
  String _active = kMetaPlatforms[0];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final p in kMetaPlatforms)
                ChoiceChip(
                  label: Text(p),
                  selected: _active == p,
                  onSelected: (_) => setState(() => _active = p),
                ),
            ],
          ),
          const SizedBox(height: 8),
          KeyedSubtree(
            key: ValueKey(_active),
            child: widget.builder(_active),
          ),
        ],
      );
}
