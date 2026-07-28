import 'dart:convert';

import 'package:crypto/crypto.dart' as legacy_crypto;
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart';

class PasswordVerificationResult {
  const PasswordVerificationResult({
    required this.matches,
    required this.needsRehash,
  });

  const PasswordVerificationResult.invalid()
      : matches = false,
        needsRehash = false;

  final bool matches;
  final bool needsRehash;
}

class PasswordHasher {
  static const _algorithmName = 'argon2id';
  static const _version = 19;
  static const _memory = 19 * 1024;
  static const _iterations = 2;
  static const _parallelism = 1;
  static const _hashLength = 32;
  static const _saltLength = 16;
  static const _legacySaltPrefix = 'Jandarma_Gorev_Takip_Salt_2026';

  static final Argon2id _algorithm = Argon2id(
    parallelism: _parallelism,
    memory: _memory,
    iterations: _iterations,
    hashLength: _hashLength,
  );

  static Future<String> hashPassword(String password) async {
    if (password.isEmpty) {
      throw ArgumentError.value(password, 'password', 'Parola boş olamaz.');
    }

    final saltKey = SecretKeyData.random(length: _saltLength);
    final salt = <int>[...saltKey.bytes];
    saltKey.destroy();
    final derivedKey = await _algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final hash = <int>[...await derivedKey.extractBytes()];
    derivedKey.destroy();

    return '\$$_algorithmName'
        '\$v=$_version'
        '\$m=$_memory,t=$_iterations,p=$_parallelism'
        '\$${base64UrlEncode(salt)}'
        '\$${base64UrlEncode(hash)}';
  }

  static Future<PasswordVerificationResult> verifyPassword(
    String inputPassword,
    String storedHash, {
    String? username,
  }) async {
    if (inputPassword.isEmpty || storedHash.isEmpty) {
      return const PasswordVerificationResult.invalid();
    }

    if (storedHash.startsWith('\$$_algorithmName\$')) {
      return _verifyArgon2id(inputPassword, storedHash);
    }

    if (!_isLegacySha256(storedHash)) {
      return const PasswordVerificationResult.invalid();
    }

    final legacyWithoutContext = _legacyHash(inputPassword);
    final legacyWithContext = username == null
        ? ''
        : _legacyHash(inputPassword, username: username);
    final matches = _constantTimeStringEquals(
          legacyWithoutContext,
          storedHash,
        ) ||
        (legacyWithContext.isNotEmpty &&
            _constantTimeStringEquals(legacyWithContext, storedHash));
    return PasswordVerificationResult(
      matches: matches,
      needsRehash: matches,
    );
  }

  static Future<PasswordVerificationResult> _verifyArgon2id(
    String password,
    String encodedHash,
  ) async {
    try {
      final parts = encodedHash.split(r'$');
      if (parts.length != 6 ||
          parts[1] != _algorithmName ||
          parts[2] != 'v=$_version') {
        return const PasswordVerificationResult.invalid();
      }

      final parameters = <String, int>{
        for (final parameter in parts[3].split(','))
          parameter.split('=').first:
              int.parse(parameter.split('=').last),
      };
      final memory = parameters['m'];
      final iterations = parameters['t'];
      final parallelism = parameters['p'];
      if (memory == null || iterations == null || parallelism == null) {
        return const PasswordVerificationResult.invalid();
      }

      final salt = base64Url.decode(base64Url.normalize(parts[4]));
      final expectedHash = base64Url.decode(base64Url.normalize(parts[5]));
      final algorithm = Argon2id(
        memory: memory,
        iterations: iterations,
        parallelism: parallelism,
        hashLength: expectedHash.length,
      );
      final derivedKey = await algorithm.deriveKeyFromPassword(
        password: password,
        nonce: salt,
      );
      final actualHash = <int>[...await derivedKey.extractBytes()];
      derivedKey.destroy();
      final matches = constantTimeBytesEquality.equals(
        actualHash,
        expectedHash,
      );
      return PasswordVerificationResult(
        matches: matches,
        needsRehash: matches &&
            (memory != _memory ||
                iterations != _iterations ||
                parallelism != _parallelism ||
                expectedHash.length != _hashLength),
      );
    } on FormatException {
      return const PasswordVerificationResult.invalid();
    } on ArgumentError {
      return const PasswordVerificationResult.invalid();
    }
  }

  static bool _isLegacySha256(String value) =>
      RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(value);

  static String _legacyHash(String password, {String? username}) {
    final saltContext = username == null
        ? _legacySaltPrefix
        : '$username:$_legacySaltPrefix';
    return legacy_crypto.sha256
        .convert(utf8.encode('$password$saltContext'))
        .toString();
  }

  static bool _constantTimeStringEquals(String left, String right) {
    final leftBytes = utf8.encode(left);
    final rightBytes = utf8.encode(right);
    return constantTimeBytesEquality.equals(leftBytes, rightBytes);
  }
}
