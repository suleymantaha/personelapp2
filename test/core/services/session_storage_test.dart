import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('resolves role and team from the database, not preferences', () async {
    final userId = await database.into(database.kullaniciTable).insert(
          KullaniciTableCompanion.insert(
            kullaniciAdi: 'komutan',
            sifre: const Value('hash'),
            rol: UserRole.teamCommander.storageValue,
          ),
        );
    final teamId = await database.into(database.timTable).insert(
          TimTableCompanion.insert(
            timAdi: '1-B Timi',
            timKomutaniId: Value(userId),
            olusturmaTarihi: '2026-07-28',
          ),
        );
    SharedPreferences.setMockInitialValues({
      'session_username': 'komutan',
      'session_role': UserRole.admin.storageValue,
      'session_tim_id': 999,
    });

    final session = await SessionStorage.loadValidatedSession(database);

    expect(session?.username, 'komutan');
    expect(session?.role, UserRole.teamCommander);
    expect(session?.timId, teamId);
  });

  test('clears a session whose account no longer exists', () async {
    SharedPreferences.setMockInitialValues({
      'session_username': 'silinmis_hesap',
      'session_role': UserRole.admin.storageValue,
    });

    final session = await SessionStorage.loadValidatedSession(database);
    final preferences = await SharedPreferences.getInstance();

    expect(session, isNull);
    expect(preferences.getString('session_username'), isNull);
    expect(preferences.getString('session_role'), isNull);
  });

  test('clears a session with an unsupported database role', () async {
    await database.into(database.kullaniciTable).insert(
          KullaniciTableCompanion.insert(
            kullaniciAdi: 'bozuk_rol',
            sifre: const Value('hash'),
            rol: 'super_admin',
          ),
        );
    SharedPreferences.setMockInitialValues({
      'session_username': 'bozuk_rol',
    });

    final session = await SessionStorage.loadValidatedSession(database);
    final preferences = await SharedPreferences.getInstance();

    expect(session, isNull);
    expect(preferences.getString('session_username'), isNull);
  });

  test('saves and loads theme mode preferences correctly', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await SessionStorage.loadThemeMode(), ThemeMode.light);

    await SessionStorage.saveThemeMode(ThemeMode.dark);
    expect(await SessionStorage.loadThemeMode(), ThemeMode.dark);

    await SessionStorage.saveThemeMode(ThemeMode.system);
    expect(await SessionStorage.loadThemeMode(), ThemeMode.system);

    await SessionStorage.saveThemeMode(ThemeMode.light);
    expect(await SessionStorage.loadThemeMode(), ThemeMode.light);
  });
}
