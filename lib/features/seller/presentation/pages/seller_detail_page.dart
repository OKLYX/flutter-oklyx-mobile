import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_detail_event.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_detail_state.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_list_event.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';

class SellerDetailPage extends StatefulWidget {
  final int sellerId;

  const SellerDetailPage({required this.sellerId});

  @override
  State<SellerDetailPage> createState() => _SellerDetailPageState();
}

class _SellerDetailPageState extends State<SellerDetailPage> {
  late final SellerDetailBloc _sellerDetailBloc;
  bool _isEditing = false;

  late TextEditingController _sellerNameController;
  late TextEditingController _businessRegController;

  @override
  void initState() {
    super.initState();
    _sellerDetailBloc = context.read<SellerDetailBloc>();
    _initializeControllers();
  }

  void _initializeControllers() {
    _sellerNameController = TextEditingController();
    _businessRegController = TextEditingController();
  }

  @override
  void dispose() {
    _sellerNameController.dispose();
    _businessRegController.dispose();
    super.dispose();
  }

  void _populateControllers(Seller seller) {
    _sellerNameController.text = seller.sellerName;
    _businessRegController.text = seller.businessRegistration;
  }

  Future<void> _showDeleteDialog(BuildContext context, Seller seller) async {
    final ok = await showAppConfirmDialog(
      context,
      title: '판매자 삭제',
      message: '${seller.sellerName}을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '삭제',
      isDangerous: true,
    );
    if (!ok) {
      return;
    }
    _sellerDetailBloc.add(const ConfirmDeleteSeller());
  }

  void _onCancel() {
    setState(() => _isEditing = false);
  }

  void _onSave() {
    _sellerDetailBloc.add(SubmitSellerUpdateDirect(
      sellerName: _sellerNameController.text.trim(),
      businessRegistration: _businessRegController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
    title: '판매자 정보',
    navBarIndex: 2,
    onBackPressed: _isEditing
        ? () => setState(() => _isEditing = false)
        : () => context.go(Routes.sellerPath),
    body: BlocProvider.value(
      value: _sellerDetailBloc,
      child: BlocListener<SellerDetailBloc, SellerDetailState>(
        listener: (context, state) {
          if (state is SellerDetailLoaded) {
            _populateControllers(state.seller);
            if (_isEditing) {
              setState(() => _isEditing = false);
            }
          }
          if (state is SellerDetailUpdateSuccess) {
            showSuccessToast(context, '판매자 정보가 수정되었습니다.');
            context.read<SellerListBloc>().add(const FetchSellers());
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) context.go(Routes.sellerPath);
            });
          } else if (state is SellerDetailDeleteSuccess) {
            showSuccessToast(context, '판매자가 삭제되었습니다.');
            context.read<SellerListBloc>().add(const FetchSellers());
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) context.go(Routes.sellerPath);
            });
          } else if (state is SellerDetailError) {
            showErrorToast(context, state.message);
          }
        },
        child: BlocBuilder<SellerDetailBloc, SellerDetailState>(
          buildWhen: (previous, current) =>
              current is SellerDetailLoading ||
              current is SellerDetailError ||
              current is SellerDetailLoaded,
          builder: (context, state) {
            if (state is SellerDetailLoading) {
              return const AppPageBody(children: [AppLoading()]);
            }

            if (state is SellerDetailError) {
              return AppPageBody(
                children: [
                  AppErrorBox(
                    message: state.message,
                    action: FilledButton(
                      onPressed: () => _sellerDetailBloc.add(LoadSellerDetail(widget.sellerId)),
                      child: const Text('다시 시도'),
                    ),
                  ),
                ],
              );
            }

            if (state is SellerDetailLoaded) {
              final seller = state.seller;
              return AppPageBody.scroll(
                child: Column(
                  children: [
                    if (_isEditing)
                      _EditableBasicInfoCard(
                        seller: seller,
                        sellerNameController: _sellerNameController,
                        businessRegController: _businessRegController,
                      )
                    else
                      _BasicInfoCard(seller: seller),
                    const SizedBox(height: 12),
                    if (!_isEditing) ...[
                      _DetailsCard(seller: seller),
                      const SizedBox(height: 12),
                      _ActionCard(
                        onEditPressed: () => setState(() => _isEditing = true),
                        onDeletePressed: () => _showDeleteDialog(context, seller),
                      ),
                    ],
                    if (_isEditing)
                      _EditActionCard(
                        onSavePressed: _onSave,
                        onCancelPressed: _onCancel,
                      ),
                    const SizedBox(height: 12),
                    _TimestampsCard(seller: seller),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
}

class _BasicInfoCard extends StatelessWidget {
  final Seller seller;

  const _BasicInfoCard({required this.seller});

  @override
  Widget build(BuildContext context) {
    return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seller.sellerName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${seller.id}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final Seller seller;

  const _DetailsCard({required this.seller});

  @override
  Widget build(BuildContext context) {
    return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('사업자등록번호: '),
                Text(
                  seller.businessRegistration,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _EditableBasicInfoCard extends StatelessWidget {
  final Seller seller;
  final TextEditingController sellerNameController;
  final TextEditingController businessRegController;

  const _EditableBasicInfoCard({
    required this.seller,
    required this.sellerNameController,
    required this.businessRegController,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: sellerNameController,
              decoration: InputDecoration(
                labelText: '판매자명',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: businessRegController,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: '사업자등록번호',
                hintText: '0000000000',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${seller.id}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const _ActionCard({
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
        child: Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: onEditPressed,
                child: const Text('수정'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: onDeletePressed,
                child: const Text('삭제'),
              ),
            ),
          ],
        ),
    );
  }
}

class _EditActionCard extends StatelessWidget {
  final VoidCallback onSavePressed;
  final VoidCallback onCancelPressed;

  const _EditActionCard({
    required this.onSavePressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancelPressed,
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onSavePressed,
                child: const Text('저장'),
              ),
            ),
          ],
        ),
    );
  }
}

class _TimestampsCard extends StatelessWidget {
  final Seller seller;

  const _TimestampsCard({required this.seller});

  @override
  Widget build(BuildContext context) {
    return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기본 정보',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('생성: '),
                Text(
                  seller.createdDate,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('수정: '),
                Text(
                  seller.modifiedDate,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}
