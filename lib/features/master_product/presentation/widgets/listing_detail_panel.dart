import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/copy_id_button.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/market_option_link_sheet.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/tag_chips_input.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';

const String _channelOnlyReason = '마스터 옵션이 없는 채널 전용 옵션입니다';
const String _optionLinkUnknownReason =
    '채널별 옵션을 불러오지 못해 연결된 마스터 옵션을 알 수 없습니다';
const String _optionIdPendingHint = '승인 후 부여';

/// Why an option already on the market cannot be switched off (approved
/// market options are never physically deleted — the backend answers 400).
const String kMarketOptionLockReason = '마켓에 등록된 옵션은 뺄 수 없습니다.';

/// Web `formatWon` — shared by the listing row and the option picker sheet.
String formatWon(num v) => '${koNumber(v)}원';

/// Screen shape of one listing option — merges `generated[].optionPrices`
/// (active · market lock · price · stock) with `channel-options` (option ID ·
/// linked master option) — web `ListingOptionView`.
class ListingOptionView {
  final int optionId;
  final String name;
  final num sellingPrice;

  /// A price set by a person, not the auto price (2609_19).
  final bool priceManual;

  /// Effective stock = channel value ?? master cap.
  final int stock;

  /// No channel value — follows the master value (grey).
  final bool stockInherited;
  final bool active;

  /// On the market and active → cannot be switched off (87).
  final bool lockedOff;
  final String? platformOptionId;

  /// `null` with [masterOptionKnown] = channel-only option.
  final int? masterOptionId;

  /// `false` = web `masterOptionId === undefined` (channel options not
  /// loaded / failed → the link is unknown).
  final bool masterOptionKnown;

  const ListingOptionView({
    required this.optionId,
    required this.name,
    required this.sellingPrice,
    required this.priceManual,
    required this.stock,
    required this.stockInherited,
    required this.active,
    required this.lockedOff,
    required this.platformOptionId,
    required this.masterOptionId,
    required this.masterOptionKnown,
  });
}

/// Body shown when a listing row is expanded — display name · option cards ·
/// (folded once more) tags / image / detail page — FEATURE_2609_80 / 08.
///
/// **File**: lib/features/master_product/presentation/widgets/listing_detail_panel.dart
/// **Web original**: `master-products/[id]/components/ListingDetailPanel.tsx` @09208a0
///
/// - Display name: [수정] toggles view ↔ edit (blank cannot be saved). Local
///   save only — the market gets it on [수정 요청].
/// - Registration name: auto value, read-only.
/// - Option cards: the **only** place that shows option · price · stock. No
///   active checkbox (2609_77/D57) — unused options are dimmed with `(미사용)`.
///   [수정] sends to the master option editor (does not edit here). An empty
///   option ID on a market listing shows [쿠팡 옵션 연결].
/// - Tags: raw channel tags (current value from the matrix, no extra call).
///
/// Every save is reflected through the parent reload ([onSaved]).
class ListingDetailPanel extends StatefulWidget {
  final int listingId;
  final String name;
  final String registrationName;
  final List<String> tags;

  /// The listing is on Coupang (has a product ID) (2609_74/D13).
  final bool onMarket;
  final List<ListingOptionView> options;

  /// Options still loading — distinguishes a spinner from "옵션 없음".
  final bool optionsLoading;
  final ValueChanged<int> onEditMasterOption;
  final VoidCallback onSaved;

  /// Thumbnail / detail preview drawn by the parent (inside the folded part).
  final Widget thumbnail;
  final Widget detailThumb;

  const ListingDetailPanel({
    required this.listingId,
    required this.name,
    required this.registrationName,
    required this.tags,
    required this.onMarket,
    required this.options,
    required this.optionsLoading,
    required this.onEditMasterOption,
    required this.onSaved,
    required this.thumbnail,
    required this.detailThumb,
    super.key,
  });

  @override
  State<ListingDetailPanel> createState() => _ListingDetailPanelState();
}

