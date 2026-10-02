import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_register_bloc.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_register_event.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_register_state.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

class UserRegisterPage extends StatefulWidget {
  const UserRegisterPage({super.key});

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _nameController;
  late final ValueNotifier<String> _emailCheckStatus;

  final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameController = TextEditingController();
    _emailCheckStatus = ValueNotifier<String>('');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailCheckStatus.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) => _emailRegex.hasMatch(email);

  bool _isValidPassword(String password) =>
      password.length >= 8 && password.length <= 20;

  bool _isValidName(String name) =>
      name.length >= 2 && name.length <= 50;

  void _handleEmailComplete(BuildContext context) {
    final email = _emailController.text.trim();
    if (email.isNotEmpty && _isValidEmail(email)) {
      context.read<UserRegisterBloc>().add(EmailCheckRequested(email));
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('회원등록 완료'),
        content: const Text(
          'GUEST 권한으로 등록되었습니다.\n관리자 권한 변경이 필요하신 경우 관리자에게 요청해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go(Routes.userManagePath);
            },
            child: const Text('회원관리로 이동'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _resetForm();
            },
            child: const Text('계속 등록하기'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _emailCheckStatus.value = '';
    context.read<UserRegisterBloc>().add(const UserRegisterInitialEvent());
  }

  void _handleSubmit(BuildContext context) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (!_isValidEmail(email)) {
      showInputNoticeToast(context, '유효한 이메일을 입력해주세요');
      return;
    }

    if (!_isValidPassword(password)) {
      showInputNoticeToast(context, '비밀번호는 8자 이상 20자 이하여야 합니다');
      return;
    }

    if (!_isValidName(name)) {
      showInputNoticeToast(context, '이름은 2자 이상 50자 이하여야 합니다');
      return;
    }

    context.read<UserRegisterBloc>().add(
          RegisterUserRequested(
            email: email,
            password: password,
            name: name,
          ),
        );
  }

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
        title: '회원등록',
        navBarIndex: 0,
        showAppBarDrawerButton: false,
        body: BlocProvider(
          create: (context) => getIt<UserRegisterBloc>(),
          child: BlocListener<UserRegisterBloc, UserRegisterState>(
            listenWhen: (previous, current) =>
                current is UserRegisterSuccess ||
                (current is UserRegisterError &&
                    previous is! UserRegisterInitial),
            listener: (context, state) {
              if (state is UserRegisterSuccess) {
                _showSuccessDialog(context);
              } else if (state is UserRegisterError) {
                showErrorToast(context, state.message);
              }
            },
            child: BlocListener<UserRegisterBloc, UserRegisterState>(
              listenWhen: (previous, current) =>
                  current is EmailAvailable || current is EmailDuplicate,
              listener: (context, state) {
                if (state is EmailAvailable) {
                  _emailCheckStatus.value = '사용 가능';
                } else if (state is EmailDuplicate) {
                  _emailCheckStatus.value = state.message;
                }
              },
              child: AppPageBody.scroll(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '기본 정보',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: '이메일',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() {}),
                      onEditingComplete: () =>
                          _handleEmailComplete(context),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<String>(
                      valueListenable: _emailCheckStatus,
                      builder: (context, status, _) {
                        if (status.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final isError = status != '사용 가능';
                        return Text(
                          status,
                          style: TextStyle(
                            color: isError
                                ? Theme.of(context).colorScheme.error
                                : AppColors.brandGreen,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                    BlocBuilder<UserRegisterBloc, UserRegisterState>(
                      buildWhen: (previous, current) =>
                          current is EmailChecking,
                      builder: (context, state) {
                        if (state is EmailChecking) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              '확인 중...',
                              style: TextStyle(fontSize: 12),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: '비밀번호',
                        errorText: _passwordController.text.isNotEmpty &&
                                !_isValidPassword(_passwordController.text)
                            ? '비밀번호는 8자 이상 20자 이하여야 합니다'
                            : null,
                      ),
                      obscureText: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: '이름',
                        errorText: _nameController.text.isNotEmpty &&
                                !_isValidName(_nameController.text)
                            ? '이름은 2자 이상 50자 이하여야 합니다'
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 32),
                    BlocBuilder<UserRegisterBloc, UserRegisterState>(
                      buildWhen: (previous, current) =>
                          current is EmailChecking ||
                          current is EmailDuplicate ||
                          current is UserRegistering ||
                          current is EmailAvailable ||
                          current is UserRegisterInitial,
                      builder: (context, state) {
                        final isEmailChecking = state is EmailChecking;
                        final isEmailDuplicate = state is EmailDuplicate;
                        final isRegistering = state is UserRegistering;
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;
                        final name = _nameController.text.trim();

                        final isButtonDisabled = isEmailChecking ||
                            isEmailDuplicate ||
                            isRegistering ||
                            email.isEmpty ||
                            !_isValidEmail(email) ||
                            password.isEmpty ||
                            !_isValidPassword(password) ||
                            name.isEmpty ||
                            !_isValidName(name);

                        return SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                isButtonDisabled
                                    ? null
                                    : () => _handleSubmit(context),
                            child: const Text('회원가입'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
