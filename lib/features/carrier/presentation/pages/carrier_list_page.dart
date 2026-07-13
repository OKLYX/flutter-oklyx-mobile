import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/carrier.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/carrier_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/carrier_list_event.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/carrier_list_state.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/carrier_form_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/carrier_form_event.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/carrier_form_state.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/dialogs/carrier_input_dialog.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/widgets/platform_code_section.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

class CarrierListPage extends StatefulWidget {
  const CarrierListPage({super.key});

  @override
  State<CarrierListPage> createState() => _CarrierListPageState();
}

class _CarrierListPageState extends State<CarrierListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CarrierListBloc>().add(FetchCarriers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    // Bottom nav 가 overlay 로 떠 있으므로 SnackBar 는 floating + 하단 여백으로 띄운다.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : null,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
      ),
    );
  }

  void _openCreateDialog() {
    final bloc = context.read<CarrierFormBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const CarrierInputDialog(),
      ),
    );
  }

  void _openEditDialog(Carrier carrier) {
    final bloc = context.read<CarrierFormBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: CarrierInputDialog(carrier: carrier),
      ),
    );
  }

  void _confirmDelete(Carrier carrier) {
    final bloc = context.read<CarrierFormBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('"${carrier.name}" 택배사를 삭제하시겠습니까?\n이 작업은 취소할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(DeleteCarrier(id: carrier.id));
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '택배사',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: BlocListener<CarrierFormBloc, CarrierFormState>(
        listener: (context, state) {
          if (state is CarrierFormSuccess) {
            _showSnackBar(state.message);
            context.read<CarrierListBloc>().add(FetchCarriers());
          } else if (state is CarrierFormError) {
            _showSnackBar(state.message, isError: true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: '택배사명 검색...',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        context
                            .read<CarrierListBloc>()
                            .add(SearchCarriers(query: value));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('추가'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<CarrierListBloc, CarrierListState>(
                  builder: (context, state) {
                    if (state is CarrierListLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is CarrierListEmpty) {
                      return const Center(child: Text('조회 결과가 없습니다.'));
                    }
                    if (state is CarrierListError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(state.message),
                            ElevatedButton(
                              onPressed: () => context
                                  .read<CarrierListBloc>()
                                  .add(FetchCarriers()),
                              child: const Text('재시도'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state is CarrierListLoaded) {
                      return ListView.builder(
                        itemCount: state.carriers.length,
                        itemBuilder: (context, index) {
                          final carrier = state.carriers[index];
                          return _CarrierCard(
                            carrier: carrier,
                            onEdit: () => _openEditDialog(carrier),
                            onDelete: () => _confirmDelete(carrier),
                            onToggle: () => context
                                .read<CarrierFormBloc>()
                                .add(ToggleActive(carrier: carrier)),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 택배사 카드 — 탭 시 펼쳐서 플랫폼 코드 섹션을 노출한다.
class _CarrierCard extends StatelessWidget {
  final Carrier carrier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _CarrierCard({
    required this.carrier,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                carrier.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            _StatusChip(isActive: carrier.isActive),
          ],
        ),
        childrenPadding: EdgeInsets.zero,
        children: [
          // 액션 바: 활성토글 · 수정 · 삭제
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    carrier.isActive ? Icons.toggle_on : Icons.toggle_off,
                    size: 20,
                  ),
                  label: Text(carrier.isActive ? '비활성화' : '활성화'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  tooltip: '수정',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: '삭제',
                ),
              ],
            ),
          ),
          PlatformCodeSection(carrierId: carrier.id),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? '활성' : '비활성',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
        ),
      ),
    );
  }
}
