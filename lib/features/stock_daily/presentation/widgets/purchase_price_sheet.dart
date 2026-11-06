import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import '../../domain/entities/stock_daily.dart';
import '../bloc/purchase_price_cubit.dart';

/// 「매입가 넣기」 sheet of 「일별 입출고 내역」 (FEATURE_2611_16 D2 · D3 · D7 ·
/// D12 · D13 · D18), shown with `showAppSheet`.
///
/// - Open it inside a `BlocProvider` of a new [PurchasePriceCubit] (opened
///   with the same [targets]) — the sheet reads every state from it and pops
///   `true` once the prices were applied.
/// - The 「영수증 사진」 field follows `purchasePricePhoto(targets)` three ways:
///   a new receipt (camera · album, then 「결제 카드」 for one seller) · the
///   waiting 「영수증 나중에」 receipt (camera · album, no card) · blocked (the
///   reason text instead of the buttons).
/// - Each checked target has 「총액」/「단가」, an amount field (blank = the
///   amount stays) and 「상품 기준가에 반영」.
///
/// ⚠️ Refusals and failures are shown inside the sheet in red.
class PurchasePriceSheet extends StatefulWidget {
  final String date;
  final List<PurchasePriceTarget> targets;

  const PurchasePriceSheet({
    required this.date,
    required this.targets,
    super.key,
  });

  @override
  State<PurchasePriceSheet> createState() => _PurchasePriceSheetState();
}

class _PurchasePriceSheetState extends State<PurchasePriceSheet> {
  final ImagePicker _picker = ImagePicker();
  final Map<int, TextEditingController> _amounts = {};

  @override
  void initState() {
    super.initState();
    for (final target in widget.targets) {
      _amounts[target.recordId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _amounts.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto(PurchasePriceCubit cubit, ImageSource source) async {
    // Same downscale as the receipt check-in sheet.
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );
    if (picked == null || !mounted) {
      return;
    }
    cubit.setPhoto(File(picked.path));
  }

  static String _currentAmount(double? amount) => amount == null
      ? '미기입'
      : '₩${NumberFormat('#,##0', 'ko_KR').format(amount)}';

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<PurchasePriceCubit, PurchasePriceState>(
        listenWhen: (previous, current) => !previous.saved && current.saved,
        listener: (context, state) => Navigator.of(context).pop(true),
        builder: (context, state) {
          final cubit = context.read<PurchasePriceCubit>();
          final colorScheme = Theme.of(context).colorScheme;
          final muted = colorScheme.onSurfaceVariant;
          final photoKind = purchasePricePhoto(widget.targets);
          final cardSellerId =
              state.photo != null && photoKind is NewReceiptPhoto
                  ? photoKind.sellerId
                  : null;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '매입가 넣기',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          state.busy ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('영수증 사진',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    if (photoKind is BlockedPhoto)
                      Text(photoKind.message, style: TextStyle(color: muted))
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: state.busy
                                  ? null
                                  : () => _pickPhoto(cubit, ImageSource.camera),
                              icon: const Icon(Icons.photo_camera, size: 18),
                              label: const Text('촬영'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: state.busy
                                  ? null
                                  : () =>
                                      _pickPhoto(cubit, ImageSource.gallery),
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text('앨범'),
                            ),
                          ),
                        ],
                      ),
                      if (state.photo != null) ...[
                        const SizedBox(height: 8),
                        Image.file(state.photo!,
                            height: 200, fit: BoxFit.contain),
                      ],
                    ],
                    if (cardSellerId != null) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: state.cardChoice,
                        isExpanded: true,
                        hint: const Text('선택'),
                        decoration: const InputDecoration(
                          labelText: '결제 카드',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          for (final card in state.cards)
                            if (card.sellerId == cardSellerId)
                              DropdownMenuItem<String>(
                                value: card.id.toString(),
                                child: Text(
                                  '${card.sellerName} · ${card.alias} '
                                  '(${card.maskedNumber})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          const DropdownMenuItem<String>(
                            value: kUnknownPurchasePriceCard,
                            child: Text('카드로 알 수 없음'),
                          ),
                        ],
                        onChanged: state.busy ? null : cubit.pickCard,
                      ),
                    ],
                    if (state.error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(state.error,
                          style: TextStyle(color: colorScheme.error)),
                    ],
                    const SizedBox(height: 16),
                    const Text('매입가를 넣을 입고',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    for (final target in widget.targets)
                      _targetInput(cubit, state, target, muted),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.busy
                        ? null
                        : () => cubit.save(
                              date: widget.date,
                              targets: widget.targets,
                              amounts: {
                                for (final entry in _amounts.entries)
                                  entry.key: entry.value.text,
                              },
                            ),
                    child: state.busy
                        ? const AppBusyLabel('저장')
                        : const Text('저장'),
                  ),
                ),
              ),
            ],
          );
        },
      );

  Widget _targetInput(
    PurchasePriceCubit cubit,
    PurchasePriceState state,
    PurchasePriceTarget target,
    Color muted,
  ) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${target.productName} ${target.quantity}개 · '
                '${target.sellerName}'),
            Text(
              '지금 금액 ${_currentAmount(target.amount)}',
              style: TextStyle(fontSize: 12, color: muted),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                DropdownButton<bool>(
                  value: state.unitMode[target.recordId] ?? false,
                  items: const [
                    DropdownMenuItem(value: false, child: Text('총액')),
                    DropdownMenuItem(value: true, child: Text('단가')),
                  ],
                  onChanged: state.busy
                      ? null
                      : (value) => cubit.setUnitMode(target.recordId,
                          unit: value ?? false),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amounts[target.recordId],
                    enabled: !state.busy,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: '금액 (비우면 그대로)'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: state.reflect[target.recordId] ?? true,
                  onChanged: state.busy
                      ? null
                      : (value) => cubit.setReflect(target.recordId,
                          value: value ?? true),
                ),
                Text('상품 기준가에 반영',
                    style: TextStyle(fontSize: 12, color: muted)),
              ],
            ),
          ],
        ),
      );
}
