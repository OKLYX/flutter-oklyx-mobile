import 'package:formz/formz.dart';

class EmailField extends FormzInput<String, String> {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  const EmailField.pure() : super.pure('');

  const EmailField.dirty({String value = ''}) : super.dirty(value);

  @override
  String? validator(String value) {
    if (value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  bool get invalid => !isValid;
  bool get valid => isValid;
  @override
  String? get error => validator(value);
}
