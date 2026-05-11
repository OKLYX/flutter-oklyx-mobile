import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/entities/user.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_edit_bloc.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_edit_event.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_edit_state.dart';

class UserEditPage extends StatefulWidget {
  final User user;

  const UserEditPage({
    super.key,
    required this.user,
  });

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final ValueNotifier<String> _emailCheckStatus;
  late String _originalEmail;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _emailCheckStatus = ValueNotifier('available');
    _originalEmail = widget.user.email;
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailCheckStatus.dispose();
    super.dispose();
  }

  void _checkEmail() {
    _emailCheckStatus.value = 'checking';
    context.read<UserEditBloc>().add(
      EmailCheckRequested(
        email: _emailController.text.trim(),
        originalEmail: _originalEmail,
      ),
    );
  }

  void _handleSave(BuildContext context) {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final role = _selectedRole;

    context.read<UserEditBloc>().add(
      UserUpdateRequested(
        id: widget.user.id,
        name: name.isNotEmpty ? name : null,
        email: email.isNotEmpty ? email : null,
        password: password.isNotEmpty ? password : null,
        role: role,
      ),
    );
  }

  String? _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '이름은 필수입니다';
    if (trimmed.length < 2 || trimmed.length > 50) {
      return '이름은 2-50자여야 합니다';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return null;
    if (value.length < 8 || value.length > 20) {
      return '비밀번호는 8-20자여야 합니다';
    }
    return null;
  }

  String? _validatePasswordMatch() {
    if (_passwordController.text.isEmpty) return null;
    if (_passwordController.text != _confirmPasswordController.text) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  String _formatDate(DateTime dateTime) => dateTime.toString().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UserEditBloc>()
        ..add(UserEditInitialized(widget.user)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('사용자 정보 수정'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocListener<UserEditBloc, UserEditState>(
          listenWhen: (previous, current) =>
              current is UserUpdateSuccess ||
              current is UserEditError ||
              current is EmailAvailable ||
              current is EmailDuplicate,
          listener: (context, state) {
            if (state is UserUpdateSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('사용자 정보가 수정되었습니다')),
              );
              context.pop(state.user);
            } else if (state is UserEditError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is EmailAvailable) {
              _emailCheckStatus.value = 'available';
            } else if (state is EmailDuplicate) {
              _emailCheckStatus.value = 'duplicate';
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '이름',
                    hintText: '사용자 이름',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<String>(
                  valueListenable: _emailCheckStatus,
                  builder: (context, status, _) {
                    return TextField(
                      controller: _emailController,
                      onEditingComplete: _checkEmail,
                      decoration: InputDecoration(
                        labelText: '이메일',
                        hintText: '사용자 이메일',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorText: status == 'duplicate'
                            ? '이미 사용 중인 이메일입니다'
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: const ['GUEST', 'USER', 'ADMIN']
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedRole = value),
                  decoration: InputDecoration(
                    labelText: '역할',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '새 비밀번호 (선택)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _validatePassword(_passwordController.text),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호 확인',
                    hintText: '비밀번호 확인',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _validatePasswordMatch(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: '가입일',
                    hintText: _formatDate(widget.user.createdAt),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  controller: TextEditingController(
                    text: _formatDate(widget.user.createdAt),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: '수정일',
                    hintText: _formatDate(widget.user.updatedAt),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  controller: TextEditingController(
                    text: _formatDate(widget.user.updatedAt),
                  ),
                ),
                const SizedBox(height: 24),
                Builder(
                  builder: (builderContext) => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleSave(builderContext),
                      child: const Text('저장'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
