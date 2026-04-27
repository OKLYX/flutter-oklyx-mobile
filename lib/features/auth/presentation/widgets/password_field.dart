import 'package:formz/formz.dart';

class PasswordField extends FormzInput<String, String> {
  const PasswordField.pure() : super.pure('');

  const PasswordField.dirty({String value = ''}) : super.dirty(value);

  @override
  String? validator(String value) {
    if (value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  bool get invalid => !isValid;
  bool get valid => isValid;
  @override
  String? get error => validator(value);
}
