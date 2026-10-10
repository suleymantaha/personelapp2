import 'dart:convert';

import 'package:personelapp2/features/temgundrap/domain/temgundrap_defaults.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemgundrapApproverDefaults {
  const TemgundrapApproverDefaults({
    this.name = '',
    this.rank = '',
    this.duty = '',
    this.unitTitle = defaultTemgundrapUnitTitle,
  });

  final String name;
  final String rank;
  final String duty;
  final String unitTitle;

  Map<String, String> toJson() => {
    'name': name,
    'rank': rank,
    'duty': duty,
    'unitTitle': unitTitle,
  };

  factory TemgundrapApproverDefaults.fromJson(Map<String, dynamic> json) =>
      TemgundrapApproverDefaults(
        name: json['name'] as String? ?? '',
        rank: json['rank'] as String? ?? '',
        duty: json['duty'] as String? ?? '',
        unitTitle: json['unitTitle'] as String? ?? defaultTemgundrapUnitTitle,
      );
}

class TemgundrapRepository {
  static Future<void> _pendingWrite = Future.value();

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _pendingWrite.then((_) => action());
    _pendingWrite = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  static const _storageKey = 'temgundrap_documents_v1';
  static const _defaultsKey = 'temgundrap_approver_defaults_v1';

  Future<TemgundrapApproverDefaults> getApproverDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_defaultsKey);
    if (raw == null || raw.isEmpty) return const TemgundrapApproverDefaults();
    try {
      return TemgundrapApproverDefaults.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      throw const FormatException(
        'Failed to decode TEMGÜNDRAP approver defaults JSON',
      );
    }
  }

  Future<void> saveApproverDefaults(TemgundrapApproverDefaults defaults) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_defaultsKey, jsonEncode(defaults.toJson()))) {
      throw StateError('Failed to save TEMGÜNDRAP approver defaults');
    }
  }

  Future<List<TemgundrapDocument>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final documents =
          decoded
              .map(
                (item) => TemgundrapDocument.fromJson(
                  (item as Map).cast<String, Object?>(),
                ),
              )
              .toList();
      documents.sort((a, b) => b.date.compareTo(a.date));
      return documents;
    } catch (_) {
      throw const FormatException(
        'Failed to decode TEMGÜNDRAP documents JSON',
      );
    }
  }

  Future<TemgundrapDocument?> getById(String id) async {
    final documents = await getAll();
    for (final document in documents) {
      if (document.id == id) return document;
    }
    return null;
  }

  Future<void> save(TemgundrapDocument document) => _serialized(() async {
    final prefs = await SharedPreferences.getInstance();
    final previousDocuments = prefs.getString(_storageKey);
    final previousDefaults = prefs.getString(_defaultsKey);
    final documents = await getAll();
    final index = documents.indexWhere((item) => item.id == document.id);
    if (index == -1) {
      documents.add(document);
    } else {
      documents[index] = document;
    }
    try {
      await _write(documents);
      await saveApproverDefaults(
        TemgundrapApproverDefaults(
          name: document.approverName,
          rank: document.approverRank,
          duty: document.approverDuty,
          unitTitle: document.unitTitle,
        ),
      );
    } catch (error) {
      final documentsRestored =
          previousDocuments == null
              ? await prefs.remove(_storageKey)
              : await prefs.setString(_storageKey, previousDocuments);
      final defaultsRestored =
          previousDefaults == null
              ? await prefs.remove(_defaultsKey)
              : await prefs.setString(_defaultsKey, previousDefaults);
      if (!documentsRestored || !defaultsRestored) {
        throw StateError(
          'Failed to rollback TEMGÜNDRAP storage after write failure',
        );
      }
      rethrow;
    }
  });

  Future<void> delete(String id) => _serialized(() async {
    final documents = await getAll();
    documents.removeWhere((item) => item.id == id);
    await _write(documents);
  });

  Future<void> _write(List<TemgundrapDocument> documents) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _storageKey,
      jsonEncode(documents.map((item) => item.toJson()).toList()),
    );
    if (!saved) throw StateError('Failed to save TEMGÜNDRAP documents to storage');
  }
}
