import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/user.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_manage_bloc.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_manage_event.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_manage_state.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_search_field.dart';

class UserManagePage extends StatefulWidget {
  const UserManagePage({super.key});

  @override
  State<UserManagePage> createState() => _UserManagePageState();
}

class _UserManagePageState extends State<UserManagePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
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
    child: ScaffoldWithNavBar(
      title: '회원관리',
      navBarIndex: 0,
      showAppBarDrawerButton: false,
      body: BlocListener<UserManageBloc, UserManageState>(
        listenWhen: (previous, current) => current is UserManageError,
        listener: (context, state) {
          if (state is UserManageError) {
            showErrorToast(context, state.message);
          }
        },
        child: Builder(
          builder: (builderContext) => AppPageBody.scroll(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '사용자 조회',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: AppSearchField(
                          controller: _nameController,
                          hintText: '이름',
                          onSubmitted: (_) => _handleSearch(builderContext),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppSearchField(
                          controller: _emailController,
                          hintText: '이메일',
                          onSubmitted: (_) => _handleSearch(builderContext),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => _handleSearch(builderContext),
                        child: const Text('조회'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<UserManageBloc, UserManageState>(
                  buildWhen: (previous, current) =>
                      current is UserManageLoading ||
                      current is UserManageLoaded ||
                      current is UserManageError,
                  builder: (context, state) {
                    if (state is UserManageLoading) {
                      return const AppLoading();
                    }

                    if (state is UserManageLoaded) {
                      if (state.users.isEmpty) {
                        return const AppEmpty('조회 결과가 없습니다');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < state.users.length; i++) ...[
                            if (i > 0) const AppRowGap(),
                            AppCard.row(
                              onTap: () =>
                                  _navigateToUserEdit(context, state.users[i]),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.users[i].name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('이메일: ${state.users[i].email}'),
                                  Text('역할: ${state.users[i].role}'),
                                  Text(
                                    '가입일: ${_formatDate(state.users[i].createdAt)}',
                                  ),
                                ],
                              ),
                            ),
                          ],
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
            FilledButton(
              onPressed: () => _handlePageChange(context, currentPage - 1),
              child: const Text('이전'),
            )
          else
            FilledButton(
              onPressed: null,
              child: const Text('이전'),
            ),
          ...List<int>.generate(
            endPage - startPage,
            (index) => startPage + index,
          ).map((pageNum) {
            final isCurrentPage = pageNum == currentPage;
            return FilledButton(
              onPressed: isCurrentPage ? null : () => _handlePageChange(context, pageNum),
              style: FilledButton.styleFrom(
                backgroundColor: isCurrentPage
                    ? AppColors.brandMain
                    : Theme.of(context).colorScheme.surface,
                foregroundColor: isCurrentPage
                    ? AppColors.foregroundLight
                    : Theme.of(context).colorScheme.onSurface,
              ),
              child: Text('${pageNum + 1}'),
            );
          }).toList(),
          if (currentPage < totalPages - 1)
            FilledButton(
              onPressed: () => _handlePageChange(context, currentPage + 1),
              child: const Text('다음'),
            )
          else
            FilledButton(
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
