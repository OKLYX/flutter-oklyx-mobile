import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/user.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_manage_bloc.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_manage_event.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_manage_state.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_drawer.dart';

class UserManagePage extends StatefulWidget {
  const UserManagePage({super.key});

  @override
  State<UserManagePage> createState() => _UserManagePageState();
}

class _UserManagePageState extends State<UserManagePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _previousDrawerState = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSearch(BuildContext context) {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    context.read<UserManageBloc>().add(
          UserSearchRequested(
            name: name,
            email: email,
          ),
        );
  }

  void _handlePageChange(BuildContext context, int page) {
    context.read<UserManageBloc>().add(UserPageChanged(page));
  }

  Color _getRoleBadgeColor(String role) {
    switch (role.toUpperCase()) {
      case 'GUEST':
        return Colors.grey[400]!;
      case 'USER':
        return Colors.blue;
      case 'ADMIN':
        return Colors.red;
      default:
        return Colors.grey[400]!;
    }
  }

  String _formatDate(DateTime dateTime) {
    return dateTime.toString().substring(0, 10);
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) {
      final bloc = getIt<UserManageBloc>();
      bloc.add(const LoadUsersRequested(page: 0, name: null, email: null));
      return bloc;
    },
    child: Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          drawerScrimColor: Colors.black.withOpacity(0.3),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('회원관리'),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          backgroundColor: Colors.grey[100],
          body: BlocListener<UserManageBloc, UserManageState>(
            listenWhen: (previous, current) => current is UserManageError,
            listener: (context, state) {
              if (state is UserManageError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            child: Builder(
              builder: (builderContext) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '사용자 조회',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: '이름',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onSubmitted: (_) => _handleSearch(builderContext),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: '이메일',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onSubmitted: (_) => _handleSearch(builderContext),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _handleSearch(builderContext),
                      child: const Text('조회'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                BlocBuilder<UserManageBloc, UserManageState>(
                  buildWhen: (previous, current) =>
                      current is UserManageLoading ||
                      current is UserManageLoaded ||
                      current is UserManageError,
                  builder: (context, state) {
                    if (state is UserManageLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (state is UserManageLoaded) {
                      if (state.users.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('조회 결과가 없습니다'),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('No.')),
                                DataColumn(label: Text('이름')),
                                DataColumn(label: Text('이메일')),
                                DataColumn(label: Text('역할')),
                                DataColumn(label: Text('가입일')),
                              ],
                              rows: List<DataRow>.generate(
                                state.users.length,
                                (index) {
                                  final user = state.users[index];
                                  final rowNumber =
                                      (state.currentPage * 20) + index + 1;
                                  final badgeColor =
                                      _getRoleBadgeColor(user.role);

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        GestureDetector(
                                          onTap: () =>
                                              _navigateToUserEdit(context, user),
                                          child: Text('$rowNumber'),
                                        ),
                                      ),
                                      DataCell(
                                        GestureDetector(
                                          onTap: () =>
                                              _navigateToUserEdit(context, user),
                                          child: Text(user.name),
                                        ),
                                      ),
                                      DataCell(
                                        GestureDetector(
                                          onTap: () =>
                                              _navigateToUserEdit(context, user),
                                          child: Text(user.email),
                                        ),
                                      ),
                                      DataCell(
                                        GestureDetector(
                                          onTap: () =>
                                              _navigateToUserEdit(context, user),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeColor,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              user.role,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        GestureDetector(
                                          onTap: () =>
                                              _navigateToUserEdit(context, user),
                                          child: Text(_formatDate(user.createdAt)),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          if (state.totalPages > 1) ...[
                            const SizedBox(height: 24),
                            _buildPaginationBar(state, builderContext),
                          ],
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
              ),
            ),
          ),
        bottomNavigationBar: SizedBox.shrink(),
        drawer: const AppDrawer(),
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
              selectedItemColor: const Color(0xffffc417),
              currentIndex: 0,
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
                    context.go(Routes.dashboardPath);
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
    ),
  );

  Widget _buildPaginationBar(UserManageLoaded state, BuildContext context) {
    final currentPage = state.currentPage;
    final totalPages = state.totalPages;

    int startPage = (currentPage - 2).clamp(0, totalPages - 5);
    int endPage = (startPage + 5).clamp(5, totalPages);
    if (endPage - startPage < 5) {
      startPage = (endPage - 5).clamp(0, totalPages - 1);
    }

    return Center(
      child: Wrap(
        spacing: 4,
        children: [
          if (currentPage > 0)
            ElevatedButton(
              onPressed: () => _handlePageChange(context, currentPage - 1),
              child: const Text('이전'),
            )
          else
            ElevatedButton(
              onPressed: null,
              child: const Text('이전'),
            ),
          ...List<int>.generate(
            endPage - startPage,
            (index) => startPage + index,
          ).map((pageNum) {
            final isCurrentPage = pageNum == currentPage;
            return ElevatedButton(
              onPressed: isCurrentPage ? null : () => _handlePageChange(context, pageNum),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCurrentPage ? Colors.blue : Colors.white,
                foregroundColor:
                    isCurrentPage ? Colors.white : Colors.black,
              ),
              child: Text('${pageNum + 1}'),
            );
          }).toList(),
          if (currentPage < totalPages - 1)
            ElevatedButton(
              onPressed: () => _handlePageChange(context, currentPage + 1),
              child: const Text('다음'),
            )
          else
            ElevatedButton(
              onPressed: null,
              child: const Text('다음'),
            ),
        ],
      ),
    );
  }

  Future<void> _navigateToUserEdit(BuildContext context, User user) async {
    final updatedUser = await context.pushNamed(
      Routes.userEdit,
      extra: user,
    );

    if (updatedUser != null && updatedUser is User) {
      _updateUserInList(updatedUser);
    }
  }

  void _updateUserInList(User updatedUser) {
    context.read<UserManageBloc>().add(UserListItemUpdated(updatedUser));
  }
}
