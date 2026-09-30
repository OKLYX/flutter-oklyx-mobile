import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

// Status enum → screen text.
const Map<String, String> _statusLabel = {
  'DRAFT': '미전송',
  'SUBMITTED': '승인 대기중',
  'SELLING': '판매중',
  'REJECTED': '승인 반려',
  'SUSPENDED': '판매 중지',
};

/// Opens the detached listing picker (2609_74/D1 · D14) — FEATURE_2609_80 / 08.
///
/// **File**: lib/features/master_product/presentation/widgets/detached_listing_picker_sheet.dart
/// **Web original**: `master-products/[id]/components/DetachedListingPickerModal.tsx` @09208a0
///
/// Lists listings whose master link was cut, **for this account only**
/// (seller · platform). Picking one returns its Coupang product ID; the caller
/// opens 「마켓 상품 추가하기」 with it (the re-attach happens there).
/// - Loads right away (no keyword = latest 20). [검색] = name partial match or
///   exact Coupang product ID.
///
/// Returns the picked `platformProductId`, or `null` when dismissed.
///
/// **Usage**:
/// ```dart
/// final picked = await showDetachedListingPickerSheet(context,
///     masterId: id, sellerId: sellerId, platform: 'COUPANG', sellerName: name);
/// if (picked != null) { /* open MarketProductAddPage(initialProductId: picked) */ }
/// ```
///
/// 🔴 Nothing is saved here — only [가져오기] on the add page saves.
/// ⚠️ The list is never cached.
Future<String?> showDetachedListingPickerSheet(
  BuildContext context, {
  required int masterId,
  required int sellerId,
  required String platform,
  required String sellerName,
}) =>
    showMasterSheet<String>(
      context,
      builder: (_) => _DetachedListingPickerSheet(
        masterId: masterId,
        sellerId: sellerId,
        platform: platform,
        sellerName: sellerName,
      ),
    );

class _DetachedListingPickerSheet extends StatefulWidget {
  final int masterId;
  final int sellerId;
  final String platform;
  final String sellerName;

  const _DetachedListingPickerSheet({
    required this.masterId,
    required this.sellerId,
    required this.platform,
    required this.sellerName,
  });

  @override
  State<_DetachedListingPickerSheet> createState() =>
      _DetachedListingPickerSheetState();
}

class _DetachedListingPickerSheetState
    extends State<_DetachedListingPickerSheet> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();
  final TextEditingController _draftController = TextEditingController();

  String _keyword = '';
  List<DetachedListing> _items = [];
  bool _loading = true;
  String _error = '';
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    final res = await _useCase.findDetachedListings(
      widget.masterId,
      sellerId: widget.sellerId,
      platform: widget.platform,
      keyword: _keyword == '' ? null : _keyword,
    );
    if (!mounted || seq != _seq) {
      return;
    }
    setState(() {
      res.fold(
        (failure) {
          _items = [];
          _error = failureText(failure, '미연결 판매상품을 불러오지 못했습니다.');
        },
        (items) {
          _items = items;
          _error = '';
        },
      );
      _loading = false;
    });
  }

  void _handleSearch() {
    final next = _draftController.text.trim();
    // Same keyword → no reload.
    if (next == _keyword) {
      return;
    }
    setState(() {
      _loading = true;
      _keyword = next;
    });
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '미연결 판매상품 연결',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.sellerName} · ${widget.platform}',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _draftController,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: '상품명 또는 쿠팡 상품 ID',
                      ),
                      onSubmitted: (_) => _handleSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _loading ? null : _handleSearch,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.infoForeground,
                    ),
                    child: const Text('검색'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                const SizedBox(height: 12),
              ],
              if (_loading)
                const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 4),
                    Text('불러오는 중'),
                  ],
                )
              else if (_items.isEmpty)
                if (_error.isEmpty)
                  Text(
                    '이 계정에 마스터 연결이 끊긴 판매상품이 없습니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  const SizedBox.shrink()
              else
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _items.length; i++) ...[
                        if (i > 0)
                          Divider(height: 1, color: scheme.outlineVariant),
                        _itemRow(context, _items[i]),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                '최근 20건까지 보여줍니다. 찾는 판매상품이 없으면 상품명이나 쿠팡 상품 ID 로 검색하세요.',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _itemRow(BuildContext context, DetachedListing item) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: item.platformProductId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      TextSpan(
                        text: ' · ${_statusLabel[item.status] ?? item.status}',
                      ),
                    ],
                  ),
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(item.platformProductId),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: AppColors.infoForeground,
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            child: const Text('선택'),
          ),
        ],
      ),
    );
  }
}
