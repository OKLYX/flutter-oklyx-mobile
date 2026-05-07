import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _previousDrawerState = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      final isOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
      if (isOpen != _previousDrawerState) {
        _previousDrawerState = isOpen;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Scaffold(
        key: _scaffoldKey,
        drawerScrimColor: Colors.black.withOpacity(0.3),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: SizedBox(
            height: 30,
            child: Image.asset(
              'assets/images/oklyx_letter_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: Colors.grey[100],
        drawer: Drawer(
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
            ],
          ),
        ),
        body: const Center(
          child: Text('Dashboard Page'),
        ),
        bottomNavigationBar: SizedBox.shrink(),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Builder(
          builder: (context) {
            final isDrawerOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;

            return BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 1,
              selectedItemColor: const Color(0xffffc417),
              items: [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.menu,
                    color: isDrawerOpen ? const Color(0xffffc417) : Colors.black87,
                  ),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.checklist),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.notifications),
                  label: '',
                ),
              ],
              onTap: (index) {
                switch (index) {
                  case 0:
                    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                      Navigator.pop(context);
                    } else {
                      _scaffoldKey.currentState?.openDrawer();
                    }
                    setState(() {});
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() {});
                    });
                    break;
                  case 1:
                    // Already on dashboard
                    setState(() {});
                    break;
                  case 2:
                    context.go(Routes.listToShopPath);
                    break;
                  case 3:
                    context.go(Routes.notificationPath);
                    break;
                }
              },
            );
          },
        ),
      ),
    ],
  );
}
