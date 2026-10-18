/// Validation used when editing an existing profile.
abstract final class ProfileValidators {
  static String? fullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.length < 2) return 'Enter your full name.';
    return null;
  }
}
