/// The form validation rules shared by EduPro's authentication screens.
abstract final class AuthValidators {
  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (trimmed.isEmpty) return 'Enter your email address.';
    if (!emailPattern.hasMatch(trimmed)) return 'Enter a valid email address.';
    return null;
  }

  static String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your password.';
    return null;
  }

  static String? registrationFullName(String? value) {
    if ((value?.trim() ?? '').isEmpty) return 'Enter your full name.';
    return null;
  }

  static String? registrationPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Enter a password.';
    if ((value ?? '').length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, {required String password}) {
    if ((value ?? '').isEmpty) return 'Confirm your password.';
    if (value != password) return 'Passwords do not match.';
    return null;
  }
}
