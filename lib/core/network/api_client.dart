import 'dart:async';

abstract class ApiClient {
  Future<Map<String, dynamic>> get(String path, {Map<String, String>? headers});
  Future<Map<String, dynamic>> post(String path, {required Map<String, dynamic> body, Map<String, String>? headers});
  Future<Map<String, dynamic>> put(String path, {required Map<String, dynamic> body, Map<String, String>? headers});
  Future<bool> delete(String path, {Map<String, String>? headers});
  Future<bool> isNetworkConnected();
}

class HttpApiClient implements ApiClient {
  bool _mockNetworkStatus = true;

  void setNetworkStatus(bool isConnected) {
    _mockNetworkStatus = isConnected;
  }

  @override
  Future<bool> isNetworkConnected() async {
    return _mockNetworkStatus;
  }

  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, String>? headers}) async {
    if (!_mockNetworkStatus) {
      throw TimeoutException('Network unavailable');
    }
    return <String, dynamic>{'status': 'success', 'data': <String, dynamic>{}};
  }

  @override
  Future<Map<String, dynamic>> post(String path, {required Map<String, dynamic> body, Map<String, String>? headers}) async {
    if (!_mockNetworkStatus) {
      throw TimeoutException('Network unavailable');
    }
    return {'status': 'created', 'data': body};
  }

  @override
  Future<Map<String, dynamic>> put(String path, {required Map<String, dynamic> body, Map<String, String>? headers}) async {
    if (!_mockNetworkStatus) {
      throw TimeoutException('Network unavailable');
    }
    return {'status': 'updated', 'data': body};
  }

  @override
  Future<bool> delete(String path, {Map<String, String>? headers}) async {
    if (!_mockNetworkStatus) {
      throw TimeoutException('Network unavailable');
    }
    return true;
  }
}