class _ListingDetailPanelState extends State<ListingDetailPanel> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();
  final TextEditingController _nameController = TextEditingController();

  // Display name
  bool _isEditingName = false;
  String _nameDraft = '';
  bool _savingName = false;
  String _nameError = '';

  // Channel raw tags
  bool _isEditingTags = false;
  List<String> _tagsDraft = [];
  bool _savingTags = false;
  String _tagsError = '';

  bool _extrasOpen = false;

  @override
  void initState() {
    super.initState();
    _nameDraft = widget.name;
    _tagsDraft = widget.tags;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _trimmedName => _nameDraft.trim();

  void _startEditName() => setState(() {
        _nameDraft = widget.name;
        _nameController.text = widget.name;
        _nameError = '';
        _isEditingName = true;
      });

  Future<void> _saveName() async {
    if (_trimmedName.isEmpty) {
      return;
    }
    setState(() {
      _savingName = true;
      _nameError = '';
    });
    final res = await _useCase.updateDisplayName(widget.listingId, _trimmedName);
    if (!mounted) {
      return;
    }
    res.fold(
      (_) => setState(() {
        _nameError = '노출상품명 저장에 실패했습니다.';
        _savingName = false;
      }),
      (_) {
        setState(() {
          _isEditingName = false;
          _savingName = false;
        });
        widget.onSaved();
      },
    );
  }

  void _startEditTags() => setState(() {
        _tagsDraft = widget.tags;
        _tagsError = '';
        _isEditingTags = true;
      });

  Future<void> _saveTags() async {
    setState(() {
      _savingTags = true;
      _tagsError = '';
    });
    final res = await _useCase.updateListingTags(widget.listingId, _tagsDraft);
    if (!mounted) {
      return;
    }
    res.fold(
      (_) => setState(() {
        _tagsError = '태그 저장에 실패했습니다.';
        _savingTags = false;
      }),
      (_) {
        setState(() {
          _isEditingTags = false;
          _savingTags = false;
        });
        widget.onSaved();
      },
    );
  }

  Future<void> _openLink(ListingOptionView o) async {
    final linked = await showMarketOptionLinkSheet(
      context,
      listingId: widget.listingId,
      optionId: o.optionId,
      optionName: o.name,
    );
    if (linked) {
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(48, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _nameRow(context),
          const SizedBox(height: 12),
          // Registration name (67/68): read-only auto value.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _FieldLabel('등록상품명'),
              Text(
                widget.registrationName,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _optionsBox(context),
          const SizedBox(height: 12),
          _extras(context),
        ],
      ),
    );
  }

  Widget _nameRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const _FieldLabel('노출상품명'),
        if (_isEditingName) ...[
          TextField(
            controller: _nameController,
            enabled: !_savingName,
            onChanged: (next) => setState(() => _nameDraft = next),
          ),
          OutlinedButton(
            onPressed:
                _savingName || _trimmedName.isEmpty ? null : _saveName,
            style: _smallOutlined(foreground: AppColors.infoForeground),
            child: _savingName ? const AppBusyLabel('저장 중') : const Text('저장'),
          ),
          OutlinedButton(
            onPressed: _savingName
                ? null
                : () => setState(() => _isEditingName = false),
            style: _smallOutlined(),
            child: const Text('취소'),
          ),
        ] else ...[
          Text(
            widget.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          OutlinedButton(
            onPressed: _startEditName,
            style: _smallOutlined(),
            child: const Text('수정'),
          ),
        ],
        if (_nameError.isNotEmpty)
          Text(_nameError, style: TextStyle(fontSize: 12, color: scheme.error)),
      ],
    );
  }

  Widget _optionsBox(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final options = widget.options;
    Widget content;
    if (widget.optionsLoading && options.isEmpty) {
      content = const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: AppBusyLabel('옵션 불러오는 중', size: 12),
      );
    } else if (options.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '옵션 없음',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final o in options) _optionCard(context, o),
        ],
      );
    }
    return content;
  }

  Widget _optionCard(BuildContext context, ListingOptionView o) {
    final scheme = Theme.of(context).colorScheme;
    final dim = o.active ? null : scheme.onSurfaceVariant;
    final labelStyle = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    final editReason = !o.masterOptionKnown
        ? _optionLinkUnknownReason
        : o.masterOptionId == null
            ? _channelOnlyReason
            : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: o.name),
                  if (!o.active)
                    const TextSpan(
                      text: ' (미사용)',
                      style: TextStyle(fontSize: 10),
                    ),
                ],
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: dim,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('가격:', style: labelStyle),
                Text(
                  formatWon(o.sellingPrice),
                  style: TextStyle(
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: dim,
                  ),
                ),
                // A person-set price marker (different rule from stock grey).
                if (o.priceManual)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '수동',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.warningForeground,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Wrap(
              spacing: 4,
              children: [
                Text('재고:', style: labelStyle),
                Text(
                  '${o.stock}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: o.active && !o.stockInherited
                        ? null
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('옵션 ID:', style: labelStyle),
                ..._optionIdCell(context, o),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: o.masterOptionId == null
                        ? null
                        : () => widget.onEditMasterOption(o.masterOptionId!),
                    style: _smallOutlined(),
                    child: const Text('수정'),
                  ),
                  if (editReason != null) InfoBubbleIcon(message: editReason),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _optionIdCell(BuildContext context, ListingOptionView o) {
    final scheme = Theme.of(context).colorScheme;
    final id = o.platformOptionId;
    // An option ID appears only after approval — no warning color.
    if (id != null && id.isNotEmpty) {
      return [
        Text(
          id,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            fontFeatures: const [FontFeature.tabularFigures()],
            color: scheme.onSurfaceVariant,
          ),
        ),
        CopyIdButton(value: id),
      ];
    }
    if (widget.onMarket && o.masterOptionKnown) {
      // On Coupang but the option ID is empty → a person links it.
      return [
        OutlinedButton(
          onPressed: () => _openLink(o),
          style: _smallOutlined(),
          child: const Text('쿠팡 옵션 연결'),
        ),
      ];
    }
    return [
      Text('–', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      const InfoBubbleIcon(message: _optionIdPendingHint, size: 14),
    ];
  }

  Widget _extras(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _extrasOpen = !_extrasOpen),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _extrasOpen ? Icons.expand_more : Icons.chevron_right,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '태그 ${widget.tags.length}개 · 이미지 · 상세페이지',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (_extrasOpen)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tagsRow(context),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const _FieldLabel('이미지'),
                    widget.thumbnail,
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const _FieldLabel('상세페이지'),
                    widget.detailThumb,
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tagsRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tags = widget.tags;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        const _FieldLabel('태그'),
        if (_isEditingTags) ...[
          TagChipsInput(
            tags: _tagsDraft,
            onChanged: (next) => setState(() => _tagsDraft = next),
            disabled: _savingTags,
          ),
          OutlinedButton(
            onPressed: _savingTags ? null : _saveTags,
            style: _smallOutlined(foreground: AppColors.infoForeground),
            child: _savingTags ? const AppBusyLabel('저장 중') : const Text('저장'),
          ),
          OutlinedButton(
            onPressed: _savingTags
                ? null
                : () => setState(() => _isEditingTags = false),
            style: _smallOutlined(),
            child: const Text('취소'),
          ),
        ] else ...[
          if (tags.isNotEmpty)
            for (final tag in tags)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: const TextStyle(fontSize: 12)),
              )
          else
            Text(
              '없음',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          OutlinedButton(
            onPressed: _startEditTags,
            style: _smallOutlined(),
            child: const Text('수정'),
          ),
        ],
        if (_tagsError.isNotEmpty)
          Text(_tagsError, style: TextStyle(fontSize: 12, color: scheme.error)),
      ],
    );
  }
}

ButtonStyle _smallOutlined({Color? foreground}) => OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      foregroundColor: foreground,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );

/// Left label of a panel line (web `w-16 text-xs font-semibold text-gray-500`).
class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 64,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
}
