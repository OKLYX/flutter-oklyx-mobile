import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _emailField = const EmailField.pure();
    _passwordField = const PasswordField.pure();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Login')),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              TextField(
                onChanged: (email) {
                  _emailField = EmailField.dirty(value: email);
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: _emailField.invalid ? _emailField.error : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (password) {
                  _passwordField = PasswordField.dirty(value: password);
                  setState(() {});
                },
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: _passwordField.invalid ? _passwordField.error
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_emailField.valid && _passwordField.valid &&
                    state is! AuthLoading)
                    ? () {
                  getIt<AuthBloc>().add(
                    LoginRequested(
                      email: _emailField.value,
                      password: _passwordField.value,
                    ),
                  );
                }
                    : null,
                child: state is AuthLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
