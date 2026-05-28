import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.white,
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
            title: const Text('입출고관리'),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('입출고 관리'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.stockInOutPath);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  title: const Text('입출고 조회'),
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
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
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
