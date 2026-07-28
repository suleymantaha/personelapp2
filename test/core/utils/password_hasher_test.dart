import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/utils/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('creates a salted Argon2id hash and verifies the password', () async {
      final encoded = await PasswordHasher.hashPassword('correct horse battery');

      expect(encoded, startsWith(r'$argon2id$v=19$m=19456,t=2,p=1$'));
      final valid = await PasswordHasher.verifyPassword(
        'correct horse battery',
        encoded,
      );
      final invalid = await PasswordHasher.verifyPassword(
        'wrong password',
        encoded,
      );

      expect(valid.matches, isTrue);
      expect(valid.needsRehash, isFalse);
      expect(invalid.matches, isFalse);
    });

    test('uses a unique random salt for every hash', () async {
      final first = await PasswordHasher.hashPassword('same password value');
      final second = await PasswordHasher.hashPassword('same password value');

      expect(first, isNot(equals(second)));
    });

    test('accepts legacy SHA-256 only for one-time rehash migration', () async {
      const password = 'legacy password';
      const salt = 'Jandarma_Gorev_Takip_Salt_2026';
      final legacyHash = sha256.convert(utf8.encode('$password$salt')).toString();

      final result = await PasswordHasher.verifyPassword(password, legacyHash);

      expect(result.matches, isTrue);
      expect(result.needsRehash, isTrue);
    });

    test('never accepts a stored plaintext password', () async {
      final result = await PasswordHasher.verifyPassword(
        'plaintext password',
        'plaintext password',
      );

      expect(result.matches, isFalse);
      expect(result.needsRehash, isFalse);
    });
  });
}
