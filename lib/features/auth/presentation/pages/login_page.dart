import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_oklyn_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_oklyn_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_oklyn_mobile/features/auth/presentation/widgets/email_field.dart';
import 'package:flutter_oklyn_mobile/features/auth/presentation/widgets/password_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late EmailField _emailField;
  late PasswordField _passwordField;
  bool _submitAttempted = false;

  @override
  void initState() {
    super.initState();
    _emailField = const EmailField.pure();
    _passwordField = const PasswordField.pure();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              } else if (state is AuthAuthenticated) {
                context.go(Routes.dashboardPath);
              }
            },
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Center(
                      child: SizedBox(
                        height: 120,
                        child: Image.asset(
                          'assets/images/oclyx_letter_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  onChanged: (email) {
                                    _emailField =
                                        EmailField.dirty(value: email);
                                    setState(() {});
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    errorText:
                                        _submitAttempted && _emailField.invalid
                                            ? _emailField.error
                                            : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          const BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppColors.brandMain, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  onChanged: (password) {
                                    _passwordField =
                                        PasswordField.dirty(value: password);
                                    setState(() {});
                                  },
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    errorText: _submitAttempted &&
                                            _passwordField.invalid
                                        ? _passwordField.error
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          const BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppColors.brandMain, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandMain,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: state is! AuthLoading
                              ? () {
                                  setState(() => _submitAttempted = true);
                                  if (_emailField.valid &&
                                      _passwordField.valid) {
                                    getIt<AuthBloc>().add(
                                      LoginRequested(
                                        email: _emailField.value,
                                        password: _passwordField.value,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          child: state is AuthLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.black)),
                                )
                              : const Text('LOGIN'),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
