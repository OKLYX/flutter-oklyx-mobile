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

class SellerDetailPage extends StatefulWidget {
  final int sellerId;

  const SellerDetailPage({required this.sellerId});

  @override
  State<SellerDetailPage> createState() => _SellerDetailPageState();
}

class _SellerDetailPageState extends State<SellerDetailPage> {
  bool _isEditing = false;

  void _showDeleteDialog(Seller seller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('판매자 삭제'),
        content: Text('${seller.sellerName}을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SellerDetailBloc>().add(const ConfirmDeleteSeller());
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
      title: '판매자 정보',
      navBarIndex: 2,
      onBackPressed: _isEditing
          ? () => setState(() => _isEditing = false)
          : () => context.go(Routes.sellerPath),
      body: BlocListener<SellerDetailBloc, SellerDetailState>(
        listener: (context, state) {
          if (state is SellerDetailUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('판매자 정보가 수정되었습니다.')),
            );
            context.read<SellerListBloc>().add(const FetchSellers());
            setState(() => _isEditing = false);
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) context.go(Routes.sellerPath);
            });
          } else if (state is SellerDetailDeleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('판매자가 삭제되었습니다.')),
            );
            context.read<SellerListBloc>().add(const FetchSellers());
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) context.go(Routes.sellerPath);
            });
          } else if (state is SellerDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<SellerDetailBloc, SellerDetailState>(
          builder: (context, state) {
            if (state is SellerDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SellerDetailSubmitting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SellerDetailLoaded) {
              return _isEditing
                  ? _SellerEditForm(seller: state.seller)
                  : _SellerDetailsView(
                      seller: state.seller,
                      onEditPressed: () => setState(() => _isEditing = true),
                      onDeletePressed: () => _showDeleteDialog(state.seller),
                    );
            }
            if (state is SellerDetailError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<SellerDetailBloc>().add(LoadSellerDetail(widget.sellerId)),
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

class _SellerDetailsView extends StatelessWidget {
  final Seller seller;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const _SellerDetailsView({
    required this.seller,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'ID: ${seller.id}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),
            _DetailField('판매자명', seller.sellerName),
            _DetailField('사업자등록번호', seller.businessRegistration),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onEditPressed,
                    child: const Text('수정'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: onDeletePressed,
                    child: const Text('삭제'),
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

class _SellerEditForm extends StatefulWidget {
  final Seller seller;

  const _SellerEditForm({required this.seller});

  @override
  State<_SellerEditForm> createState() => _SellerEditFormState();
}

class _SellerEditFormState extends State<_SellerEditForm> {
  late TextEditingController _sellerNameController;
  late TextEditingController _businessRegController;
  Map<String, String?> _validationErrors = {};

  @override
  void initState() {
    super.initState();
    _sellerNameController = TextEditingController(text: widget.seller.sellerName);
    _businessRegController = TextEditingController(text: widget.seller.businessRegistration);
  }

  @override
  void dispose() {
    _sellerNameController.dispose();
    _businessRegController.dispose();
    super.dispose();
  }

  void _validateFields() {
    final errors = <String, String?>{};

    final sellerName = _sellerNameController.text;
    if (sellerName.isEmpty) {
      errors['sellerName'] = '판매자명을 입력해주세요.';
    } else if (sellerName.length > 255) {
      errors['sellerName'] = '최대 255자입니다.';
    } else {
      errors['sellerName'] = null;
    }

    final businessReg = _businessRegController.text;
    if (businessReg.isEmpty) {
      errors['businessRegistration'] = '사업자등록번호를 입력해주세요.';
    } else if (businessReg.length != 10) {
      errors['businessRegistration'] = '10자리 숫자를 입력해주세요.';
    } else if (!RegExp(r'^\d{10}$').hasMatch(businessReg)) {
      errors['businessRegistration'] = '숫자만 입력 가능합니다.';
    } else {
      errors['businessRegistration'] = null;
    }

    setState(() => _validationErrors = errors);
  }

  bool _hasChanges() {
    return _sellerNameController.text != widget.seller.sellerName ||
        _businessRegController.text != widget.seller.businessRegistration;
  }

  bool _hasErrors() {
    return _validationErrors.values.any((error) => error != null);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _sellerNameController,
              decoration: InputDecoration(
                labelText: '판매자명',
                errorText: _validationErrors['sellerName'],
              ),
              onChanged: (_) => _validateFields(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _businessRegController,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: '사업자등록번호',
                hintText: '0000000000',
                errorText: _validationErrors['businessRegistration'],
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _validateFields(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _sellerNameController.text = widget.seller.sellerName;
                      _businessRegController.text = widget.seller.businessRegistration;
                      setState(() => _validationErrors = {});
                      context.read<SellerDetailBloc>().add(LoadSellerDetail(widget.seller.id));
                    },
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: (_hasErrors() || !_hasChanges())
                        ? null
                        : () {
                            context.read<SellerDetailBloc>().add(
                              SubmitSellerUpdateDirect(
                                sellerName: _sellerNameController.text,
                                businessRegistration: _businessRegController.text,
                              ),
                            );
                          },
                    child: const Text('저장'),
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

class _DetailField extends StatelessWidget {
  final String label;
  final String value;

  const _DetailField(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const Divider(),
      ],
    ),
  );
}
