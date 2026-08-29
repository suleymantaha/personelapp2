import 'package:shared_preferences/shared_preferences.dart';

/// Stores the manual card order the user sets in the activity archive.
///
/// The order is kept per day, because the archive always shows a single date.
/// Ids that are no longer present are ignored while reading, and activities
/// that have never been ordered manually keep their default position.
class ActivityOrderPreferences {
  const ActivityOrderPreferences();

  static const String _keyPrefix = 'activity_card_order_';

  String _keyFor(String date) => '$_keyPrefix$date';

  Future<List<int>> loadOrder(String date) async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(_keyFor(date)) ?? const [];
    return stored
        .map(int.tryParse)
        .whereType<int>()
        .toList(growable: false);
  }

  Future<void> saveOrder(String date, List<int> activityIds) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _keyFor(date),
      activityIds.map((id) => id.toString()).toList(growable: false),
    );
  }

  Future<void> clearOrder(String date) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_keyFor(date));
  }
}
