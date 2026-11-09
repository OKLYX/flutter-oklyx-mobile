import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import '../../domain/entities/stock_daily.dart';
import '../bloc/purchase_price_cubit.dart';
import '../bloc/row_edit_cubit.dart';
import 'date_edit_history.dart';

/// 「입고 정보 수정」 sheet of 「일별 입출고 내역」 (FEATURE_2611_17 D5 · D6 ·
/// D9 · D17 ~ D23), shown with `showAppSheet` when a card or a share line is
/// tapped.
///
/// - Open it inside a `BlocProvider` of a new [RowEditCubit] (opened with the
///   same [target] and [date]) — the sheet reads every state from it and pops
///   the day the row moved to once the row was saved ('' = the day stayed).
/// - Fields follow [target]: 「판매자」 (a dropdown when the seller can change),
///   the price (「총액」/「단가」 + amount, 「상품 기준가에 반영」 for a
///   purchase) and the receipt field ([RowEditReceipt]).
/// - Picking a receipt of another payer asks first (「판매자 바뀜」).
/// - 「날짜」 on top (FEATURE_2611_21 D9, [RowEditTarget.dateField]): locked =
///   off with [receiptRowDateMessage]; a share has none. The row's day
///   corrections are listed last (D24).
///
/// ⚠️ Refusals and failures are shown inside the sheet in red.
class RowEditSheet extends StatefulWidget {
  final String date;
  final RowEditTarget target;
  final List<Seller> sellers;

  const RowEditSheet({
    required this.date,
    required this.target,
    required this.sellers,
    super.key,
  });

  @override
  State<RowEditSheet> createState() => _RowEditSheetState();
}

class _RowEditSheetState extends State<RowEditSheet> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(RowEditCubit cubit, ImageSource source) async {
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

  String _sellerName(int? sellerId) {
    for (final seller in widget.sellers) {
      if (seller.id == sellerId) {
        return seller.sellerName;
      }
    }
    return sellerId == widget.target.sellerId ? widget.target.sellerName : '';
  }

