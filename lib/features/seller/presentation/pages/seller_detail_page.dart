import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_detail_event.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_detail_state.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

class SellerDetailPage extends StatefulWidget {
  final int sellerId;

  const SellerDetailPage({required this.sellerId});

  @override
  State<SellerDetailPage> createState() => _SellerDetailPageState();
}

class _SellerDetailPageState extends State<SellerDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<SellerDetailBloc>().add(LoadSellerDetail(widget.sellerId));
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '판매자 정보',
      navBarIndex: 2,
      onBackPressed: () => context.go(Routes.sellerPath),
      body: BlocBuilder<SellerDetailBloc, SellerDetailState>(
        builder: (context, state) {
          if (state is SellerDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SellerDetailLoaded) {
            return _SellerDetailsView(seller: state.seller);
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
    );
  }
}

class _SellerDetailsView extends StatelessWidget {
  final Seller seller;

  const _SellerDetailsView({required this.seller});

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
