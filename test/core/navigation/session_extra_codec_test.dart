import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/navigation/session_extra_codec.dart';

void main() {
  test('null, unknown, malformed and other-session tokens recover as null', () {
    final codec = SessionExtraCodec();
    expect(codec.encode(null), isNull);
    expect(codec.decode(null), isNull);
    expect(codec.decode({'invalid': true}), isNull);
    expect(codec.decode('unknown'), isNull);
    final oldToken = codec.encode(Object());
    expect(SessionExtraCodec().decode(oldToken), isNull);
  });

  test('bounded history evicts oldest payload without leaking its contents',
      () {
    final codec = SessionExtraCodec(capacity: 2);
    final first = Object();
    final token = codec.encode(first);
    expect(codec.encode(first), token);
    String second() => 'callback';
    final secondToken = codec.encode(second);
    codec.encode(Object());
    expect(codec.decode(token), isNull);
    expect(codec.decode(jsonDecode(jsonEncode(secondToken))), same(second));
  });
}
