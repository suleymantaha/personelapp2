import 'dart:async';

abstract class LocalStorageService {
  Future<void> saveString(String key, String value);
  Future<String?> getString(String key);
  Future<void> saveJson(String key, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getJson(String key);
  Future<void> saveList(String key, List<Map<String, dynamic>> list);
  Future<List<Map<String, dynamic>>> getList(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

class InMemoryLocalStorageService implements LocalStorageService {
  final Map<String, dynamic> _store = {};

  @override
  Future<void> saveString(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<String?> getString(String key) async {
    return _store[key] as String?;
  }

  @override
  Future<void> saveJson(String key, Map<String, dynamic> data) async {
    _store[key] = data;
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final val = _store[key];
    if (val is Map<String, dynamic>) return val;
    return null;
  }

  @override
  Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    _store[key] = list;
  }

  @override
  Future<List<Map<String, dynamic>>> getList(String key) async {
    final val = _store[key];
    if (val is List) {
      return val.cast<Map<String, dynamic>>();
    }
    return [];
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}
