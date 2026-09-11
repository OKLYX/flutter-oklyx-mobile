import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/widgets/seller_filter_dropdown.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/purchase_candidate.dart';
import '../../domain/entities/return_candidate.dart';
import '../../domain/entities/stock_enums.dart';
import '../bloc/stock_ledger_bloc.dart';
import '../bloc/stock_ledger_event.dart';
import '../bloc/stock_ledger_state.dart';
import '../widgets/movement_tile.dart';
import '../widgets/stock_error_retry.dart';
import '../widgets/stock_product_picker_dialog.dart';

/// 입고·조정 페이지 (`/stock/in-out`, PLAN 2609_28 D6~D10 · D22).
///
/// 입고 · 반품입고 · 폐기 · 조정 1건을 기록하고 최근 이력을 보여준다.
/// 출고는 여기서 만들 수 없다 — 주문에서 출발한다(D11, 출고 확인 페이지).
///
/// ⚠️ 유형을 바꾸면 사유·선택 항목을 초기화한다(남으면 서버가 400 을 낸다).
/// ⚠️ 수량은 양수로 입력한다(조정만 음수 허용) — 폐기 부호는 서버가 뒤집는다.
class StockEntryPage extends StatelessWidget {
  const StockEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<StockLedgerBloc>()..add(LoadEntryData()),
      child: const _StockEntryView(),
    );
  }
}

class _StockEntryView extends StatefulWidget {
  const _StockEntryView();

  @override
  State<_StockEntryView> createState() => _StockEntryViewState();
}

class _StockEntryViewState extends State<_StockEntryView> {
  StockMovementType _type = StockMovementType.stockIn;
  StockReason? _reason;
  Product? _product;
  int? _sellerId;
  PurchaseCandidate? _purchase;
  ReturnCandidate? _returnClaim;
  late DateTime _movedOn;

