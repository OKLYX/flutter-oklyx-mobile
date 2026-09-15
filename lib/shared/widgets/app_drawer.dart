import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/alert/presentation/bloc/alert_summary_bloc.dart';
import 'package:flutter_oklyn_mobile/features/alert/presentation/bloc/alert_summary_event.dart';
import 'package:flutter_oklyn_mobile/features/alert/presentation/bloc/alert_summary_state.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/alert_badge.dart';

/// 전 페이지 공통 Drawer.
///
/// 🔴 **StatefulWidget 인 이유**: Scaffold 의 drawer 는 **열릴 때 빌드**되므로 `initState` 가
/// 곧 "열림" 트리거다 — 배지 숫자를 여기서 갱신한다([AlertSummaryBloc]).
/// 타이머·`onDrawerChanged` 배선을 새로 만들지 말 것(FEATURE_2609_49 / D9).
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  void initState() {
    super.initState();
    // Drawer 가 열릴 때마다 한 번. 닫혀 있는 동안은 폴링하지 않는다.
    context.read<AlertSummaryBloc>().add(LoadAlertSummary());
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: const Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          ExpansionTile(
            shape: const Border(),
            title: const Text('판매상품'),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('판매상품 조회'),
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed(Routes.salesProducts);
                  },
                ),
              ),
            ],
          ),
          BlocBuilder<AlertSummaryBloc, AlertSummaryState>(
            builder: (context, alerts) => ExpansionTile(
            shape: const Border(),
            // 접혀 있으면 항목이 안 보이므로 헤더에 합계를 둔다. ExpansionTile 의 trailing 은
            // 화살표가 쓰므로 title 안에 넣는다.
            title: Row(
              children: [
                const Text('주문관리'),
                AlertBadge(count: alerts.total),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('출고관리'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.shipmentManagementPath);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('주문내역'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.orderHistoryPath);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  // 라벨은 지금부터 '반품/교환' — 교환 탭이 붙어도 메뉴 이름이 바뀌지 않는다.
                  title: const Text('반품/교환'),
                  // ⚠️ 목록 화면의 행 수와 다를 수 있다 — 배지는 전 타입·전 기간이다.
                  trailing: AlertBadge(count: alerts.openClaims),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.claimListPath);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('고객문의'),
                  trailing: AlertBadge(count: alerts.unansweredInquiries),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.inquiryListPath);
                  },
                ),
              ),
            ],
          ),
          ),
          ExpansionTile(
            shape: const Border(),
            title: const Text('구매관리'),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('구매목록'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.listToShopPath);
                  },
                ),
              ),
            ],
          ),
          ExpansionTile(
            shape: const Border(),
            title: const Text('상품관리'),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('상품등록'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.productRegisterPath);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('상품조회'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.productSearchPath);
                  },
                ),
              ),
            ],
          ),
          ExpansionTile(
            shape: const Border(),
            title: const Text('재고관리'),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('입고·조정'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.stockInOutPath);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('출고 확인'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.stockOutboundPath);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('재고 조회'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.stockSearchPath);
                  },
                ),
              ),
            ],
          ),
          ExpansionTile(
            shape: const Border(),
            title: const Text('비용관리'),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('택배비'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.carrierRatePath);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('택배사 관리'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.carrierPath);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('상자비'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.packageSearchPath);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('카테고리'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.categoryListPath);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('수수료'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.commissionRatePath);
                  },
                ),
              ),
            ],
          ),
          ExpansionTile(
            shape: const Border(),
            title: const Text('판매자 관리'),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('판매자 관리'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.sellerPath);
                  },
                ),
              ),
            ],
          ),
          ExpansionTile(
            shape: const Border(),
            title: const Text('회원관리'),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('회원등록'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.userRegisterPath);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('회원관리'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.userManagePath);
                  },
                ),
              ),
            ],
          ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(Routes.loginPath);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('로그아웃'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
