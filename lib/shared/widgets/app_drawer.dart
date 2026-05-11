import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
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
        ],
      ),
    );
  }
}
