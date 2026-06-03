import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_create_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_create_event.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_create_state.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_list_event.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

class SellerCreatePage extends StatefulWidget {
  const SellerCreatePage({super.key});

  @override
  State<SellerCreatePage> createState() => _SellerCreatePageState();
}

class _SellerCreatePageState extends State<SellerCreatePage> {
  final _sellerNameCtrl = TextEditingController();
  final _businessRegCtrl = TextEditingController();
  final _initialFormData = {'sellerName': '', 'businessRegistration': ''};

  @override
  void initState() {
    super.initState();
    context.read<SellerCreateBloc>().add(const ResetCreateForm());
  }

  @override
  void dispose() {
    _sellerNameCtrl.dispose();
    _businessRegCtrl.dispose();
    super.dispose();
  }

  bool _isSubmitEnabled(SellerCreateLoaded state) {
    final hasErrors = state.validationErrors.values.any((e) => e != null);
    final isChanged = state.formData != _initialFormData;
    return !hasErrors && isChanged;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '판매자 추가',
      navBarIndex: 2,
      onBackPressed: () => context.pop(),
      body: BlocListener<SellerCreateBloc, SellerCreateState>(
        listener: (context, state) {
          if (state is SellerCreateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('판매자가 추가되었습니다.'),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(bottom: 70, left: 16, right: 16),
              ),
            );
            GetIt.instance<SellerListBloc>().add(const FetchSellers());
            Future.delayed(const Duration(milliseconds: 500), () {
              context.pop();
            });
          } else if (state is SellerCreateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(bottom: 70, left: 16, right: 16),
              ),
            );
          }
        },
        child: BlocBuilder<SellerCreateBloc, SellerCreateState>(
          builder: (context, state) {
            if (state is! SellerCreateLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final isSubmitting = state is SellerCreateLoading;
            final isEnabled = _isSubmitEnabled(state);
            final bloc = context.read<SellerCreateBloc>();

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _sellerNameCtrl,
                      enabled: !isSubmitting,
                      maxLength: 255,
                      decoration: InputDecoration(
                        labelText: '판매자명',
                        errorText: state.validationErrors['sellerName'],
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) =>
                          bloc.add(UpdateFormField(field: 'sellerName', value: v)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _businessRegCtrl,
                      enabled: !isSubmitting,
                      maxLength: 10,
                      decoration: InputDecoration(
                        labelText: '사업자등록번호 (10자리)',
                        hintText: '1234567890',
                        errorText: state.validationErrors['businessRegistration'],
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => bloc
                          .add(UpdateFormField(field: 'businessRegistration', value: v)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : () => context.pop(),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (isSubmitting || !isEnabled)
                                ? null
                                : () => bloc.add(const SubmitSellerCreate()),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('추가'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
