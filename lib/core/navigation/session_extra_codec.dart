import 'dart:convert';
import 'dart:math';

/// History stores opaque tokens, never callbacks or personnel data.
/// A reload or expired entry intentionally decodes to null for route recovery.
class SessionExtraCodec extends Codec<Object?, Object?> {
  SessionExtraCodec({this.capacity = 64}) : assert(capacity > 0);

  final int capacity;
  final String _session = List.generate(
    4,
    (_) => Random.secure().nextInt(0x100000000).toRadixString(16),
  ).join('-');
  final _values = <String, Object>{};
  int _nextId = 0;

  @override
  Converter<Object?, Object?> get encoder => _ExtraConverter((value) {
        if (value == null) return null;
        for (final entry in _values.entries) {
          if (identical(entry.value, value)) return entry.key;
        }
        final token = '$_session:${_nextId++}';
        _values[token] = value;
        if (_values.length > capacity) _values.remove(_values.keys.first);
        return token;
      });

  @override
  Converter<Object?, Object?> get decoder => _ExtraConverter(
        (token) => token is String ? _values[token] : null,
      );
}

class _ExtraConverter extends Converter<Object?, Object?> {
  const _ExtraConverter(this.convertValue);
  final Object? Function(Object?) convertValue;

  @override
  Object? convert(Object? input) => convertValue(input);
}
