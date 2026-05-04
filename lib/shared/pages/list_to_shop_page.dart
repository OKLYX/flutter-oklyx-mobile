import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';

class ListToShopPage extends StatefulWidget {
  const ListToShopPage({super.key});

  @override
  State<ListToShopPage> createState() => _ListToShopPageState();
}

class _ListToShopPageState extends State<ListToShopPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) => Scaffold(
    key: _scaffoldKey,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('To-Do List'),
      backgroundColor: Colors.white,
      elevation: 0,
    ),
    backgroundColor: Colors.grey[100],
    body: const Center(
      child: Text('List To Shop Page'),
    ),
    bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 2,
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
            context.go(Routes.dashboardPath);
            break;
          case 2:
            // Already on list to shop
            setState(() {});
            break;
          case 3:
            context.go(Routes.notificationPath);
            break;
        }
      },
    ),
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
  );
}