  // ♻️ 옛 입출고 화면의 입력 패턴: autofocus + 기록 후 clear·재포커스 (연속 입력이 빨라진다).
  final TextEditingController _qtyController = TextEditingController();
  final FocusNode _qtyFocusNode = FocusNode();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _movedOn = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _qtyFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _qtyFocusNode.dispose();
    _noteController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  String get _movedOnText => _formatDate(_movedOn);

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// 유형 전환 — 사유와 선택 항목을 전부 비운다.
  void _onTypeChanged(StockMovementType type) {
    setState(() {
      _type = type;
      _reason = null;
      _purchase = null;
      _returnClaim = null;
      _noteController.clear();
      _unitPriceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    return ScaffoldWithNavBar(
      title: '입고·조정',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: BlocConsumer<StockLedgerBloc, StockLedgerState>(
        listenWhen: (prev, curr) =>
            curr is StockLedgerLoaded &&
            (curr.actionError != null || curr.actionMessage != null),
        listener: (context, state) {
          final loaded = state as StockLedgerLoaded;
          if (loaded.actionError != null) {
            _snack(context, loaded.actionError!);
          } else if (loaded.actionMessage != null) {
            _snack(context, loaded.actionMessage!);
            _afterRecorded();
          }
          context.read<StockLedgerBloc>().add(ClearStockLedgerNotice());
        },
        builder: (context, state) {
          if (state is StockLedgerInitial || state is StockLedgerLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StockLedgerError) {
            return StockErrorRetry(
              message: state.message,
              onRetry: () =>
                  context.read<StockLedgerBloc>().add(LoadEntryData()),
            );
          }
          final loaded = state as StockLedgerLoaded;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildForm(context, loaded),
                const SizedBox(height: 24),
                const Text(
                  '최근 이력',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                if (loaded.movements.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '최근 30일 이력이 없습니다.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ...loaded.movements
                      .map((m) => MovementTile(movement: m)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, StockLedgerLoaded state) {
    final reasons = StockReason.forType(_type);
    final busy = state.actionInProgressKey != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<StockMovementType>(
            segments: StockMovementType.entryTypes
                .map((t) => ButtonSegment(value: t, label: Text(t.label)))
                .toList(),
            selected: {_type},
            showSelectedIcon: false,
            onSelectionChanged: busy ? null : (set) => _onTypeChanged(set.first),
          ),
        ),
        const SizedBox(height: 12),
        SellerFilterDropdown(
          sellers: state.sellers,
          selectedSellerId: _sellerId,
          includeAll: false,
          labelText: _type == StockMovementType.returnIn
              ? '판매자 (주문 미매칭 반품만)'
              : '판매자',
          enabled: !busy,
          onChanged: (value) => setState(() => _sellerId = value),
        ),
        const SizedBox(height: 12),
        _buildProductField(context, busy),
        if (_type == StockMovementType.stockIn &&
            _reason == StockReason.purchase) ...[
          const SizedBox(height: 12),
          _buildPurchasePicker(context, state, busy),
        ],
        if (_type == StockMovementType.returnIn) ...[
          const SizedBox(height: 12),
          _buildReturnPicker(context, state, busy),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _qtyController,
          focusNode: _qtyFocusNode,
          enabled: !busy,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [
            // 조정만 음수를 허용한다 — 나머지는 부호를 서버가 정한다.
            FilteringTextInputFormatter.allow(
              _type == StockMovementType.adjust
                  ? RegExp(r'^-?\d*')
                  : RegExp(r'^\d*'),
            ),
          ],
          decoration: InputDecoration(
            labelText: '수량',
            helperText: _type == StockMovementType.adjust
                ? '실사 차이는 음수로 입력할 수 있습니다'
                : null,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        if (reasons.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<StockReason>(
            value: _reason,
            isExpanded: true,
            hint: const Text('선택'),
            decoration: const InputDecoration(
              labelText: '사유',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: reasons
                .map((r) =>
                    DropdownMenuItem(value: r, child: Text(r.label)))
                .toList(),
            onChanged: busy
                ? null
                : (value) => setState(() {
                      _reason = value;
                      if (value != StockReason.purchase) _purchase = null;
                      if (value != StockReason.etc) _noteController.clear();
                      if (value != StockReason.opening) {
                        _unitPriceController.clear();
                      }
                    }),
          ),
        ],
        if (_reason == StockReason.etc) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: '메모 (필수)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
        if (_type == StockMovementType.stockIn &&
            _reason == StockReason.opening) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _unitPriceController,
            enabled: !busy,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: '단가 (필수)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
        const SizedBox(height: 12),
        InkWell(
          onTap: busy ? null : _pickDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '날짜',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            child: Text(_movedOnText),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: busy ? null : () => _submit(context),
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('기록'),
          ),
        ),
      ],
    );
  }

  Widget _buildProductField(BuildContext context, bool busy) {
    // 구매기록을 골랐으면 그 물품이 정본이다 — 다른 물품으로 바꾸면 두 원장이 어긋난다.
    final locked = _purchase != null;
    final name = _purchase?.productName ?? _product?.productName;

    return InkWell(
      onTap: busy || locked ? null : () => _pickProduct(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '상품',
          border: const OutlineInputBorder(),
          isDense: true,
          helperText: locked ? '구매기록의 물품을 그대로 씁니다' : null,
        ),
        child: Text(
          name ?? '검색 선택',
          style: TextStyle(
            color: name == null
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// 매입 입고는 구매기록을 참조해야 한다(D8) — 단가는 그쪽에서 승계된다.
  Widget _buildPurchasePicker(
    BuildContext context,
    StockLedgerLoaded state,
    bool busy,
  ) {
    return InkWell(
      onTap: busy ? null : () => _pickPurchase(context, state),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '구매기록',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(
          _purchase == null
              ? (state.purchaseCandidates.isEmpty
                  ? '입고 대기 구매가 없습니다'
                  : '선택')
              : '${_purchase!.purchasedOn} · ${_purchase!.productName} · 남은 ${_purchase!.remainingQty}',
          style: TextStyle(
            color: _purchase == null
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildReturnPicker(
    BuildContext context,
    StockLedgerLoaded state,
    bool busy,
  ) {
    return InkWell(
      onTap: busy ? null : () => _pickReturn(context, state),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '반품 건',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(
          _returnClaim == null
              ? (state.returnCandidates.isEmpty ? '반품 대기 건이 없습니다' : '선택')
              : '${_returnClaim!.itemName} · 남은 ${_returnClaim!.remainingQty}',
          style: TextStyle(
            color: _returnClaim == null
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _pickProduct(BuildContext context) async {
    final product = await showDialog<Product>(
      context: context,
      builder: (_) => const StockProductPickerDialog(),
    );
    if (product != null && mounted) {
      setState(() => _product = product);
    }
  }

  Future<void> _pickPurchase(
    BuildContext context,
    StockLedgerLoaded state,
  ) async {
    if (state.purchaseCandidates.isEmpty) {
      _snack(context, '입고 대기 중인 구매기록이 없습니다.');
      return;
    }
    final picked = await showModalBottomSheet<PurchaseCandidate>(
      context: context,
      builder: (_) => _PickerSheet(
        title: '입고 대기 구매',
        children: state.purchaseCandidates
            .map((c) => ListTile(
                  dense: true,
                  title: Text(c.productName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${c.purchasedOn} · ${c.sellerName} · 구매 ${c.purchasedQty} / 입고 ${c.receivedQty} · 남은 ${c.remainingQty}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () => Navigator.of(context).pop(c),
                ))
            .toList(),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _purchase = picked;
      // 구매기록의 물품·수량을 그대로 승계한다 — 서버는 판매자 불일치를 400 으로 막는다.
      _product = null;
      _qtyController.text = '${picked.remainingQty > 0 ? picked.remainingQty : 0}';
    });
  }

  Future<void> _pickReturn(
    BuildContext context,
    StockLedgerLoaded state,
  ) async {
    if (state.returnCandidates.isEmpty) {
      _snack(context, '반품 입고 대기 건이 없습니다.');
      return;
    }
    final picked = await showModalBottomSheet<ReturnCandidate>(
      context: context,
      builder: (_) => _PickerSheet(
        title: '반품 입고 대기',
        children: state.returnCandidates
            .map((c) => ListTile(
                  dense: true,
                  title: Text(c.itemName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [
                      if (c.externalOrderId != null) c.externalOrderId!,
                      '반품 ${c.claimQty} / 입고 ${c.receivedQty} · 남은 ${c.remainingQty}',
                      if (c.claimStatus != null) c.claimStatus!,
                      if (c.collectStatus != null) c.collectStatus!,
                    ].join(' · '),
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () => Navigator.of(context).pop(c),
                ))
            .toList(),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _returnClaim = picked;
      _qtyController.text = '${picked.remainingQty > 0 ? picked.remainingQty : 0}';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _movedOn,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) {
      setState(() => _movedOn = picked);
    }
  }

  void _submit(BuildContext context) {
    final productId = _product?.id ?? _purchase?.productId;
    if (productId == null) {
      _snack(context, '상품을 선택하세요.');
      return;
    }
    final quantity = int.tryParse(_qtyController.text.trim());
    if (quantity == null || quantity == 0) {
      _snack(context, '수량을 입력하세요.');
      return;
    }

    context.read<StockLedgerBloc>().add(RecordMovement(
          productId: productId,
          sellerId: _sellerId,
          movementType: _type,
          quantity: quantity,
          reason: _reason,
          reasonNote: _noteController.text,
          unitPrice: double.tryParse(_unitPriceController.text.trim()),
          orderClaimId: _returnClaim?.orderClaimId,
          purchaseRecordId: _purchase?.purchaseRecordId,
          movedOn: _movedOnText,
        ));
  }

  /// 기록 성공 후: 수량만 비우고 다시 포커스를 준다(연속 입력).
  void _afterRecorded() {
    setState(() {
      _qtyController.clear();
      _purchase = null;
      _returnClaim = null;
    });
    _qtyFocusNode.requestFocus();
  }

  /// 하단 내비가 오버레이라 floating + bottom:70 이 필수다.
  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
        ),
      );
  }
}

/// 선택 목록 바텀시트 (구매기록 / 반품 건 공용).
class _PickerSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PickerSheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: ListView(shrinkWrap: true, children: children),
          ),
        ],
      ),
    );
  }
}
