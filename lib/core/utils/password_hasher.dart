import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  static const String _salt = 'Jandarma_Gorev_Takip_Salt_2026';

  /// Hash a plaintext password using SHA-256 with static salt
  static String hashPassword(String password) {
    if (password.isEmpty) return '';
    final bytes = utf8.encode('$password$_salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify password against stored hash (also supports legacy unhashed passwords for seamless transition)
  static bool verifyPassword(String inputPassword, String storedHashOrPassword) {
    if (storedHashOrPassword.isEmpty) return true;
    final hashedInput = hashPassword(inputPassword);
    return hashedInput == storedHashOrPassword || inputPassword == storedHashOrPassword;
  }
}
