import 'dart:convert';

import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemgundrapRepository {
  static const _storageKey = 'temgundrap_documents_v1';

  Future<List<TemgundrapDocument>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    final documents = decoded
        .map((item) => TemgundrapDocument.fromJson(
              (item as Map).cast<String, Object?>(),
            ))
        .toList();
    documents.sort((a, b) => b.date.compareTo(a.date));
    return documents;
  }

  Future<TemgundrapDocument?> getById(String id) async {
    final documents = await getAll();
    for (final document in documents) {
      if (document.id == id) return document;
    }
    return null;
  }

  Future<void> save(TemgundrapDocument document) async {
    final documents = await getAll();
    final index = documents.indexWhere((item) => item.id == document.id);
    if (index == -1) {
      documents.add(document);
    } else {
      documents[index] = document;
    }
    await _write(documents);
  }

  Future<void> delete(String id) async {
    final documents = await getAll();
    documents.removeWhere((item) => item.id == id);
    await _write(documents);
  }

  Future<void> _write(List<TemgundrapDocument> documents) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(documents.map((item) => item.toJson()).toList()),
    );
  }
}
