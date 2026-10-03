class PasswordPolicy {
  static const minimumLength = 12;
  static const message = 'Parola en az 12 karakter olmalıdır.';
  static bool isValid(String password) =>
      password.trim().length >= minimumLength;
  static void requireValid(String password) {
    if (!isValid(password)) throw ArgumentError(message);
  }
}
