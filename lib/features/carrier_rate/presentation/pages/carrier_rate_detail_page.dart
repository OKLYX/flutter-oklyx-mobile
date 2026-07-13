import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/carrier.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/entities/carrier_rate.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/presentation/bloc/carrier_rate_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/presentation/bloc/carrier_rate_detail_event.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/presentation/bloc/carrier_rate_detail_state.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/presentation/bloc/carrier_rate_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/presentation/bloc/carrier_rate_list_event.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

class CarrierRateDetailPage extends StatefulWidget {
  final int carrierRateId;
  const CarrierRateDetailPage({required this.carrierRateId});

  @override
  State<CarrierRateDetailPage> createState() => _CarrierRateDetailPageState();
}

class _CarrierRateDetailPageState extends State<CarrierRateDetailPage> {
  bool _isEditing = false;

  void _showDeleteDialog(BuildContext context, CarrierRate carrierRate) {
    showDialog(
      context: context,
      builder: (ctx) => _DeleteConfirmationDialog(
        carrierRate: carrierRate,
        onConfirm: () {
          Navigator.pop(ctx);
          context.read<CarrierRateDetailBloc>().add(
                ConfirmDeleteCarrierRate(carrierRate.id),
              );
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '택배비 정보',
      navBarIndex: 2,
      onBackPressed: () {
        if (_isEditing) {
          setState(() => _isEditing = false);
        } else {
          context.go(Routes.carrierRatePath);
        }
      },
      body: BlocListener<CarrierRateDetailBloc, CarrierRateDetailState>(
        listener: (context, state) {
          if (state is CarrierRateDetailSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('택배비가 수정되었습니다.')),
            );
            context.read<CarrierRateListBloc>().add(FetchCarrierRates());
            setState(() => _isEditing = false);
            context.go(Routes.carrierRatePath);
          } else if (state is CarrierRateDetailDeleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('택배비가 삭제되었습니다.')),
            );
            context.read<CarrierRateListBloc>().add(FetchCarrierRates());
            context.go(Routes.carrierRatePath);
          } else if (state is CarrierRateDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<CarrierRateDetailBloc, CarrierRateDetailState>(
          builder: (context, state) {
            final bloc = context.read<CarrierRateDetailBloc>();
            if (state is CarrierRateDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CarrierRateDetailLoaded) {
              // Resolve carrier name from loaded carriers for display.
              String carrierName = '';
              for (final c in state.carriers) {
                if (c.id == state.carrierId) {
                  carrierName = c.name;
                  break;
                }
              }
              final carrierRate = CarrierRate(
                id: widget.carrierRateId,
                carrierId: state.carrierId ?? 0,
                carrier: carrierName,
                type: state.type.value,
                cost: state.cost.value,
                effectiveDate: state.effectiveDate.value,
                isDefault: state.isDefault,
              );
              return _CarrierRateDetailsView(
                carrierRate: carrierRate,
                carriers: state.carriers,
                carriersLoading: state.carriersLoading,
                isEditing: _isEditing,
                onEditChange: (editing) => setState(() => _isEditing = editing),
                onDeletePressed: () => _showDeleteDialog(context, carrierRate),
              );
            }
            if (state is CarrierRateDetailError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => bloc.add(FetchCarrierRateDetail(widget.carrierRateId)),
                      child: const Text('재시도'),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _CarrierRateDetailsView extends StatefulWidget {
  final CarrierRate carrierRate;
  final List<Carrier> carriers;
  final bool carriersLoading;
  final bool isEditing;
  final Function(bool) onEditChange;
  final VoidCallback onDeletePressed;
  const _CarrierRateDetailsView({
    required this.carrierRate,
    required this.carriers,
    required this.carriersLoading,
    required this.isEditing,
    required this.onEditChange,
    required this.onDeletePressed,
  });

  @override
  State<_CarrierRateDetailsView> createState() => _CarrierRateDetailsViewState();
}

class _CarrierRateDetailsViewState extends State<_CarrierRateDetailsView> {
  late TextEditingController _typeCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _dateCtrl;

  @override
  void initState() {
    super.initState();
    _typeCtrl = TextEditingController(text: widget.carrierRate.type);
    _costCtrl = TextEditingController(
      text: widget.carrierRate.cost.toInt().toString(),
    );
    _dateCtrl = TextEditingController(text: widget.carrierRate.effectiveDate);
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _costCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Widget _buildCarrierDropdown() {
    final decoration = const InputDecoration(
      labelText: '배송사',
      border: OutlineInputBorder(),
    );

    if (widget.carriersLoading) {
      return InputDecorator(
        decoration: decoration,
        child: const SizedBox(
          height: 20,
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('택배사 불러오는 중...'),
            ],
          ),
        ),
      );
    }

    final items = <DropdownMenuItem<int>>[
      for (final c in widget.carriers.where((c) => c.isActive))
        DropdownMenuItem<int>(value: c.id, child: Text(c.name)),
    ];

    // Keep the current carrierId selectable even if inactive/missing.
    final cid = widget.carrierRate.carrierId;
    if (cid != 0 && !items.any((it) => it.value == cid)) {
      final match = widget.carriers.where((c) => c.id == cid);
      if (match.isNotEmpty) {
        items.add(DropdownMenuItem<int>(value: cid, child: Text(match.first.name)));
      }
    }

    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            decoration: decoration,
            items: const [],
            onChanged: null,
          ),
          const SizedBox(height: 4),
          Text(
            '등록된 택배사가 없습니다',
            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
          ),
        ],
      );
    }

    return DropdownButtonFormField<int>(
      value: cid != 0 ? cid : null,
      decoration: decoration,
      items: items,
      onChanged: (value) {
        if (value != null) {
          context.read<CarrierRateDetailBloc>().add(CarrierIdDetailChanged(value));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('###,##0', 'ko_KR');

    if (!widget.isEditing) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${widget.carrierRate.id}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          widget.onEditChange(true);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('수정'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: widget.onDeletePressed,
                        icon: const Icon(Icons.delete),
                        label: const Text('삭제'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailField('배송사', widget.carrierRate.carrier),
              _DetailField('타입', widget.carrierRate.type),
              _DetailField('비용', '${fmt.format(widget.carrierRate.cost.toInt())}원'),
              _DetailField('유효일', widget.carrierRate.effectiveDate),
              _DetailField(
                '기본값',
                widget.carrierRate.isDefault ? '예' : '아니오',
              ),
            ],
          ),
        ),
      );
    }

    // Edit form
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCarrierDropdown(),
            const SizedBox(height: 16),
            _FormField(
              '타입',
              _typeCtrl,
              (v) => context.read<CarrierRateDetailBloc>().add(TypeDetailChanged(v)),
            ),
            _FormField(
              '비용',
              _costCtrl,
              (v) => context.read<CarrierRateDetailBloc>().add(CostDetailChanged(v)),
              keyboardType: TextInputType.number,
            ),
            _FormField(
              '유효일',
              _dateCtrl,
              (v) => context
                  .read<CarrierRateDetailBloc>()
                  .add(EffectiveDateDetailChanged(v)),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('기본값으로 설정'),
              value: widget.carrierRate.isDefault,
              onChanged: (v) => context.read<CarrierRateDetailBloc>().add(
                    IsDefaultDetailChanged(v ?? false),
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onEditChange(false),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<CarrierRateDetailBloc>().add(
                            UpdateCarrierRateSubmitted(widget.carrierRate.id),
                          );
                    },
                    child: const Text('수정'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Function(String) onChanged;
  final TextInputType keyboardType;

  const _FormField(
    this.label,
    this.controller,
    this.onChanged, {
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    ),
  );
}

class _DetailField extends StatelessWidget {
  final String label, value;
  const _DetailField(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const Divider(),
      ],
    ),
  );
}

class _DeleteConfirmationDialog extends StatelessWidget {
  final CarrierRate carrierRate;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DeleteConfirmationDialog({
    required this.carrierRate,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('택배비 삭제'),
      content: Text(
        '${carrierRate.carrier}의 ${carrierRate.type}을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('삭제'),
        ),
      ],
    );
  }
}