  /// FEATURE_2611_21 D9: the 「날짜」 picker starts at the picked day.
  Future<void> _pickDay(RowEditCubit cubit) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(cubit.state.movedOn),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    cubit.setMovedOn(DateFormat('yyyy-MM-dd').format(picked));
  }

  /// D23: a receipt of another payer is picked only after [바꾸기].
  Future<void> _onReceiptPicked(
    RowEditCubit cubit,
    RowEditState state,
    String? choice,
  ) async {
    if (choice == null) {
      return;
    }
    final id = int.tryParse(choice);
    DayReceipt? receipt;
    for (final r in state.receipts) {
      if (r.id == id) {
        receipt = r;
      }
    }
    if (receipt != null && receipt.payerSellerId != state.sellerId) {
      final ok = await showAppConfirmDialog(
        context,
        title: '판매자 바뀜',
        message: sellerSwitchMessage(
          _sellerName(state.sellerId),
          receipt.payerSellerName,
        ),
        confirmText: '바꾸기',
      );
      if (!ok || !mounted) {
        return;
      }
    }
    cubit.pickReceipt(choice);
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<RowEditCubit, RowEditState>(
        listenWhen: (previous, current) => !previous.saved && current.saved,
        listener: (context, state) =>
            Navigator.of(context).pop(state.movedTo ?? ''),
        builder: (context, state) {
          final cubit = context.read<RowEditCubit>();
          final colorScheme = Theme.of(context).colorScheme;
          final muted = colorScheme.onSurfaceVariant;
          final target = widget.target;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '입고 정보 수정',
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
                    ..._dateField(cubit, state, muted),
                    Text('${target.productName} ${target.quantity}개'),
                    Text(
                      '지금 금액 ${_currentAmount(target.amount)}',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    const SizedBox(height: 16),
                    ..._sellerField(cubit, state, muted),
                    if (target.price != null) ..._priceField(cubit, state),
                    ..._receiptField(cubit, state),
                    DateEditHistory(edits: target.dateEdits),
                    if (state.error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(state.error,
                          style: TextStyle(color: colorScheme.error)),
                    ],
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
                              target: target,
                              amount: _amount.text,
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

  List<Widget> _dateField(
    RowEditCubit cubit,
    RowEditState state,
    Color muted,
  ) {
    final field = widget.target.dateField;
    if (field == null) {
      return const [];
    }
    return [
      _label('날짜'),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: state.busy || field == RowEditDate.locked
              ? null
              : () => _pickDay(cubit),
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text(state.movedOn),
        ),
      ),
      if (field == RowEditDate.locked)
        Text(
          receiptRowDateMessage,
          style: TextStyle(fontSize: 12, color: muted),
        ),
      const SizedBox(height: 16),
    ];
  }

  static Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      );

  List<Widget> _sellerField(
    RowEditCubit cubit,
    RowEditState state,
    Color muted,
  ) {
    final target = widget.target;
    if (!target.sellerEditable) {
      return [
        _label('판매자'),
        Text(target.sellerName),
        if (target.receipt != null)
          Text(
            '판매자는 영수증 수정에서 바꿉니다',
            style: TextStyle(fontSize: 12, color: muted),
          ),
        const SizedBox(height: 16),
      ];
    }
    final listed = widget.sellers.any((s) => s.id == state.sellerId);
    return [
      _label('판매자'),
      DropdownButton<int>(
        value: listed ? state.sellerId : null,
        isExpanded: true,
        hint: Text(_sellerName(state.sellerId)),
        items: [
          for (final seller in widget.sellers)
            DropdownMenuItem<int>(
              value: seller.id,
              child: Text(seller.sellerName, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: state.busy
            ? null
            : (value) {
                if (value != null) {
                  cubit.setSeller(value);
                }
              },
      ),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _priceField(RowEditCubit cubit, RowEditState state) => [
        Row(
          children: [
            DropdownButton<bool>(
              value: state.unitMode,
              items: const [
                DropdownMenuItem(value: false, child: Text('총액')),
                DropdownMenuItem(value: true, child: Text('단가')),
              ],
              onChanged: state.busy
                  ? null
                  : (value) => cubit.setUnitMode(unit: value ?? false),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _amount,
                enabled: !state.busy,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '금액 (비우면 그대로)'),
              ),
            ),
          ],
        ),
        if (widget.target.price == RowEditPrice.purchase)
          Row(
            children: [
              Checkbox(
                value: state.reflect,
                onChanged: state.busy
                    ? null
                    : (value) => cubit.setReflect(value: value ?? true),
              ),
              const Text('상품 기준가에 반영'),
            ],
          ),
        const SizedBox(height: 16),
      ];

  List<Widget> _photoButtons(RowEditCubit cubit, RowEditState state) => [
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
                    : () => _pickPhoto(cubit, ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('앨범'),
              ),
            ),
          ],
        ),
        if (state.photo != null) ...[
          const SizedBox(height: 8),
          Image.file(state.photo!, height: 200, fit: BoxFit.contain),
        ],
      ];

  List<Widget> _receiptField(RowEditCubit cubit, RowEditState state) {
    final target = widget.target;
    switch (target.receipt) {
      case null:
        return const [];
      case RowEditReceipt.laterPhoto:
        return [_label('영수증 사진'), ..._photoButtons(cubit, state)];
      case RowEditReceipt.fixed:
        DayReceipt? receipt;
        for (final r in state.receipts) {
          if (r.id == target.receiptId) {
            receipt = r;
          }
        }
        return [
          _label('영수증'),
          Text(receipt != null
              ? receiptChoiceLabel(receipt)
              : '영수증 #${target.receiptId}'),
        ];
      case RowEditReceipt.pick:
        final sellerId = state.sellerId ?? target.sellerId;
        final choices = dayReceiptChoices(state.receipts, sellerId);
        final newPhoto = state.receiptChoice == kNewRowEditReceipt;
        return [
          _label('영수증'),
          DropdownButton<String>(
            value: state.receiptChoice,
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: kNoRowEditReceipt,
                child: Text('영수증 없음'),
              ),
              for (final receipt in choices)
                DropdownMenuItem<String>(
                  value: receipt.id.toString(),
                  child: Text(
                    receiptChoiceLabel(receipt),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const DropdownMenuItem<String>(
                value: kNewRowEditReceipt,
                child: Text('새 영수증 사진 올리기'),
              ),
            ],
            onChanged: state.busy
                ? null
                : (value) => _onReceiptPicked(cubit, state, value),
          ),
          if (newPhoto) ...[
            const SizedBox(height: 8),
            ..._photoButtons(cubit, state),
            const SizedBox(height: 16),
            _label('결제 카드'),
            DropdownButton<String>(
              value: state.cardChoice,
              isExpanded: true,
              hint: const Text('선택'),
              items: [
                for (final card in state.cards)
                  if (card.sellerId == sellerId)
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
        ];
    }
  }
}
