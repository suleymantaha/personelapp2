import 'database.dart';

/// Returns the opening error for the startup screen, or null on success.
Future<Object?> prepareDatabase(AppDatabase database) async {
  try {
    await database.ensureSeeded();
    return null;
  } catch (error) {
    try {
      await database.close();
    } catch (_) {
      // A failed lazy connection can repeat its opening error while closing.
    }
    return error;
  }
}
