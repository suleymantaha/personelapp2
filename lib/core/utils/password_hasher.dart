import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  static const String _saltPrefix = 'Jandarma_Gorev_Takip_Salt_2026';

  /// Hash a plaintext password using SHA-256 with static + context salt
  static String hashPassword(String password, {String? username}) {
    if (password.isEmpty) return '';
    final saltContext = username != null
        ? '$username:$_saltPrefix'
        : _saltPrefix;
    final bytes = utf8.encode('$password$saltContext');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify password against stored hash (supports username context and legacy hashes)
  static bool verifyPassword(
    String inputPassword,
    String storedHashOrPassword, {
    String? username,
  }) {
    if (storedHashOrPassword.isEmpty) return true;
    final hashedInputWithContext = hashPassword(
      inputPassword,
      username: username,
    );
    final hashedInputLegacy = hashPassword(inputPassword);
    return hashedInputWithContext == storedHashOrPassword ||
        hashedInputLegacy == storedHashOrPassword ||
        inputPassword == storedHashOrPassword;
  }
}
