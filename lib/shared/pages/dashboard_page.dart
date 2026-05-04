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

  @override
  Widget build(BuildContext context) => Scaffold(
    key: _scaffoldKey,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text(
        'OKLYX',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
    ),
    backgroundColor: Colors.grey[100],
    drawer: Drawer(
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
          ListTile(
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go(Routes.dashboardPath);
            },
          ),
          ListTile(
            title: const Text('To-Do List'),
            onTap: () {
              Navigator.pop(context);
              context.go(Routes.listToShopPath);
            },
          ),
          ListTile(
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              context.go(Routes.notificationPath);
            },
          ),
        ],
      ),
    ),
    body: const Center(
      child: Text('Dashboard Page'),
    ),
    bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 1,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.menu),
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
            _scaffoldKey.currentState?.openDrawer();
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
    ),
  );
}
