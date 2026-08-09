import 'dart:convert';

import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemgundrapApproverDefaults {
  const TemgundrapApproverDefaults({
    this.name = '',
    this.rank = '',
    this.duty = '',
    this.unitTitle = 'KOVANCILAR J.KOMD.ÖZ.HRK.TB.K.LIĞI',
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
        unitTitle: json['unitTitle'] as String? ??
            'KOVANCILAR J.KOMD.ÖZ.HRK.TB.K.LIĞI',
      );
}

class TemgundrapRepository {
  static const _storageKey = 'temgundrap_documents_v1';
  static const _defaultsKey = 'temgundrap_approver_defaults_v1';

  Future<TemgundrapApproverDefaults> getApproverDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_defaultsKey);
    if (raw == null || raw.isEmpty) return const TemgundrapApproverDefaults();
    return TemgundrapApproverDefaults.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> saveApproverDefaults(TemgundrapApproverDefaults defaults) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultsKey, jsonEncode(defaults.toJson()));
  }

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

    if (document.approverName.isNotEmpty ||
        document.approverRank.isNotEmpty ||
        document.approverDuty.isNotEmpty ||
        document.unitTitle.isNotEmpty) {
      await saveApproverDefaults(TemgundrapApproverDefaults(
        name: document.approverName,
        rank: document.approverRank,
        duty: document.approverDuty,
        unitTitle: document.unitTitle,
      ));
    }
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

