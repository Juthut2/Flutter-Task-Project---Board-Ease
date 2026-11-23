/// Shared form validators. Every validator trims text before checking it.
class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );
  static final RegExp _phonePattern = RegExp(r'^(?:\+63|0)9\d{9}$');
  static final RegExp _monthPattern = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');
  static final RegExp _letterPattern = RegExp(r'[A-Za-z]');
  static final RegExp _numberPattern = RegExp(r'\d');

  static String? required(
    String? value, {
    String field = 'This field',
    int maxLength = 200,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$field is required';
    if (text.length > maxLength) {
      return '$field must be $maxLength characters or fewer';
    }
    return null;
  }

  static String? name(String? value) =>
      required(value, field: 'Full name', maxLength: 80);

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    if (text.length > 120) return 'Email is too long';
    if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < 8) return 'Password must be at least 8 characters';
    if (text.length > 64) return 'Password must be 64 characters or fewer';
    if (!_letterPattern.hasMatch(text)) {
      return 'Password must include at least one letter';
    }
    if (!_numberPattern.hasMatch(text)) {
      return 'Password must include at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Phone number is required';
    final normalized = text.replaceAll(RegExp(r'[\s-]'), '');
    if (!_phonePattern.hasMatch(normalized)) {
      return 'Use a valid PH mobile number (e.g. 09171234567)';
    }
    return null;
  }

  static String? optionalPhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return phone(text);
  }

  static String? amount(String? value, {String field = 'Amount'}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$field is required';
    final parsed = double.tryParse(text.replaceAll(',', ''));
    if (parsed == null) return 'Enter a valid $field';
    if (parsed <= 0) return '$field must be greater than zero';
    if (parsed > 10000000) return '$field is too large';
    return null;
  }

  static String? nonNegativeAmount(String? value, {String field = 'Amount'}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$field is required';
    final parsed = double.tryParse(text.replaceAll(',', ''));
    if (parsed == null) return 'Enter a valid $field';
    if (parsed < 0) return '$field cannot be negative';
    if (parsed > 10000000) return '$field is too large';
    return null;
  }

  static String? positiveInt(String? value, {String field = 'Value'}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$field is required';
    final parsed = int.tryParse(text);
    if (parsed == null) return 'Enter a valid whole number';
    if (parsed <= 0) return '$field must be greater than zero';
    if (parsed > 1000) return '$field is too large';
    return null;
  }

  static String? month(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Month is required';
    if (!_monthPattern.hasMatch(text)) return 'Use the format YYYY-MM';
    return null;
  }

  static String? optionalText(String? value, {int maxLength = 500}) {
    final text = value?.trim() ?? '';
    if (text.length > maxLength) {
      return 'Must be $maxLength characters or fewer';
    }
    return null;
  }
}
