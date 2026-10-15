import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'roster_signature.dart';

class RosterSignatureStore {
  static const storageKey = 'roster_signers_v1';

  Future<List<RosterSigner>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return List.of(heybetRosterSigners);
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      if (data.length != 2) throw const FormatException();
      return List.generate(2, (index) {
        final item = data[index] as Map<String, dynamic>;
        return RosterSigner(
            heybetRosterSigners[index].title,
            item['name'] as String,
            item['rank'] as String,
            item['role'] as String);
      });
    } on FormatException {
      return List.of(heybetRosterSigners);
    } on TypeError {
      return List.of(heybetRosterSigners);
    }
  }

  Future<void> save(List<RosterSigner> signers) async {
    if (signers.length != 2) throw ArgumentError('Expected two roster signers');
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(signers
        .map((s) => {
              'name': s.name,
              'rank': s.rank,
              'role': s.role,
            })
        .toList());
    if (!await prefs.setString(storageKey, raw)) {
      throw StateError('Failed to save roster signers');
    }
  }
}
