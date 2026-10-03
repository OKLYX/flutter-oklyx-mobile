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
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_search_field.dart';

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

  Future<void> _confirmDelete(Carrier carrier) async {
    final bloc = context.read<CarrierFormBloc>();
    final ok = await showAppConfirmDialog(
      context,
      title: '삭제 확인',
      message: '"${carrier.name}" 택배사를 삭제하시겠습니까?\n이 작업은 취소할 수 없습니다.',
      confirmText: '삭제',
      isDangerous: true,
    );
    if (!ok) {
      return;
    }
    bloc.add(DeleteCarrier(id: carrier.id));
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
            showSuccessToast(context, state.message);
            context.read<CarrierListBloc>().add(FetchCarriers());
          } else if (state is CarrierFormError) {
            showErrorToast(context, state.message);
          }
        },
        child: AppPageBody.slivers(
          slivers: [
            SliverToBoxAdapter(
              child: AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: AppSearchField(
                        controller: _searchController,
                        hintText: '택배사명 검색...',
                        onChanged: (value) {
                          context
                              .read<CarrierListBloc>()
                              .add(SearchCarriers(query: value));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _openCreateDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('추가'),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            BlocBuilder<CarrierListBloc, CarrierListState>(
              builder: (context, state) {
                if (state is CarrierListLoading) {
                  return const SliverToBoxAdapter(child: AppLoading());
                }
                if (state is CarrierListEmpty) {
                  return const SliverToBoxAdapter(
                    child: AppEmpty('조회 결과가 없습니다.'),
                  );
                }
                if (state is CarrierListError) {
                  return SliverToBoxAdapter(
                    child: AppErrorBox(
                      message: state.message,
                      action: FilledButton(
                        onPressed: () =>
                            context.read<CarrierListBloc>().add(FetchCarriers()),
                        child: const Text('다시 시도'),
                      ),
                    ),
                  );
                }
                if (state is CarrierListLoaded) {
                  return SliverList.separated(
                    itemCount: state.carriers.length,
                    separatorBuilder: (context, index) => const AppRowGap(),
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
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
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
    return AppCard.flush(
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
                  icon: Icon(
                    Icons.delete,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
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
        color: isActive
            ? AppColors.successSurface
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? '활성' : '비활성',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isActive
              ? AppColors.successForeground
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
