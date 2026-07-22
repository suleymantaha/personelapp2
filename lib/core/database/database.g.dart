// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TimTableTable extends TimTable
    with TableInfo<$TimTableTable, TimTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timAdiMeta = const VerificationMeta('timAdi');
  @override
  late final GeneratedColumn<String> timAdi = GeneratedColumn<String>(
    'tim_adi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timKomutaniIdMeta = const VerificationMeta(
    'timKomutaniId',
  );
  @override
  late final GeneratedColumn<int> timKomutaniId = GeneratedColumn<int>(
    'tim_komutani_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES kullanici_table (id)',
    ),
  );
  static const VerificationMeta _olusturmaTarihiMeta = const VerificationMeta(
    'olusturmaTarihi',
  );
  @override
  late final GeneratedColumn<String> olusturmaTarihi = GeneratedColumn<String>(
    'olusturma_tarihi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timAdi,
    timKomutaniId,
    olusturmaTarihi,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tim_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tim_adi')) {
      context.handle(
        _timAdiMeta,
        timAdi.isAcceptableOrUnknown(data['tim_adi']!, _timAdiMeta),
      );
    } else if (isInserting) {
      context.missing(_timAdiMeta);
    }
    if (data.containsKey('tim_komutani_id')) {
      context.handle(
        _timKomutaniIdMeta,
        timKomutaniId.isAcceptableOrUnknown(
          data['tim_komutani_id']!,
          _timKomutaniIdMeta,
        ),
      );
    }
    if (data.containsKey('olusturma_tarihi')) {
      context.handle(
        _olusturmaTarihiMeta,
        olusturmaTarihi.isAcceptableOrUnknown(
          data['olusturma_tarihi']!,
          _olusturmaTarihiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_olusturmaTarihiMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timAdi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tim_adi'],
      )!,
      timKomutaniId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tim_komutani_id'],
      ),
      olusturmaTarihi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}olusturma_tarihi'],
      )!,
    );
  }

  @override
  $TimTableTable createAlias(String alias) {
    return $TimTableTable(attachedDatabase, alias);
  }
}

class TimTableData extends DataClass implements Insertable<TimTableData> {
  final int id;
  final String timAdi;
  final int? timKomutaniId;
  final String olusturmaTarihi;
  const TimTableData({
    required this.id,
    required this.timAdi,
    this.timKomutaniId,
    required this.olusturmaTarihi,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tim_adi'] = Variable<String>(timAdi);
    if (!nullToAbsent || timKomutaniId != null) {
      map['tim_komutani_id'] = Variable<int>(timKomutaniId);
    }
    map['olusturma_tarihi'] = Variable<String>(olusturmaTarihi);
    return map;
  }

  TimTableCompanion toCompanion(bool nullToAbsent) {
    return TimTableCompanion(
      id: Value(id),
      timAdi: Value(timAdi),
      timKomutaniId: timKomutaniId == null && nullToAbsent
          ? const Value.absent()
          : Value(timKomutaniId),
      olusturmaTarihi: Value(olusturmaTarihi),
    );
  }

  factory TimTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimTableData(
      id: serializer.fromJson<int>(json['id']),
      timAdi: serializer.fromJson<String>(json['timAdi']),
      timKomutaniId: serializer.fromJson<int?>(json['timKomutaniId']),
      olusturmaTarihi: serializer.fromJson<String>(json['olusturmaTarihi']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timAdi': serializer.toJson<String>(timAdi),
      'timKomutaniId': serializer.toJson<int?>(timKomutaniId),
      'olusturmaTarihi': serializer.toJson<String>(olusturmaTarihi),
    };
  }

  TimTableData copyWith({
    int? id,
    String? timAdi,
    Value<int?> timKomutaniId = const Value.absent(),
    String? olusturmaTarihi,
  }) => TimTableData(
    id: id ?? this.id,
    timAdi: timAdi ?? this.timAdi,
    timKomutaniId: timKomutaniId.present
        ? timKomutaniId.value
        : this.timKomutaniId,
    olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
  );
  TimTableData copyWithCompanion(TimTableCompanion data) {
    return TimTableData(
      id: data.id.present ? data.id.value : this.id,
      timAdi: data.timAdi.present ? data.timAdi.value : this.timAdi,
      timKomutaniId: data.timKomutaniId.present
          ? data.timKomutaniId.value
          : this.timKomutaniId,
      olusturmaTarihi: data.olusturmaTarihi.present
          ? data.olusturmaTarihi.value
          : this.olusturmaTarihi,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimTableData(')
          ..write('id: $id, ')
          ..write('timAdi: $timAdi, ')
          ..write('timKomutaniId: $timKomutaniId, ')
          ..write('olusturmaTarihi: $olusturmaTarihi')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timAdi, timKomutaniId, olusturmaTarihi);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimTableData &&
          other.id == this.id &&
          other.timAdi == this.timAdi &&
          other.timKomutaniId == this.timKomutaniId &&
          other.olusturmaTarihi == this.olusturmaTarihi);
}

class TimTableCompanion extends UpdateCompanion<TimTableData> {
  final Value<int> id;
  final Value<String> timAdi;
  final Value<int?> timKomutaniId;
  final Value<String> olusturmaTarihi;
  const TimTableCompanion({
    this.id = const Value.absent(),
    this.timAdi = const Value.absent(),
    this.timKomutaniId = const Value.absent(),
    this.olusturmaTarihi = const Value.absent(),
  });
  TimTableCompanion.insert({
    this.id = const Value.absent(),
    required String timAdi,
    this.timKomutaniId = const Value.absent(),
    required String olusturmaTarihi,
  }) : timAdi = Value(timAdi),
       olusturmaTarihi = Value(olusturmaTarihi);
  static Insertable<TimTableData> custom({
    Expression<int>? id,
    Expression<String>? timAdi,
    Expression<int>? timKomutaniId,
    Expression<String>? olusturmaTarihi,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timAdi != null) 'tim_adi': timAdi,
      if (timKomutaniId != null) 'tim_komutani_id': timKomutaniId,
      if (olusturmaTarihi != null) 'olusturma_tarihi': olusturmaTarihi,
    });
  }

  TimTableCompanion copyWith({
    Value<int>? id,
    Value<String>? timAdi,
    Value<int?>? timKomutaniId,
    Value<String>? olusturmaTarihi,
  }) {
    return TimTableCompanion(
      id: id ?? this.id,
      timAdi: timAdi ?? this.timAdi,
      timKomutaniId: timKomutaniId ?? this.timKomutaniId,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timAdi.present) {
      map['tim_adi'] = Variable<String>(timAdi.value);
    }
    if (timKomutaniId.present) {
      map['tim_komutani_id'] = Variable<int>(timKomutaniId.value);
    }
    if (olusturmaTarihi.present) {
      map['olusturma_tarihi'] = Variable<String>(olusturmaTarihi.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimTableCompanion(')
          ..write('id: $id, ')
          ..write('timAdi: $timAdi, ')
          ..write('timKomutaniId: $timKomutaniId, ')
          ..write('olusturmaTarihi: $olusturmaTarihi')
          ..write(')'))
        .toString();
  }
}

class $KullaniciTableTable extends KullaniciTable
    with TableInfo<$KullaniciTableTable, KullaniciTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KullaniciTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kullaniciAdiMeta = const VerificationMeta(
    'kullaniciAdi',
  );
  @override
  late final GeneratedColumn<String> kullaniciAdi = GeneratedColumn<String>(
    'kullanici_adi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _sifreMeta = const VerificationMeta('sifre');
  @override
  late final GeneratedColumn<String> sifre = GeneratedColumn<String>(
    'sifre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _rolMeta = const VerificationMeta('rol');
  @override
  late final GeneratedColumn<String> rol = GeneratedColumn<String>(
    'rol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timIdMeta = const VerificationMeta('timId');
  @override
  late final GeneratedColumn<int> timId = GeneratedColumn<int>(
    'tim_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tim_table (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, kullaniciAdi, sifre, rol, timId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kullanici_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<KullaniciTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kullanici_adi')) {
      context.handle(
        _kullaniciAdiMeta,
        kullaniciAdi.isAcceptableOrUnknown(
          data['kullanici_adi']!,
          _kullaniciAdiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kullaniciAdiMeta);
    }
    if (data.containsKey('sifre')) {
      context.handle(
        _sifreMeta,
        sifre.isAcceptableOrUnknown(data['sifre']!, _sifreMeta),
      );
    }
    if (data.containsKey('rol')) {
      context.handle(
        _rolMeta,
        rol.isAcceptableOrUnknown(data['rol']!, _rolMeta),
      );
    } else if (isInserting) {
      context.missing(_rolMeta);
    }
    if (data.containsKey('tim_id')) {
      context.handle(
        _timIdMeta,
        timId.isAcceptableOrUnknown(data['tim_id']!, _timIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KullaniciTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KullaniciTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kullaniciAdi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kullanici_adi'],
      )!,
      sifre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sifre'],
      )!,
      rol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rol'],
      )!,
      timId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tim_id'],
      ),
    );
  }

  @override
  $KullaniciTableTable createAlias(String alias) {
    return $KullaniciTableTable(attachedDatabase, alias);
  }
}

class KullaniciTableData extends DataClass
    implements Insertable<KullaniciTableData> {
  final int id;
  final String kullaniciAdi;
  final String sifre;
  final String rol;
  final int? timId;
  const KullaniciTableData({
    required this.id,
    required this.kullaniciAdi,
    required this.sifre,
    required this.rol,
    this.timId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kullanici_adi'] = Variable<String>(kullaniciAdi);
    map['sifre'] = Variable<String>(sifre);
    map['rol'] = Variable<String>(rol);
    if (!nullToAbsent || timId != null) {
      map['tim_id'] = Variable<int>(timId);
    }
    return map;
  }

  KullaniciTableCompanion toCompanion(bool nullToAbsent) {
    return KullaniciTableCompanion(
      id: Value(id),
      kullaniciAdi: Value(kullaniciAdi),
      sifre: Value(sifre),
      rol: Value(rol),
      timId: timId == null && nullToAbsent
          ? const Value.absent()
          : Value(timId),
    );
  }

  factory KullaniciTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KullaniciTableData(
      id: serializer.fromJson<int>(json['id']),
      kullaniciAdi: serializer.fromJson<String>(json['kullaniciAdi']),
      sifre: serializer.fromJson<String>(json['sifre']),
      rol: serializer.fromJson<String>(json['rol']),
      timId: serializer.fromJson<int?>(json['timId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kullaniciAdi': serializer.toJson<String>(kullaniciAdi),
      'sifre': serializer.toJson<String>(sifre),
      'rol': serializer.toJson<String>(rol),
      'timId': serializer.toJson<int?>(timId),
    };
  }

  KullaniciTableData copyWith({
    int? id,
    String? kullaniciAdi,
    String? sifre,
    String? rol,
    Value<int?> timId = const Value.absent(),
  }) => KullaniciTableData(
    id: id ?? this.id,
    kullaniciAdi: kullaniciAdi ?? this.kullaniciAdi,
    sifre: sifre ?? this.sifre,
    rol: rol ?? this.rol,
    timId: timId.present ? timId.value : this.timId,
  );
  KullaniciTableData copyWithCompanion(KullaniciTableCompanion data) {
    return KullaniciTableData(
      id: data.id.present ? data.id.value : this.id,
      kullaniciAdi: data.kullaniciAdi.present
          ? data.kullaniciAdi.value
          : this.kullaniciAdi,
      sifre: data.sifre.present ? data.sifre.value : this.sifre,
      rol: data.rol.present ? data.rol.value : this.rol,
      timId: data.timId.present ? data.timId.value : this.timId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KullaniciTableData(')
          ..write('id: $id, ')
          ..write('kullaniciAdi: $kullaniciAdi, ')
          ..write('sifre: $sifre, ')
          ..write('rol: $rol, ')
          ..write('timId: $timId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kullaniciAdi, sifre, rol, timId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KullaniciTableData &&
          other.id == this.id &&
          other.kullaniciAdi == this.kullaniciAdi &&
          other.sifre == this.sifre &&
          other.rol == this.rol &&
          other.timId == this.timId);
}

class KullaniciTableCompanion extends UpdateCompanion<KullaniciTableData> {
  final Value<int> id;
  final Value<String> kullaniciAdi;
  final Value<String> sifre;
  final Value<String> rol;
  final Value<int?> timId;
  const KullaniciTableCompanion({
    this.id = const Value.absent(),
    this.kullaniciAdi = const Value.absent(),
    this.sifre = const Value.absent(),
    this.rol = const Value.absent(),
    this.timId = const Value.absent(),
  });
  KullaniciTableCompanion.insert({
    this.id = const Value.absent(),
    required String kullaniciAdi,
    this.sifre = const Value.absent(),
    required String rol,
    this.timId = const Value.absent(),
  }) : kullaniciAdi = Value(kullaniciAdi),
       rol = Value(rol);
  static Insertable<KullaniciTableData> custom({
    Expression<int>? id,
    Expression<String>? kullaniciAdi,
    Expression<String>? sifre,
    Expression<String>? rol,
    Expression<int>? timId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kullaniciAdi != null) 'kullanici_adi': kullaniciAdi,
      if (sifre != null) 'sifre': sifre,
      if (rol != null) 'rol': rol,
      if (timId != null) 'tim_id': timId,
    });
  }

  KullaniciTableCompanion copyWith({
    Value<int>? id,
    Value<String>? kullaniciAdi,
    Value<String>? sifre,
    Value<String>? rol,
    Value<int?>? timId,
  }) {
    return KullaniciTableCompanion(
      id: id ?? this.id,
      kullaniciAdi: kullaniciAdi ?? this.kullaniciAdi,
      sifre: sifre ?? this.sifre,
      rol: rol ?? this.rol,
      timId: timId ?? this.timId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kullaniciAdi.present) {
      map['kullanici_adi'] = Variable<String>(kullaniciAdi.value);
    }
    if (sifre.present) {
      map['sifre'] = Variable<String>(sifre.value);
    }
    if (rol.present) {
      map['rol'] = Variable<String>(rol.value);
    }
    if (timId.present) {
      map['tim_id'] = Variable<int>(timId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KullaniciTableCompanion(')
          ..write('id: $id, ')
          ..write('kullaniciAdi: $kullaniciAdi, ')
          ..write('sifre: $sifre, ')
          ..write('rol: $rol, ')
          ..write('timId: $timId')
          ..write(')'))
        .toString();
  }
}

class $PersonelTableTable extends PersonelTable
    with TableInfo<$PersonelTableTable, PersonelTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonelTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _adSoyadMeta = const VerificationMeta(
    'adSoyad',
  );
  @override
  late final GeneratedColumn<String> adSoyad = GeneratedColumn<String>(
    'ad_soyad',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rutbeMeta = const VerificationMeta('rutbe');
  @override
  late final GeneratedColumn<String> rutbe = GeneratedColumn<String>(
    'rutbe',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birlikMeta = const VerificationMeta('birlik');
  @override
  late final GeneratedColumn<String> birlik = GeneratedColumn<String>(
    'birlik',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timIdMeta = const VerificationMeta('timId');
  @override
  late final GeneratedColumn<int> timId = GeneratedColumn<int>(
    'tim_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tim_table (id)',
    ),
  );
  static const VerificationMeta _kayitTarihiMeta = const VerificationMeta(
    'kayitTarihi',
  );
  @override
  late final GeneratedColumn<String> kayitTarihi = GeneratedColumn<String>(
    'kayit_tarihi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    adSoyad,
    rutbe,
    birlik,
    timId,
    kayitTarihi,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personel_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonelTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ad_soyad')) {
      context.handle(
        _adSoyadMeta,
        adSoyad.isAcceptableOrUnknown(data['ad_soyad']!, _adSoyadMeta),
      );
    } else if (isInserting) {
      context.missing(_adSoyadMeta);
    }
    if (data.containsKey('rutbe')) {
      context.handle(
        _rutbeMeta,
        rutbe.isAcceptableOrUnknown(data['rutbe']!, _rutbeMeta),
      );
    } else if (isInserting) {
      context.missing(_rutbeMeta);
    }
    if (data.containsKey('birlik')) {
      context.handle(
        _birlikMeta,
        birlik.isAcceptableOrUnknown(data['birlik']!, _birlikMeta),
      );
    } else if (isInserting) {
      context.missing(_birlikMeta);
    }
    if (data.containsKey('tim_id')) {
      context.handle(
        _timIdMeta,
        timId.isAcceptableOrUnknown(data['tim_id']!, _timIdMeta),
      );
    }
    if (data.containsKey('kayit_tarihi')) {
      context.handle(
        _kayitTarihiMeta,
        kayitTarihi.isAcceptableOrUnknown(
          data['kayit_tarihi']!,
          _kayitTarihiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kayitTarihiMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonelTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonelTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      adSoyad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ad_soyad'],
      )!,
      rutbe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rutbe'],
      )!,
      birlik: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}birlik'],
      )!,
      timId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tim_id'],
      ),
      kayitTarihi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kayit_tarihi'],
      )!,
    );
  }

  @override
  $PersonelTableTable createAlias(String alias) {
    return $PersonelTableTable(attachedDatabase, alias);
  }
}

class PersonelTableData extends DataClass
    implements Insertable<PersonelTableData> {
  final int id;
  final String adSoyad;
  final String rutbe;
  final String birlik;
  final int? timId;
  final String kayitTarihi;
  const PersonelTableData({
    required this.id,
    required this.adSoyad,
    required this.rutbe,
    required this.birlik,
    this.timId,
    required this.kayitTarihi,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ad_soyad'] = Variable<String>(adSoyad);
    map['rutbe'] = Variable<String>(rutbe);
    map['birlik'] = Variable<String>(birlik);
    if (!nullToAbsent || timId != null) {
      map['tim_id'] = Variable<int>(timId);
    }
    map['kayit_tarihi'] = Variable<String>(kayitTarihi);
    return map;
  }

  PersonelTableCompanion toCompanion(bool nullToAbsent) {
    return PersonelTableCompanion(
      id: Value(id),
      adSoyad: Value(adSoyad),
      rutbe: Value(rutbe),
      birlik: Value(birlik),
      timId: timId == null && nullToAbsent
          ? const Value.absent()
          : Value(timId),
      kayitTarihi: Value(kayitTarihi),
    );
  }

  factory PersonelTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonelTableData(
      id: serializer.fromJson<int>(json['id']),
      adSoyad: serializer.fromJson<String>(json['adSoyad']),
      rutbe: serializer.fromJson<String>(json['rutbe']),
      birlik: serializer.fromJson<String>(json['birlik']),
      timId: serializer.fromJson<int?>(json['timId']),
      kayitTarihi: serializer.fromJson<String>(json['kayitTarihi']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'adSoyad': serializer.toJson<String>(adSoyad),
      'rutbe': serializer.toJson<String>(rutbe),
      'birlik': serializer.toJson<String>(birlik),
      'timId': serializer.toJson<int?>(timId),
      'kayitTarihi': serializer.toJson<String>(kayitTarihi),
    };
  }

  PersonelTableData copyWith({
    int? id,
    String? adSoyad,
    String? rutbe,
    String? birlik,
    Value<int?> timId = const Value.absent(),
    String? kayitTarihi,
  }) => PersonelTableData(
    id: id ?? this.id,
    adSoyad: adSoyad ?? this.adSoyad,
    rutbe: rutbe ?? this.rutbe,
    birlik: birlik ?? this.birlik,
    timId: timId.present ? timId.value : this.timId,
    kayitTarihi: kayitTarihi ?? this.kayitTarihi,
  );
  PersonelTableData copyWithCompanion(PersonelTableCompanion data) {
    return PersonelTableData(
      id: data.id.present ? data.id.value : this.id,
      adSoyad: data.adSoyad.present ? data.adSoyad.value : this.adSoyad,
      rutbe: data.rutbe.present ? data.rutbe.value : this.rutbe,
      birlik: data.birlik.present ? data.birlik.value : this.birlik,
      timId: data.timId.present ? data.timId.value : this.timId,
      kayitTarihi: data.kayitTarihi.present
          ? data.kayitTarihi.value
          : this.kayitTarihi,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonelTableData(')
          ..write('id: $id, ')
          ..write('adSoyad: $adSoyad, ')
          ..write('rutbe: $rutbe, ')
          ..write('birlik: $birlik, ')
          ..write('timId: $timId, ')
          ..write('kayitTarihi: $kayitTarihi')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, adSoyad, rutbe, birlik, timId, kayitTarihi);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonelTableData &&
          other.id == this.id &&
          other.adSoyad == this.adSoyad &&
          other.rutbe == this.rutbe &&
          other.birlik == this.birlik &&
          other.timId == this.timId &&
          other.kayitTarihi == this.kayitTarihi);
}

class PersonelTableCompanion extends UpdateCompanion<PersonelTableData> {
  final Value<int> id;
  final Value<String> adSoyad;
  final Value<String> rutbe;
  final Value<String> birlik;
  final Value<int?> timId;
  final Value<String> kayitTarihi;
  const PersonelTableCompanion({
    this.id = const Value.absent(),
    this.adSoyad = const Value.absent(),
    this.rutbe = const Value.absent(),
    this.birlik = const Value.absent(),
    this.timId = const Value.absent(),
    this.kayitTarihi = const Value.absent(),
  });
  PersonelTableCompanion.insert({
    this.id = const Value.absent(),
    required String adSoyad,
    required String rutbe,
    required String birlik,
    this.timId = const Value.absent(),
    required String kayitTarihi,
  }) : adSoyad = Value(adSoyad),
       rutbe = Value(rutbe),
       birlik = Value(birlik),
       kayitTarihi = Value(kayitTarihi);
  static Insertable<PersonelTableData> custom({
    Expression<int>? id,
    Expression<String>? adSoyad,
    Expression<String>? rutbe,
    Expression<String>? birlik,
    Expression<int>? timId,
    Expression<String>? kayitTarihi,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (adSoyad != null) 'ad_soyad': adSoyad,
      if (rutbe != null) 'rutbe': rutbe,
      if (birlik != null) 'birlik': birlik,
      if (timId != null) 'tim_id': timId,
      if (kayitTarihi != null) 'kayit_tarihi': kayitTarihi,
    });
  }

  PersonelTableCompanion copyWith({
    Value<int>? id,
    Value<String>? adSoyad,
    Value<String>? rutbe,
    Value<String>? birlik,
    Value<int?>? timId,
    Value<String>? kayitTarihi,
  }) {
    return PersonelTableCompanion(
      id: id ?? this.id,
      adSoyad: adSoyad ?? this.adSoyad,
      rutbe: rutbe ?? this.rutbe,
      birlik: birlik ?? this.birlik,
      timId: timId ?? this.timId,
      kayitTarihi: kayitTarihi ?? this.kayitTarihi,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (adSoyad.present) {
      map['ad_soyad'] = Variable<String>(adSoyad.value);
    }
    if (rutbe.present) {
      map['rutbe'] = Variable<String>(rutbe.value);
    }
    if (birlik.present) {
      map['birlik'] = Variable<String>(birlik.value);
    }
    if (timId.present) {
      map['tim_id'] = Variable<int>(timId.value);
    }
    if (kayitTarihi.present) {
      map['kayit_tarihi'] = Variable<String>(kayitTarihi.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonelTableCompanion(')
          ..write('id: $id, ')
          ..write('adSoyad: $adSoyad, ')
          ..write('rutbe: $rutbe, ')
          ..write('birlik: $birlik, ')
          ..write('timId: $timId, ')
          ..write('kayitTarihi: $kayitTarihi')
          ..write(')'))
        .toString();
  }
}

class $GunlukFaaliyetTableTable extends GunlukFaaliyetTable
    with TableInfo<$GunlukFaaliyetTableTable, GunlukFaaliyetTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GunlukFaaliyetTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _faaliyetAdiMeta = const VerificationMeta(
    'faaliyetAdi',
  );
  @override
  late final GeneratedColumn<String> faaliyetAdi = GeneratedColumn<String>(
    'faaliyet_adi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tarihMeta = const VerificationMeta('tarih');
  @override
  late final GeneratedColumn<String> tarih = GeneratedColumn<String>(
    'tarih',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _olusturanKullaniciMeta =
      const VerificationMeta('olusturanKullanici');
  @override
  late final GeneratedColumn<String> olusturanKullanici =
      GeneratedColumn<String>(
        'olusturan_kullanici',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _olusturmaTarihiMeta = const VerificationMeta(
    'olusturmaTarihi',
  );
  @override
  late final GeneratedColumn<String> olusturmaTarihi = GeneratedColumn<String>(
    'olusturma_tarihi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    faaliyetAdi,
    tarih,
    olusturanKullanici,
    olusturmaTarihi,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gunluk_faaliyet_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<GunlukFaaliyetTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('faaliyet_adi')) {
      context.handle(
        _faaliyetAdiMeta,
        faaliyetAdi.isAcceptableOrUnknown(
          data['faaliyet_adi']!,
          _faaliyetAdiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_faaliyetAdiMeta);
    }
    if (data.containsKey('tarih')) {
      context.handle(
        _tarihMeta,
        tarih.isAcceptableOrUnknown(data['tarih']!, _tarihMeta),
      );
    } else if (isInserting) {
      context.missing(_tarihMeta);
    }
    if (data.containsKey('olusturan_kullanici')) {
      context.handle(
        _olusturanKullaniciMeta,
        olusturanKullanici.isAcceptableOrUnknown(
          data['olusturan_kullanici']!,
          _olusturanKullaniciMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_olusturanKullaniciMeta);
    }
    if (data.containsKey('olusturma_tarihi')) {
      context.handle(
        _olusturmaTarihiMeta,
        olusturmaTarihi.isAcceptableOrUnknown(
          data['olusturma_tarihi']!,
          _olusturmaTarihiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_olusturmaTarihiMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GunlukFaaliyetTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GunlukFaaliyetTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      faaliyetAdi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}faaliyet_adi'],
      )!,
      tarih: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tarih'],
      )!,
      olusturanKullanici: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}olusturan_kullanici'],
      )!,
      olusturmaTarihi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}olusturma_tarihi'],
      )!,
    );
  }

  @override
  $GunlukFaaliyetTableTable createAlias(String alias) {
    return $GunlukFaaliyetTableTable(attachedDatabase, alias);
  }
}

class GunlukFaaliyetTableData extends DataClass
    implements Insertable<GunlukFaaliyetTableData> {
  final int id;
  final String faaliyetAdi;
  final String tarih;
  final String olusturanKullanici;
  final String olusturmaTarihi;
  const GunlukFaaliyetTableData({
    required this.id,
    required this.faaliyetAdi,
    required this.tarih,
    required this.olusturanKullanici,
    required this.olusturmaTarihi,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['faaliyet_adi'] = Variable<String>(faaliyetAdi);
    map['tarih'] = Variable<String>(tarih);
    map['olusturan_kullanici'] = Variable<String>(olusturanKullanici);
    map['olusturma_tarihi'] = Variable<String>(olusturmaTarihi);
    return map;
  }

  GunlukFaaliyetTableCompanion toCompanion(bool nullToAbsent) {
    return GunlukFaaliyetTableCompanion(
      id: Value(id),
      faaliyetAdi: Value(faaliyetAdi),
      tarih: Value(tarih),
      olusturanKullanici: Value(olusturanKullanici),
      olusturmaTarihi: Value(olusturmaTarihi),
    );
  }

  factory GunlukFaaliyetTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GunlukFaaliyetTableData(
      id: serializer.fromJson<int>(json['id']),
      faaliyetAdi: serializer.fromJson<String>(json['faaliyetAdi']),
      tarih: serializer.fromJson<String>(json['tarih']),
      olusturanKullanici: serializer.fromJson<String>(
        json['olusturanKullanici'],
      ),
      olusturmaTarihi: serializer.fromJson<String>(json['olusturmaTarihi']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'faaliyetAdi': serializer.toJson<String>(faaliyetAdi),
      'tarih': serializer.toJson<String>(tarih),
      'olusturanKullanici': serializer.toJson<String>(olusturanKullanici),
      'olusturmaTarihi': serializer.toJson<String>(olusturmaTarihi),
    };
  }

  GunlukFaaliyetTableData copyWith({
    int? id,
    String? faaliyetAdi,
    String? tarih,
    String? olusturanKullanici,
    String? olusturmaTarihi,
  }) => GunlukFaaliyetTableData(
    id: id ?? this.id,
    faaliyetAdi: faaliyetAdi ?? this.faaliyetAdi,
    tarih: tarih ?? this.tarih,
    olusturanKullanici: olusturanKullanici ?? this.olusturanKullanici,
    olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
  );
  GunlukFaaliyetTableData copyWithCompanion(GunlukFaaliyetTableCompanion data) {
    return GunlukFaaliyetTableData(
      id: data.id.present ? data.id.value : this.id,
      faaliyetAdi: data.faaliyetAdi.present
          ? data.faaliyetAdi.value
          : this.faaliyetAdi,
      tarih: data.tarih.present ? data.tarih.value : this.tarih,
      olusturanKullanici: data.olusturanKullanici.present
          ? data.olusturanKullanici.value
          : this.olusturanKullanici,
      olusturmaTarihi: data.olusturmaTarihi.present
          ? data.olusturmaTarihi.value
          : this.olusturmaTarihi,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GunlukFaaliyetTableData(')
          ..write('id: $id, ')
          ..write('faaliyetAdi: $faaliyetAdi, ')
          ..write('tarih: $tarih, ')
          ..write('olusturanKullanici: $olusturanKullanici, ')
          ..write('olusturmaTarihi: $olusturmaTarihi')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, faaliyetAdi, tarih, olusturanKullanici, olusturmaTarihi);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GunlukFaaliyetTableData &&
          other.id == this.id &&
          other.faaliyetAdi == this.faaliyetAdi &&
          other.tarih == this.tarih &&
          other.olusturanKullanici == this.olusturanKullanici &&
          other.olusturmaTarihi == this.olusturmaTarihi);
}

class GunlukFaaliyetTableCompanion
    extends UpdateCompanion<GunlukFaaliyetTableData> {
  final Value<int> id;
  final Value<String> faaliyetAdi;
  final Value<String> tarih;
  final Value<String> olusturanKullanici;
  final Value<String> olusturmaTarihi;
  const GunlukFaaliyetTableCompanion({
    this.id = const Value.absent(),
    this.faaliyetAdi = const Value.absent(),
    this.tarih = const Value.absent(),
    this.olusturanKullanici = const Value.absent(),
    this.olusturmaTarihi = const Value.absent(),
  });
  GunlukFaaliyetTableCompanion.insert({
    this.id = const Value.absent(),
    required String faaliyetAdi,
    required String tarih,
    required String olusturanKullanici,
    required String olusturmaTarihi,
  }) : faaliyetAdi = Value(faaliyetAdi),
       tarih = Value(tarih),
       olusturanKullanici = Value(olusturanKullanici),
       olusturmaTarihi = Value(olusturmaTarihi);
  static Insertable<GunlukFaaliyetTableData> custom({
    Expression<int>? id,
    Expression<String>? faaliyetAdi,
    Expression<String>? tarih,
    Expression<String>? olusturanKullanici,
    Expression<String>? olusturmaTarihi,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (faaliyetAdi != null) 'faaliyet_adi': faaliyetAdi,
      if (tarih != null) 'tarih': tarih,
      if (olusturanKullanici != null) 'olusturan_kullanici': olusturanKullanici,
      if (olusturmaTarihi != null) 'olusturma_tarihi': olusturmaTarihi,
    });
  }

  GunlukFaaliyetTableCompanion copyWith({
    Value<int>? id,
    Value<String>? faaliyetAdi,
    Value<String>? tarih,
    Value<String>? olusturanKullanici,
    Value<String>? olusturmaTarihi,
  }) {
    return GunlukFaaliyetTableCompanion(
      id: id ?? this.id,
      faaliyetAdi: faaliyetAdi ?? this.faaliyetAdi,
      tarih: tarih ?? this.tarih,
      olusturanKullanici: olusturanKullanici ?? this.olusturanKullanici,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (faaliyetAdi.present) {
      map['faaliyet_adi'] = Variable<String>(faaliyetAdi.value);
    }
    if (tarih.present) {
      map['tarih'] = Variable<String>(tarih.value);
    }
    if (olusturanKullanici.present) {
      map['olusturan_kullanici'] = Variable<String>(olusturanKullanici.value);
    }
    if (olusturmaTarihi.present) {
      map['olusturma_tarihi'] = Variable<String>(olusturmaTarihi.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GunlukFaaliyetTableCompanion(')
          ..write('id: $id, ')
          ..write('faaliyetAdi: $faaliyetAdi, ')
          ..write('tarih: $tarih, ')
          ..write('olusturanKullanici: $olusturanKullanici, ')
          ..write('olusturmaTarihi: $olusturmaTarihi')
          ..write(')'))
        .toString();
  }
}

class $FaaliyetPersonelAtamaTableTable extends FaaliyetPersonelAtamaTable
    with
        TableInfo<
          $FaaliyetPersonelAtamaTableTable,
          FaaliyetPersonelAtamaTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FaaliyetPersonelAtamaTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _faaliyetIdMeta = const VerificationMeta(
    'faaliyetId',
  );
  @override
  late final GeneratedColumn<int> faaliyetId = GeneratedColumn<int>(
    'faaliyet_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES gunluk_faaliyet_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _personelIdMeta = const VerificationMeta(
    'personelId',
  );
  @override
  late final GeneratedColumn<int> personelId = GeneratedColumn<int>(
    'personel_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES personel_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _gorevVeyaIzinMeta = const VerificationMeta(
    'gorevVeyaIzin',
  );
  @override
  late final GeneratedColumn<String> gorevVeyaIzin = GeneratedColumn<String>(
    'gorev_veya_izin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durumMeta = const VerificationMeta('durum');
  @override
  late final GeneratedColumn<String> durum = GeneratedColumn<String>(
    'durum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aciklamaMeta = const VerificationMeta(
    'aciklama',
  );
  @override
  late final GeneratedColumn<String> aciklama = GeneratedColumn<String>(
    'aciklama',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    faaliyetId,
    personelId,
    gorevVeyaIzin,
    durum,
    aciklama,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'faaliyet_personel_atama_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<FaaliyetPersonelAtamaTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('faaliyet_id')) {
      context.handle(
        _faaliyetIdMeta,
        faaliyetId.isAcceptableOrUnknown(data['faaliyet_id']!, _faaliyetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_faaliyetIdMeta);
    }
    if (data.containsKey('personel_id')) {
      context.handle(
        _personelIdMeta,
        personelId.isAcceptableOrUnknown(data['personel_id']!, _personelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personelIdMeta);
    }
    if (data.containsKey('gorev_veya_izin')) {
      context.handle(
        _gorevVeyaIzinMeta,
        gorevVeyaIzin.isAcceptableOrUnknown(
          data['gorev_veya_izin']!,
          _gorevVeyaIzinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gorevVeyaIzinMeta);
    }
    if (data.containsKey('durum')) {
      context.handle(
        _durumMeta,
        durum.isAcceptableOrUnknown(data['durum']!, _durumMeta),
      );
    } else if (isInserting) {
      context.missing(_durumMeta);
    }
    if (data.containsKey('aciklama')) {
      context.handle(
        _aciklamaMeta,
        aciklama.isAcceptableOrUnknown(data['aciklama']!, _aciklamaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FaaliyetPersonelAtamaTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FaaliyetPersonelAtamaTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      faaliyetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}faaliyet_id'],
      )!,
      personelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}personel_id'],
      )!,
      gorevVeyaIzin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gorev_veya_izin'],
      )!,
      durum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}durum'],
      )!,
      aciklama: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aciklama'],
      ),
    );
  }

  @override
  $FaaliyetPersonelAtamaTableTable createAlias(String alias) {
    return $FaaliyetPersonelAtamaTableTable(attachedDatabase, alias);
  }
}

class FaaliyetPersonelAtamaTableData extends DataClass
    implements Insertable<FaaliyetPersonelAtamaTableData> {
  final int id;
  final int faaliyetId;
  final int personelId;
  final String gorevVeyaIzin;
  final String durum;
  final String? aciklama;
  const FaaliyetPersonelAtamaTableData({
    required this.id,
    required this.faaliyetId,
    required this.personelId,
    required this.gorevVeyaIzin,
    required this.durum,
    this.aciklama,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['faaliyet_id'] = Variable<int>(faaliyetId);
    map['personel_id'] = Variable<int>(personelId);
    map['gorev_veya_izin'] = Variable<String>(gorevVeyaIzin);
    map['durum'] = Variable<String>(durum);
    if (!nullToAbsent || aciklama != null) {
      map['aciklama'] = Variable<String>(aciklama);
    }
    return map;
  }

  FaaliyetPersonelAtamaTableCompanion toCompanion(bool nullToAbsent) {
    return FaaliyetPersonelAtamaTableCompanion(
      id: Value(id),
      faaliyetId: Value(faaliyetId),
      personelId: Value(personelId),
      gorevVeyaIzin: Value(gorevVeyaIzin),
      durum: Value(durum),
      aciklama: aciklama == null && nullToAbsent
          ? const Value.absent()
          : Value(aciklama),
    );
  }

  factory FaaliyetPersonelAtamaTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FaaliyetPersonelAtamaTableData(
      id: serializer.fromJson<int>(json['id']),
      faaliyetId: serializer.fromJson<int>(json['faaliyetId']),
      personelId: serializer.fromJson<int>(json['personelId']),
      gorevVeyaIzin: serializer.fromJson<String>(json['gorevVeyaIzin']),
      durum: serializer.fromJson<String>(json['durum']),
      aciklama: serializer.fromJson<String?>(json['aciklama']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'faaliyetId': serializer.toJson<int>(faaliyetId),
      'personelId': serializer.toJson<int>(personelId),
      'gorevVeyaIzin': serializer.toJson<String>(gorevVeyaIzin),
      'durum': serializer.toJson<String>(durum),
      'aciklama': serializer.toJson<String?>(aciklama),
    };
  }

  FaaliyetPersonelAtamaTableData copyWith({
    int? id,
    int? faaliyetId,
    int? personelId,
    String? gorevVeyaIzin,
    String? durum,
    Value<String?> aciklama = const Value.absent(),
  }) => FaaliyetPersonelAtamaTableData(
    id: id ?? this.id,
    faaliyetId: faaliyetId ?? this.faaliyetId,
    personelId: personelId ?? this.personelId,
    gorevVeyaIzin: gorevVeyaIzin ?? this.gorevVeyaIzin,
    durum: durum ?? this.durum,
    aciklama: aciklama.present ? aciklama.value : this.aciklama,
  );
  FaaliyetPersonelAtamaTableData copyWithCompanion(
    FaaliyetPersonelAtamaTableCompanion data,
  ) {
    return FaaliyetPersonelAtamaTableData(
      id: data.id.present ? data.id.value : this.id,
      faaliyetId: data.faaliyetId.present
          ? data.faaliyetId.value
          : this.faaliyetId,
      personelId: data.personelId.present
          ? data.personelId.value
          : this.personelId,
      gorevVeyaIzin: data.gorevVeyaIzin.present
          ? data.gorevVeyaIzin.value
          : this.gorevVeyaIzin,
      durum: data.durum.present ? data.durum.value : this.durum,
      aciklama: data.aciklama.present ? data.aciklama.value : this.aciklama,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FaaliyetPersonelAtamaTableData(')
          ..write('id: $id, ')
          ..write('faaliyetId: $faaliyetId, ')
          ..write('personelId: $personelId, ')
          ..write('gorevVeyaIzin: $gorevVeyaIzin, ')
          ..write('durum: $durum, ')
          ..write('aciklama: $aciklama')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, faaliyetId, personelId, gorevVeyaIzin, durum, aciklama);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FaaliyetPersonelAtamaTableData &&
          other.id == this.id &&
          other.faaliyetId == this.faaliyetId &&
          other.personelId == this.personelId &&
          other.gorevVeyaIzin == this.gorevVeyaIzin &&
          other.durum == this.durum &&
          other.aciklama == this.aciklama);
}

class FaaliyetPersonelAtamaTableCompanion
    extends UpdateCompanion<FaaliyetPersonelAtamaTableData> {
  final Value<int> id;
  final Value<int> faaliyetId;
  final Value<int> personelId;
  final Value<String> gorevVeyaIzin;
  final Value<String> durum;
  final Value<String?> aciklama;
  const FaaliyetPersonelAtamaTableCompanion({
    this.id = const Value.absent(),
    this.faaliyetId = const Value.absent(),
    this.personelId = const Value.absent(),
    this.gorevVeyaIzin = const Value.absent(),
    this.durum = const Value.absent(),
    this.aciklama = const Value.absent(),
  });
  FaaliyetPersonelAtamaTableCompanion.insert({
    this.id = const Value.absent(),
    required int faaliyetId,
    required int personelId,
    required String gorevVeyaIzin,
    required String durum,
    this.aciklama = const Value.absent(),
  }) : faaliyetId = Value(faaliyetId),
       personelId = Value(personelId),
       gorevVeyaIzin = Value(gorevVeyaIzin),
       durum = Value(durum);
  static Insertable<FaaliyetPersonelAtamaTableData> custom({
    Expression<int>? id,
    Expression<int>? faaliyetId,
    Expression<int>? personelId,
    Expression<String>? gorevVeyaIzin,
    Expression<String>? durum,
    Expression<String>? aciklama,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (faaliyetId != null) 'faaliyet_id': faaliyetId,
      if (personelId != null) 'personel_id': personelId,
      if (gorevVeyaIzin != null) 'gorev_veya_izin': gorevVeyaIzin,
      if (durum != null) 'durum': durum,
      if (aciklama != null) 'aciklama': aciklama,
    });
  }

  FaaliyetPersonelAtamaTableCompanion copyWith({
    Value<int>? id,
    Value<int>? faaliyetId,
    Value<int>? personelId,
    Value<String>? gorevVeyaIzin,
    Value<String>? durum,
    Value<String?>? aciklama,
  }) {
    return FaaliyetPersonelAtamaTableCompanion(
      id: id ?? this.id,
      faaliyetId: faaliyetId ?? this.faaliyetId,
      personelId: personelId ?? this.personelId,
      gorevVeyaIzin: gorevVeyaIzin ?? this.gorevVeyaIzin,
      durum: durum ?? this.durum,
      aciklama: aciklama ?? this.aciklama,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (faaliyetId.present) {
      map['faaliyet_id'] = Variable<int>(faaliyetId.value);
    }
    if (personelId.present) {
      map['personel_id'] = Variable<int>(personelId.value);
    }
    if (gorevVeyaIzin.present) {
      map['gorev_veya_izin'] = Variable<String>(gorevVeyaIzin.value);
    }
    if (durum.present) {
      map['durum'] = Variable<String>(durum.value);
    }
    if (aciklama.present) {
      map['aciklama'] = Variable<String>(aciklama.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FaaliyetPersonelAtamaTableCompanion(')
          ..write('id: $id, ')
          ..write('faaliyetId: $faaliyetId, ')
          ..write('personelId: $personelId, ')
          ..write('gorevVeyaIzin: $gorevVeyaIzin, ')
          ..write('durum: $durum, ')
          ..write('aciklama: $aciklama')
          ..write(')'))
        .toString();
  }
}

class $RaporKayitTableTable extends RaporKayitTable
    with TableInfo<$RaporKayitTableTable, RaporKayitTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RaporKayitTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _personelIdMeta = const VerificationMeta(
    'personelId',
  );
  @override
  late final GeneratedColumn<int> personelId = GeneratedColumn<int>(
    'personel_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES personel_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _raporBaslangicMeta = const VerificationMeta(
    'raporBaslangic',
  );
  @override
  late final GeneratedColumn<String> raporBaslangic = GeneratedColumn<String>(
    'rapor_baslangic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _raporBitisMeta = const VerificationMeta(
    'raporBitis',
  );
  @override
  late final GeneratedColumn<String> raporBitis = GeneratedColumn<String>(
    'rapor_bitis',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aciklamaMeta = const VerificationMeta(
    'aciklama',
  );
  @override
  late final GeneratedColumn<String> aciklama = GeneratedColumn<String>(
    'aciklama',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personelId,
    raporBaslangic,
    raporBitis,
    aciklama,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rapor_kayit_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<RaporKayitTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('personel_id')) {
      context.handle(
        _personelIdMeta,
        personelId.isAcceptableOrUnknown(data['personel_id']!, _personelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personelIdMeta);
    }
    if (data.containsKey('rapor_baslangic')) {
      context.handle(
        _raporBaslangicMeta,
        raporBaslangic.isAcceptableOrUnknown(
          data['rapor_baslangic']!,
          _raporBaslangicMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_raporBaslangicMeta);
    }
    if (data.containsKey('rapor_bitis')) {
      context.handle(
        _raporBitisMeta,
        raporBitis.isAcceptableOrUnknown(data['rapor_bitis']!, _raporBitisMeta),
      );
    } else if (isInserting) {
      context.missing(_raporBitisMeta);
    }
    if (data.containsKey('aciklama')) {
      context.handle(
        _aciklamaMeta,
        aciklama.isAcceptableOrUnknown(data['aciklama']!, _aciklamaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RaporKayitTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RaporKayitTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      personelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}personel_id'],
      )!,
      raporBaslangic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rapor_baslangic'],
      )!,
      raporBitis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rapor_bitis'],
      )!,
      aciklama: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aciklama'],
      ),
    );
  }

  @override
  $RaporKayitTableTable createAlias(String alias) {
    return $RaporKayitTableTable(attachedDatabase, alias);
  }
}

class RaporKayitTableData extends DataClass
    implements Insertable<RaporKayitTableData> {
  final int id;
  final int personelId;
  final String raporBaslangic;
  final String raporBitis;
  final String? aciklama;
  const RaporKayitTableData({
    required this.id,
    required this.personelId,
    required this.raporBaslangic,
    required this.raporBitis,
    this.aciklama,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['personel_id'] = Variable<int>(personelId);
    map['rapor_baslangic'] = Variable<String>(raporBaslangic);
    map['rapor_bitis'] = Variable<String>(raporBitis);
    if (!nullToAbsent || aciklama != null) {
      map['aciklama'] = Variable<String>(aciklama);
    }
    return map;
  }

  RaporKayitTableCompanion toCompanion(bool nullToAbsent) {
    return RaporKayitTableCompanion(
      id: Value(id),
      personelId: Value(personelId),
      raporBaslangic: Value(raporBaslangic),
      raporBitis: Value(raporBitis),
      aciklama: aciklama == null && nullToAbsent
          ? const Value.absent()
          : Value(aciklama),
    );
  }

  factory RaporKayitTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RaporKayitTableData(
      id: serializer.fromJson<int>(json['id']),
      personelId: serializer.fromJson<int>(json['personelId']),
      raporBaslangic: serializer.fromJson<String>(json['raporBaslangic']),
      raporBitis: serializer.fromJson<String>(json['raporBitis']),
      aciklama: serializer.fromJson<String?>(json['aciklama']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personelId': serializer.toJson<int>(personelId),
      'raporBaslangic': serializer.toJson<String>(raporBaslangic),
      'raporBitis': serializer.toJson<String>(raporBitis),
      'aciklama': serializer.toJson<String?>(aciklama),
    };
  }

  RaporKayitTableData copyWith({
    int? id,
    int? personelId,
    String? raporBaslangic,
    String? raporBitis,
    Value<String?> aciklama = const Value.absent(),
  }) => RaporKayitTableData(
    id: id ?? this.id,
    personelId: personelId ?? this.personelId,
    raporBaslangic: raporBaslangic ?? this.raporBaslangic,
    raporBitis: raporBitis ?? this.raporBitis,
    aciklama: aciklama.present ? aciklama.value : this.aciklama,
  );
  RaporKayitTableData copyWithCompanion(RaporKayitTableCompanion data) {
    return RaporKayitTableData(
      id: data.id.present ? data.id.value : this.id,
      personelId: data.personelId.present
          ? data.personelId.value
          : this.personelId,
      raporBaslangic: data.raporBaslangic.present
          ? data.raporBaslangic.value
          : this.raporBaslangic,
      raporBitis: data.raporBitis.present
          ? data.raporBitis.value
          : this.raporBitis,
      aciklama: data.aciklama.present ? data.aciklama.value : this.aciklama,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RaporKayitTableData(')
          ..write('id: $id, ')
          ..write('personelId: $personelId, ')
          ..write('raporBaslangic: $raporBaslangic, ')
          ..write('raporBitis: $raporBitis, ')
          ..write('aciklama: $aciklama')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, personelId, raporBaslangic, raporBitis, aciklama);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RaporKayitTableData &&
          other.id == this.id &&
          other.personelId == this.personelId &&
          other.raporBaslangic == this.raporBaslangic &&
          other.raporBitis == this.raporBitis &&
          other.aciklama == this.aciklama);
}

class RaporKayitTableCompanion extends UpdateCompanion<RaporKayitTableData> {
  final Value<int> id;
  final Value<int> personelId;
  final Value<String> raporBaslangic;
  final Value<String> raporBitis;
  final Value<String?> aciklama;
  const RaporKayitTableCompanion({
    this.id = const Value.absent(),
    this.personelId = const Value.absent(),
    this.raporBaslangic = const Value.absent(),
    this.raporBitis = const Value.absent(),
    this.aciklama = const Value.absent(),
  });
  RaporKayitTableCompanion.insert({
    this.id = const Value.absent(),
    required int personelId,
    required String raporBaslangic,
    required String raporBitis,
    this.aciklama = const Value.absent(),
  }) : personelId = Value(personelId),
       raporBaslangic = Value(raporBaslangic),
       raporBitis = Value(raporBitis);
  static Insertable<RaporKayitTableData> custom({
    Expression<int>? id,
    Expression<int>? personelId,
    Expression<String>? raporBaslangic,
    Expression<String>? raporBitis,
    Expression<String>? aciklama,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personelId != null) 'personel_id': personelId,
      if (raporBaslangic != null) 'rapor_baslangic': raporBaslangic,
      if (raporBitis != null) 'rapor_bitis': raporBitis,
      if (aciklama != null) 'aciklama': aciklama,
    });
  }

  RaporKayitTableCompanion copyWith({
    Value<int>? id,
    Value<int>? personelId,
    Value<String>? raporBaslangic,
    Value<String>? raporBitis,
    Value<String?>? aciklama,
  }) {
    return RaporKayitTableCompanion(
      id: id ?? this.id,
      personelId: personelId ?? this.personelId,
      raporBaslangic: raporBaslangic ?? this.raporBaslangic,
      raporBitis: raporBitis ?? this.raporBitis,
      aciklama: aciklama ?? this.aciklama,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personelId.present) {
      map['personel_id'] = Variable<int>(personelId.value);
    }
    if (raporBaslangic.present) {
      map['rapor_baslangic'] = Variable<String>(raporBaslangic.value);
    }
    if (raporBitis.present) {
      map['rapor_bitis'] = Variable<String>(raporBitis.value);
    }
    if (aciklama.present) {
      map['aciklama'] = Variable<String>(aciklama.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RaporKayitTableCompanion(')
          ..write('id: $id, ')
          ..write('personelId: $personelId, ')
          ..write('raporBaslangic: $raporBaslangic, ')
          ..write('raporBitis: $raporBitis, ')
          ..write('aciklama: $aciklama')
          ..write(')'))
        .toString();
  }
}

class $TimUyelikGecmisiTableTable extends TimUyelikGecmisiTable
    with TableInfo<$TimUyelikGecmisiTableTable, TimUyelikGecmisiTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimUyelikGecmisiTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _personelIdMeta = const VerificationMeta(
    'personelId',
  );
  @override
  late final GeneratedColumn<int> personelId = GeneratedColumn<int>(
    'personel_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timIdMeta = const VerificationMeta('timId');
  @override
  late final GeneratedColumn<int> timId = GeneratedColumn<int>(
    'tim_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tim_table (id)',
    ),
  );
  static const VerificationMeta _tarihMeta = const VerificationMeta('tarih');
  @override
  late final GeneratedColumn<String> tarih = GeneratedColumn<String>(
    'tarih',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _islemMeta = const VerificationMeta('islem');
  @override
  late final GeneratedColumn<String> islem = GeneratedColumn<String>(
    'islem',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, personelId, timId, tarih, islem];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tim_uyelik_gecmisi_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimUyelikGecmisiTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('personel_id')) {
      context.handle(
        _personelIdMeta,
        personelId.isAcceptableOrUnknown(data['personel_id']!, _personelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personelIdMeta);
    }
    if (data.containsKey('tim_id')) {
      context.handle(
        _timIdMeta,
        timId.isAcceptableOrUnknown(data['tim_id']!, _timIdMeta),
      );
    }
    if (data.containsKey('tarih')) {
      context.handle(
        _tarihMeta,
        tarih.isAcceptableOrUnknown(data['tarih']!, _tarihMeta),
      );
    } else if (isInserting) {
      context.missing(_tarihMeta);
    }
    if (data.containsKey('islem')) {
      context.handle(
        _islemMeta,
        islem.isAcceptableOrUnknown(data['islem']!, _islemMeta),
      );
    } else if (isInserting) {
      context.missing(_islemMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimUyelikGecmisiTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimUyelikGecmisiTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      personelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}personel_id'],
      )!,
      timId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tim_id'],
      ),
      tarih: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tarih'],
      )!,
      islem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}islem'],
      )!,
    );
  }

  @override
  $TimUyelikGecmisiTableTable createAlias(String alias) {
    return $TimUyelikGecmisiTableTable(attachedDatabase, alias);
  }
}

class TimUyelikGecmisiTableData extends DataClass
    implements Insertable<TimUyelikGecmisiTableData> {
  final int id;
  final int personelId;
  final int? timId;
  final String tarih;
  final String islem;
  const TimUyelikGecmisiTableData({
    required this.id,
    required this.personelId,
    this.timId,
    required this.tarih,
    required this.islem,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['personel_id'] = Variable<int>(personelId);
    if (!nullToAbsent || timId != null) {
      map['tim_id'] = Variable<int>(timId);
    }
    map['tarih'] = Variable<String>(tarih);
    map['islem'] = Variable<String>(islem);
    return map;
  }

  TimUyelikGecmisiTableCompanion toCompanion(bool nullToAbsent) {
    return TimUyelikGecmisiTableCompanion(
      id: Value(id),
      personelId: Value(personelId),
      timId: timId == null && nullToAbsent
          ? const Value.absent()
          : Value(timId),
      tarih: Value(tarih),
      islem: Value(islem),
    );
  }

  factory TimUyelikGecmisiTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimUyelikGecmisiTableData(
      id: serializer.fromJson<int>(json['id']),
      personelId: serializer.fromJson<int>(json['personelId']),
      timId: serializer.fromJson<int?>(json['timId']),
      tarih: serializer.fromJson<String>(json['tarih']),
      islem: serializer.fromJson<String>(json['islem']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personelId': serializer.toJson<int>(personelId),
      'timId': serializer.toJson<int?>(timId),
      'tarih': serializer.toJson<String>(tarih),
      'islem': serializer.toJson<String>(islem),
    };
  }

  TimUyelikGecmisiTableData copyWith({
    int? id,
    int? personelId,
    Value<int?> timId = const Value.absent(),
    String? tarih,
    String? islem,
  }) => TimUyelikGecmisiTableData(
    id: id ?? this.id,
    personelId: personelId ?? this.personelId,
    timId: timId.present ? timId.value : this.timId,
    tarih: tarih ?? this.tarih,
    islem: islem ?? this.islem,
  );
  TimUyelikGecmisiTableData copyWithCompanion(
    TimUyelikGecmisiTableCompanion data,
  ) {
    return TimUyelikGecmisiTableData(
      id: data.id.present ? data.id.value : this.id,
      personelId: data.personelId.present
          ? data.personelId.value
          : this.personelId,
      timId: data.timId.present ? data.timId.value : this.timId,
      tarih: data.tarih.present ? data.tarih.value : this.tarih,
      islem: data.islem.present ? data.islem.value : this.islem,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimUyelikGecmisiTableData(')
          ..write('id: $id, ')
          ..write('personelId: $personelId, ')
          ..write('timId: $timId, ')
          ..write('tarih: $tarih, ')
          ..write('islem: $islem')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, personelId, timId, tarih, islem);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimUyelikGecmisiTableData &&
          other.id == this.id &&
          other.personelId == this.personelId &&
          other.timId == this.timId &&
          other.tarih == this.tarih &&
          other.islem == this.islem);
}

class TimUyelikGecmisiTableCompanion
    extends UpdateCompanion<TimUyelikGecmisiTableData> {
  final Value<int> id;
  final Value<int> personelId;
  final Value<int?> timId;
  final Value<String> tarih;
  final Value<String> islem;
  const TimUyelikGecmisiTableCompanion({
    this.id = const Value.absent(),
    this.personelId = const Value.absent(),
    this.timId = const Value.absent(),
    this.tarih = const Value.absent(),
    this.islem = const Value.absent(),
  });
  TimUyelikGecmisiTableCompanion.insert({
    this.id = const Value.absent(),
    required int personelId,
    this.timId = const Value.absent(),
    required String tarih,
    required String islem,
  }) : personelId = Value(personelId),
       tarih = Value(tarih),
       islem = Value(islem);
  static Insertable<TimUyelikGecmisiTableData> custom({
    Expression<int>? id,
    Expression<int>? personelId,
    Expression<int>? timId,
    Expression<String>? tarih,
    Expression<String>? islem,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personelId != null) 'personel_id': personelId,
      if (timId != null) 'tim_id': timId,
      if (tarih != null) 'tarih': tarih,
      if (islem != null) 'islem': islem,
    });
  }

  TimUyelikGecmisiTableCompanion copyWith({
    Value<int>? id,
    Value<int>? personelId,
    Value<int?>? timId,
    Value<String>? tarih,
    Value<String>? islem,
  }) {
    return TimUyelikGecmisiTableCompanion(
      id: id ?? this.id,
      personelId: personelId ?? this.personelId,
      timId: timId ?? this.timId,
      tarih: tarih ?? this.tarih,
      islem: islem ?? this.islem,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personelId.present) {
      map['personel_id'] = Variable<int>(personelId.value);
    }
    if (timId.present) {
      map['tim_id'] = Variable<int>(timId.value);
    }
    if (tarih.present) {
      map['tarih'] = Variable<String>(tarih.value);
    }
    if (islem.present) {
      map['islem'] = Variable<String>(islem.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimUyelikGecmisiTableCompanion(')
          ..write('id: $id, ')
          ..write('personelId: $personelId, ')
          ..write('timId: $timId, ')
          ..write('tarih: $tarih, ')
          ..write('islem: $islem')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TimTableTable timTable = $TimTableTable(this);
  late final $KullaniciTableTable kullaniciTable = $KullaniciTableTable(this);
  late final $PersonelTableTable personelTable = $PersonelTableTable(this);
  late final $GunlukFaaliyetTableTable gunlukFaaliyetTable =
      $GunlukFaaliyetTableTable(this);
  late final $FaaliyetPersonelAtamaTableTable faaliyetPersonelAtamaTable =
      $FaaliyetPersonelAtamaTableTable(this);
  late final $RaporKayitTableTable raporKayitTable = $RaporKayitTableTable(
    this,
  );
  late final $TimUyelikGecmisiTableTable timUyelikGecmisiTable =
      $TimUyelikGecmisiTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    timTable,
    kullaniciTable,
    personelTable,
    gunlukFaaliyetTable,
    faaliyetPersonelAtamaTable,
    raporKayitTable,
    timUyelikGecmisiTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'gunluk_faaliyet_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('faaliyet_personel_atama_table', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'personel_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('faaliyet_personel_atama_table', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'personel_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rapor_kayit_table', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TimTableTableCreateCompanionBuilder =
    TimTableCompanion Function({
      Value<int> id,
      required String timAdi,
      Value<int?> timKomutaniId,
      required String olusturmaTarihi,
    });
typedef $$TimTableTableUpdateCompanionBuilder =
    TimTableCompanion Function({
      Value<int> id,
      Value<String> timAdi,
      Value<int?> timKomutaniId,
      Value<String> olusturmaTarihi,
    });

final class $$TimTableTableReferences
    extends BaseReferences<_$AppDatabase, $TimTableTable, TimTableData> {
  $$TimTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KullaniciTableTable _timKomutaniIdTable(_$AppDatabase db) => db
      .kullaniciTable
      .createAlias('tim_table__tim_komutani_id__kullanici_table__id');

  $$KullaniciTableTableProcessedTableManager? get timKomutaniId {
    final $_column = $_itemColumn<int>('tim_komutani_id');
    if ($_column == null) return null;
    final manager = $$KullaniciTableTableTableManager(
      $_db,
      $_db.kullaniciTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_timKomutaniIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$KullaniciTableTable, List<KullaniciTableData>>
  _kullaniciTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.kullaniciTable,
    aliasName: 'tim_table__id__kullanici_table__tim_id',
  );

  $$KullaniciTableTableProcessedTableManager get kullaniciTableRefs {
    final manager = $$KullaniciTableTableTableManager(
      $_db,
      $_db.kullaniciTable,
    ).filter((f) => f.timId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_kullaniciTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PersonelTableTable, List<PersonelTableData>>
  _personelTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.personelTable,
    aliasName: 'tim_table__id__personel_table__tim_id',
  );

  $$PersonelTableTableProcessedTableManager get personelTableRefs {
    final manager = $$PersonelTableTableTableManager(
      $_db,
      $_db.personelTable,
    ).filter((f) => f.timId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_personelTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TimUyelikGecmisiTableTable,
    List<TimUyelikGecmisiTableData>
  >
  _timUyelikGecmisiTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.timUyelikGecmisiTable,
        aliasName: 'tim_table__id__tim_uyelik_gecmisi_table__tim_id',
      );

  $$TimUyelikGecmisiTableTableProcessedTableManager
  get timUyelikGecmisiTableRefs {
    final manager = $$TimUyelikGecmisiTableTableTableManager(
      $_db,
      $_db.timUyelikGecmisiTable,
    ).filter((f) => f.timId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _timUyelikGecmisiTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TimTableTableFilterComposer
    extends Composer<_$AppDatabase, $TimTableTable> {
  $$TimTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timAdi => $composableBuilder(
    column: $table.timAdi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get olusturmaTarihi => $composableBuilder(
    column: $table.olusturmaTarihi,
    builder: (column) => ColumnFilters(column),
  );

  $$KullaniciTableTableFilterComposer get timKomutaniId {
    final $$KullaniciTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timKomutaniId,
      referencedTable: $db.kullaniciTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KullaniciTableTableFilterComposer(
            $db: $db,
            $table: $db.kullaniciTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> kullaniciTableRefs(
    Expression<bool> Function($$KullaniciTableTableFilterComposer f) f,
  ) {
    final $$KullaniciTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kullaniciTable,
      getReferencedColumn: (t) => t.timId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KullaniciTableTableFilterComposer(
            $db: $db,
            $table: $db.kullaniciTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> personelTableRefs(
    Expression<bool> Function($$PersonelTableTableFilterComposer f) f,
  ) {
    final $$PersonelTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personelTable,
      getReferencedColumn: (t) => t.timId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonelTableTableFilterComposer(
            $db: $db,
            $table: $db.personelTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> timUyelikGecmisiTableRefs(
    Expression<bool> Function($$TimUyelikGecmisiTableTableFilterComposer f) f,
  ) {
    final $$TimUyelikGecmisiTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.timUyelikGecmisiTable,
          getReferencedColumn: (t) => t.timId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TimUyelikGecmisiTableTableFilterComposer(
                $db: $db,
                $table: $db.timUyelikGecmisiTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TimTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TimTableTable> {
  $$TimTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timAdi => $composableBuilder(
    column: $table.timAdi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get olusturmaTarihi => $composableBuilder(
    column: $table.olusturmaTarihi,
    builder: (column) => ColumnOrderings(column),
  );

  $$KullaniciTableTableOrderingComposer get timKomutaniId {
    final $$KullaniciTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timKomutaniId,
      referencedTable: $db.kullaniciTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KullaniciTableTableOrderingComposer(
            $db: $db,
            $table: $db.kullaniciTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimTableTable> {
  $$TimTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get timAdi =>
      $composableBuilder(column: $table.timAdi, builder: (column) => column);

  GeneratedColumn<String> get olusturmaTarihi => $composableBuilder(
    column: $table.olusturmaTarihi,
    builder: (column) => column,
  );

  $$KullaniciTableTableAnnotationComposer get timKomutaniId {
    final $$KullaniciTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timKomutaniId,
      referencedTable: $db.kullaniciTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KullaniciTableTableAnnotationComposer(
            $db: $db,
            $table: $db.kullaniciTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> kullaniciTableRefs<T extends Object>(
    Expression<T> Function($$KullaniciTableTableAnnotationComposer a) f,
  ) {
    final $$KullaniciTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kullaniciTable,
      getReferencedColumn: (t) => t.timId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KullaniciTableTableAnnotationComposer(
            $db: $db,
            $table: $db.kullaniciTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> personelTableRefs<T extends Object>(
    Expression<T> Function($$PersonelTableTableAnnotationComposer a) f,
  ) {
    final $$PersonelTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personelTable,
      getReferencedColumn: (t) => t.timId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonelTableTableAnnotationComposer(
            $db: $db,
            $table: $db.personelTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> timUyelikGecmisiTableRefs<T extends Object>(
    Expression<T> Function($$TimUyelikGecmisiTableTableAnnotationComposer a) f,
  ) {
    final $$TimUyelikGecmisiTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.timUyelikGecmisiTable,
          getReferencedColumn: (t) => t.timId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TimUyelikGecmisiTableTableAnnotationComposer(
                $db: $db,
                $table: $db.timUyelikGecmisiTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TimTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimTableTable,
          TimTableData,
          $$TimTableTableFilterComposer,
          $$TimTableTableOrderingComposer,
          $$TimTableTableAnnotationComposer,
          $$TimTableTableCreateCompanionBuilder,
          $$TimTableTableUpdateCompanionBuilder,
          (TimTableData, $$TimTableTableReferences),
          TimTableData,
          PrefetchHooks Function({
            bool timKomutaniId,
            bool kullaniciTableRefs,
            bool personelTableRefs,
            bool timUyelikGecmisiTableRefs,
          })
        > {
  $$TimTableTableTableManager(_$AppDatabase db, $TimTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> timAdi = const Value.absent(),
                Value<int?> timKomutaniId = const Value.absent(),
                Value<String> olusturmaTarihi = const Value.absent(),
              }) => TimTableCompanion(
                id: id,
                timAdi: timAdi,
                timKomutaniId: timKomutaniId,
                olusturmaTarihi: olusturmaTarihi,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String timAdi,
                Value<int?> timKomutaniId = const Value.absent(),
                required String olusturmaTarihi,
              }) => TimTableCompanion.insert(
                id: id,
                timAdi: timAdi,
                timKomutaniId: timKomutaniId,
                olusturmaTarihi: olusturmaTarihi,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TimTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                timKomutaniId = false,
                kullaniciTableRefs = false,
                personelTableRefs = false,
                timUyelikGecmisiTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (kullaniciTableRefs) db.kullaniciTable,
                    if (personelTableRefs) db.personelTable,
                    if (timUyelikGecmisiTableRefs) db.timUyelikGecmisiTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (timKomutaniId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.timKomutaniId,
                                    referencedTable: $$TimTableTableReferences
                                        ._timKomutaniIdTable(db),
                                    referencedColumn: $$TimTableTableReferences
                                        ._timKomutaniIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (kullaniciTableRefs)
                        await $_getPrefetchedData<
                          TimTableData,
                          $TimTableTable,
                          KullaniciTableData
                        >(
                          currentTable: table,
                          referencedTable: $$TimTableTableReferences
                              ._kullaniciTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TimTableTableReferences(
                                db,
                                table,
                                p0,
                              ).kullaniciTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.timId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (personelTableRefs)
                        await $_getPrefetchedData<
                          TimTableData,
                          $TimTableTable,
                          PersonelTableData
                        >(
                          currentTable: table,
                          referencedTable: $$TimTableTableReferences
                              ._personelTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TimTableTableReferences(
                                db,
                                table,
                                p0,
                              ).personelTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.timId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (timUyelikGecmisiTableRefs)
                        await $_getPrefetchedData<
                          TimTableData,
                          $TimTableTable,
                          TimUyelikGecmisiTableData
                        >(
                          currentTable: table,
                          referencedTable: $$TimTableTableReferences
                              ._timUyelikGecmisiTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TimTableTableReferences(
                                db,
                                table,
                                p0,
                              ).timUyelikGecmisiTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.timId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TimTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimTableTable,
      TimTableData,
      $$TimTableTableFilterComposer,
      $$TimTableTableOrderingComposer,
      $$TimTableTableAnnotationComposer,
      $$TimTableTableCreateCompanionBuilder,
      $$TimTableTableUpdateCompanionBuilder,
      (TimTableData, $$TimTableTableReferences),
      TimTableData,
      PrefetchHooks Function({
        bool timKomutaniId,
        bool kullaniciTableRefs,
        bool personelTableRefs,
        bool timUyelikGecmisiTableRefs,
      })
    >;
typedef $$KullaniciTableTableCreateCompanionBuilder =
    KullaniciTableCompanion Function({
      Value<int> id,
      required String kullaniciAdi,
      Value<String> sifre,
      required String rol,
      Value<int?> timId,
    });
typedef $$KullaniciTableTableUpdateCompanionBuilder =
    KullaniciTableCompanion Function({
      Value<int> id,
      Value<String> kullaniciAdi,
      Value<String> sifre,
      Value<String> rol,
      Value<int?> timId,
    });

final class $$KullaniciTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $KullaniciTableTable,
          KullaniciTableData
        > {
  $$KullaniciTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TimTableTable _timIdTable(_$AppDatabase db) =>
      db.timTable.createAlias('kullanici_table__tim_id__tim_table__id');

  $$TimTableTableProcessedTableManager? get timId {
    final $_column = $_itemColumn<int>('tim_id');
    if ($_column == null) return null;
    final manager = $$TimTableTableTableManager(
      $_db,
      $_db.timTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_timIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TimTableTable, List<TimTableData>>
  _timTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.timTable,
    aliasName: 'kullanici_table__id__tim_table__tim_komutani_id',
  );

  $$TimTableTableProcessedTableManager get timTableRefs {
    final manager = $$TimTableTableTableManager(
      $_db,
      $_db.timTable,
    ).filter((f) => f.timKomutaniId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_timTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$KullaniciTableTableFilterComposer
    extends Composer<_$AppDatabase, $KullaniciTableTable> {
  $$KullaniciTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kullaniciAdi => $composableBuilder(
    column: $table.kullaniciAdi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sifre => $composableBuilder(
    column: $table.sifre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnFilters(column),
  );

  $$TimTableTableFilterComposer get timId {
    final $$TimTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timId,
      referencedTable: $db.timTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimTableTableFilterComposer(
            $db: $db,
            $table: $db.timTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> timTableRefs(
    Expression<bool> Function($$TimTableTableFilterComposer f) f,
  ) {
    final $$TimTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timTable,
      getReferencedColumn: (t) => t.timKomutaniId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimTableTableFilterComposer(
            $db: $db,
            $table: $db.timTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KullaniciTableTableOrderingComposer
    extends Composer<_$AppDatabase, $KullaniciTableTable> {
  $$KullaniciTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kullaniciAdi => $composableBuilder(
    column: $table.kullaniciAdi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sifre => $composableBuilder(
    column: $table.sifre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnOrderings(column),
  );

  $$TimTableTableOrderingComposer get timId {
    final $$TimTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timId,
      referencedTable: $db.timTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimTableTableOrderingComposer(
            $db: $db,
            $table: $db.timTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KullaniciTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $KullaniciTableTable> {
  $$KullaniciTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kullaniciAdi => $composableBuilder(
    column: $table.kullaniciAdi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sifre =>
      $composableBuilder(column: $table.sifre, builder: (column) => column);

  GeneratedColumn<String> get rol =>
      $composableBuilder(column: $table.rol, builder: (column) => column);

  $$TimTableTableAnnotationComposer get timId {
    final $$TimTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timId,
      referencedTable: $db.timTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimTableTableAnnotationComposer(
            $db: $db,
            $table: $db.timTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> timTableRefs<T extends Object>(
    Expression<T> Function($$TimTableTableAnnotationComposer a) f,
  ) {
    final $$TimTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timTable,
      getReferencedColumn: (t) => t.timKomutaniId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimTableTableAnnotationComposer(
            $db: $db,
            $table: $db.timTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KullaniciTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KullaniciTableTable,
          KullaniciTableData,
          $$KullaniciTableTableFilterComposer,
          $$KullaniciTableTableOrderingComposer,
          $$KullaniciTableTableAnnotationComposer,
          $$KullaniciTableTableCreateCompanionBuilder,
          $$KullaniciTableTableUpdateCompanionBuilder,
          (KullaniciTableData, $$KullaniciTableTableReferences),
          KullaniciTableData,
          PrefetchHooks Function({bool timId, bool timTableRefs})
        > {
  $$KullaniciTableTableTableManager(
    _$AppDatabase db,
    $KullaniciTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KullaniciTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KullaniciTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KullaniciTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kullaniciAdi = const Value.absent(),
                Value<String> sifre = const Value.absent(),
                Value<String> rol = const Value.absent(),
                Value<int?> timId = const Value.absent(),
              }) => KullaniciTableCompanion(
                id: id,
                kullaniciAdi: kullaniciAdi,
                sifre: sifre,
                rol: rol,
                timId: timId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kullaniciAdi,
                Value<String> sifre = const Value.absent(),
                required String rol,
                Value<int?> timId = const Value.absent(),
              }) => KullaniciTableCompanion.insert(
                id: id,
                kullaniciAdi: kullaniciAdi,
                sifre: sifre,
                rol: rol,
                timId: timId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$KullaniciTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({timId = false, timTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (timTableRefs) db.timTable],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (timId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.timId,
                                referencedTable: $$KullaniciTableTableReferences
                                    ._timIdTable(db),
                                referencedColumn:
                                    $$KullaniciTableTableReferences
                                        ._timIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (timTableRefs)
                    await $_getPrefetchedData<
                      KullaniciTableData,
                      $KullaniciTableTable,
                      TimTableData
                    >(
                      currentTable: table,
                      referencedTable: $$KullaniciTableTableReferences
                          ._timTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$KullaniciTableTableReferences(
                            db,
                            table,
                            p0,
                          ).timTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.timKomutaniId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$KullaniciTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KullaniciTableTable,
      KullaniciTableData,
      $$KullaniciTableTableFilterComposer,
      $$KullaniciTableTableOrderingComposer,
      $$KullaniciTableTableAnnotationComposer,
      $$KullaniciTableTableCreateCompanionBuilder,
      $$KullaniciTableTableUpdateCompanionBuilder,
      (KullaniciTableData, $$KullaniciTableTableReferences),
      KullaniciTableData,
      PrefetchHooks Function({bool timId, bool timTableRefs})
    >;
typedef $$PersonelTableTableCreateCompanionBuilder =
    PersonelTableCompanion Function({
      Value<int> id,
      required String adSoyad,
      required String rutbe,
      required String birlik,
      Value<int?> timId,
      required String kayitTarihi,
    });
typedef $$PersonelTableTableUpdateCompanionBuilder =
    PersonelTableCompanion Function({
      Value<int> id,
      Value<String> adSoyad,
      Value<String> rutbe,
      Value<String> birlik,
      Value<int?> timId,
      Value<String> kayitTarihi,
    });

final class $$PersonelTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $PersonelTableTable, PersonelTableData> {
  $$PersonelTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TimTableTable _timIdTable(_$AppDatabase db) =>
      db.timTable.createAlias('personel_table__tim_id__tim_table__id');

  $$TimTableTableProcessedTableManager? get timId {
    final $_column = $_itemColumn<int>('tim_id');
    if ($_column == null) return null;
    final manager = $$TimTableTableTableManager(
      $_db,
      $_db.timTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_timIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $FaaliyetPersonelAtamaTableTable,
    List<FaaliyetPersonelAtamaTableData>
  >
  _faaliyetPersonelAtamaTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.faaliyetPersonelAtamaTable,
        aliasName:
            'personel_table__id__faaliyet_personel_atama_table__personel_id',
      );

  $$FaaliyetPersonelAtamaTableTableProcessedTableManager
  get faaliyetPersonelAtamaTableRefs {
    final manager = $$FaaliyetPersonelAtamaTableTableTableManager(
      $_db,
      $_db.faaliyetPersonelAtamaTable,
    ).filter((f) => f.personelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _faaliyetPersonelAtamaTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RaporKayitTableTable, List<RaporKayitTableData>>
  _raporKayitTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.raporKayitTable,
    aliasName: 'personel_table__id__rapor_kayit_table__personel_id',
  );

  $$RaporKayitTableTableProcessedTableManager get raporKayitTableRefs {
    final manager = $$RaporKayitTableTableTableManager(
      $_db,
      $_db.raporKayitTable,
    ).filter((f) => f.personelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _raporKayitTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PersonelTableTableFilterComposer
    extends Composer<_$AppDatabase, $PersonelTableTable> {
  $$PersonelTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adSoyad => $composableBuilder(
    column: $table.adSoyad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rutbe => $composableBuilder(
    column: $table.rutbe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get birlik => $composableBuilder(
    column: $table.birlik,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kayitTarihi => $composableBuilder(
    column: $table.kayitTarihi,
    builder: (column) => ColumnFilters(column),
  );

  $$TimTableTableFilterComposer get timId {
    final $$TimTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timId,
      referencedTable: $db.timTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimTableTableFilterComposer(
            $db: $db,
            $table: $db.timTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> faaliyetPersonelAtamaTableRefs(
    Expression<bool> Function($$FaaliyetPersonelAtamaTableTableFilterComposer f)
    f,
  ) {
    final $$FaaliyetPersonelAtamaTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.faaliyetPersonelAtamaTable,
          getReferencedColumn: (t) => t.personelId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FaaliyetPersonelAtamaTableTableFilterComposer(
                $db: $db,
                $table: $db.faaliyetPersonelAtamaTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> raporKayitTableRefs(
    Expression<bool> Function($$RaporKayitTableTableFilterComposer f) f,
  ) {
    final $$RaporKayitTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.raporKayitTable,
      getReferencedColumn: (t) => t.personelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RaporKayitTableTableFilterComposer(
            $db: $db,
            $table: $db.raporKayitTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PersonelTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonelTableTable> {
  $$PersonelTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adSoyad => $composableBuilder(
    column: $table.adSoyad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rutbe => $composableBuilder(
    column: $table.rutbe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birlik => $composableBuilder(
    column: $table.birlik,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kayitTarihi => $composableBuilder(
    column: $table.kayitTarihi,
    builder: (column) => ColumnOrderings(column),
  );

  $$TimTableTableOrderingComposer get timId {
    final $$TimTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timId,
      referencedTable: $db.timTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimTableTableOrderingComposer(
            $db: $db,
            $table: $db.timTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonelTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonelTableTable> {
  $$PersonelTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get adSoyad =>
      $composableBuilder(column: $table.adSoyad, builder: (column) => column);

  GeneratedColumn<String> get rutbe =>
      $composableBuilder(column: $table.rutbe, builder: (column) => column);

  GeneratedColumn<String> get birlik =>
      $composableBuilder(column: $table.birlik, builder: (column) => column);

  GeneratedColumn<String> get kayitTarihi => $composableBuilder(
    column: $table.kayitTarihi,
    builder: (column) => column,
  );

  $$TimTableTableAnnotationComposer get timId {
    final $$TimTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timId,
      referencedTable: $db.timTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimTableTableAnnotationComposer(
            $db: $db,
            $table: $db.timTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> faaliyetPersonelAtamaTableRefs<T extends Object>(
    Expression<T> Function(
      $$FaaliyetPersonelAtamaTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$FaaliyetPersonelAtamaTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.faaliyetPersonelAtamaTable,
          getReferencedColumn: (t) => t.personelId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FaaliyetPersonelAtamaTableTableAnnotationComposer(
                $db: $db,
                $table: $db.faaliyetPersonelAtamaTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> raporKayitTableRefs<T extends Object>(
    Expression<T> Function($$RaporKayitTableTableAnnotationComposer a) f,
  ) {
    final $$RaporKayitTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.raporKayitTable,
      getReferencedColumn: (t) => t.personelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RaporKayitTableTableAnnotationComposer(
            $db: $db,
            $table: $db.raporKayitTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PersonelTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonelTableTable,
          PersonelTableData,
          $$PersonelTableTableFilterComposer,
          $$PersonelTableTableOrderingComposer,
          $$PersonelTableTableAnnotationComposer,
          $$PersonelTableTableCreateCompanionBuilder,
          $$PersonelTableTableUpdateCompanionBuilder,
          (PersonelTableData, $$PersonelTableTableReferences),
          PersonelTableData,
          PrefetchHooks Function({
            bool timId,
            bool faaliyetPersonelAtamaTableRefs,
            bool raporKayitTableRefs,
          })
        > {
  $$PersonelTableTableTableManager(_$AppDatabase db, $PersonelTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonelTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonelTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonelTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> adSoyad = const Value.absent(),
                Value<String> rutbe = const Value.absent(),
                Value<String> birlik = const Value.absent(),
                Value<int?> timId = const Value.absent(),
                Value<String> kayitTarihi = const Value.absent(),
              }) => PersonelTableCompanion(
                id: id,
                adSoyad: adSoyad,
                rutbe: rutbe,
                birlik: birlik,
                timId: timId,
                kayitTarihi: kayitTarihi,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String adSoyad,
                required String rutbe,
                required String birlik,
                Value<int?> timId = const Value.absent(),
                required String kayitTarihi,
              }) => PersonelTableCompanion.insert(
                id: id,
                adSoyad: adSoyad,
                rutbe: rutbe,
                birlik: birlik,
                timId: timId,
                kayitTarihi: kayitTarihi,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonelTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                timId = false,
                faaliyetPersonelAtamaTableRefs = false,
                raporKayitTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (faaliyetPersonelAtamaTableRefs)
                      db.faaliyetPersonelAtamaTable,
                    if (raporKayitTableRefs) db.raporKayitTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (timId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.timId,
                                    referencedTable:
                                        $$PersonelTableTableReferences
                                            ._timIdTable(db),
                                    referencedColumn:
                                        $$PersonelTableTableReferences
                                            ._timIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (faaliyetPersonelAtamaTableRefs)
                        await $_getPrefetchedData<
                          PersonelTableData,
                          $PersonelTableTable,
                          FaaliyetPersonelAtamaTableData
                        >(
                          currentTable: table,
                          referencedTable: $$PersonelTableTableReferences
                              ._faaliyetPersonelAtamaTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonelTableTableReferences(
                                db,
                                table,
                                p0,
                              ).faaliyetPersonelAtamaTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personelId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (raporKayitTableRefs)
                        await $_getPrefetchedData<
                          PersonelTableData,
                          $PersonelTableTable,
                          RaporKayitTableData
                        >(
                          currentTable: table,
                          referencedTable: $$PersonelTableTableReferences
                              ._raporKayitTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonelTableTableReferences(
                                db,
                                table,
                                p0,
                              ).raporKayitTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personelId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PersonelTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonelTableTable,
      PersonelTableData,
      $$PersonelTableTableFilterComposer,
      $$PersonelTableTableOrderingComposer,
      $$PersonelTableTableAnnotationComposer,
      $$PersonelTableTableCreateCompanionBuilder,
      $$PersonelTableTableUpdateCompanionBuilder,
      (PersonelTableData, $$PersonelTableTableReferences),
      PersonelTableData,
      PrefetchHooks Function({
        bool timId,
        bool faaliyetPersonelAtamaTableRefs,
        bool raporKayitTableRefs,
      })
    >;
typedef $$GunlukFaaliyetTableTableCreateCompanionBuilder =
    GunlukFaaliyetTableCompanion Function({
      Value<int> id,
      required String faaliyetAdi,
      required String tarih,
      required String olusturanKullanici,
      required String olusturmaTarihi,
    });
typedef $$GunlukFaaliyetTableTableUpdateCompanionBuilder =
    GunlukFaaliyetTableCompanion Function({
      Value<int> id,
      Value<String> faaliyetAdi,
      Value<String> tarih,
      Value<String> olusturanKullanici,
      Value<String> olusturmaTarihi,
    });

final class $$GunlukFaaliyetTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $GunlukFaaliyetTableTable,
          GunlukFaaliyetTableData
        > {
  $$GunlukFaaliyetTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $FaaliyetPersonelAtamaTableTable,
    List<FaaliyetPersonelAtamaTableData>
  >
  _faaliyetPersonelAtamaTableRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.faaliyetPersonelAtamaTable,
    aliasName:
        'gunluk_faaliyet_table__id__faaliyet_personel_atama_table__faaliyet_id',
  );

  $$FaaliyetPersonelAtamaTableTableProcessedTableManager
  get faaliyetPersonelAtamaTableRefs {
    final manager = $$FaaliyetPersonelAtamaTableTableTableManager(
      $_db,
      $_db.faaliyetPersonelAtamaTable,
    ).filter((f) => f.faaliyetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _faaliyetPersonelAtamaTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GunlukFaaliyetTableTableFilterComposer
    extends Composer<_$AppDatabase, $GunlukFaaliyetTableTable> {
  $$GunlukFaaliyetTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get faaliyetAdi => $composableBuilder(
    column: $table.faaliyetAdi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tarih => $composableBuilder(
    column: $table.tarih,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get olusturanKullanici => $composableBuilder(
    column: $table.olusturanKullanici,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get olusturmaTarihi => $composableBuilder(
    column: $table.olusturmaTarihi,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> faaliyetPersonelAtamaTableRefs(
    Expression<bool> Function($$FaaliyetPersonelAtamaTableTableFilterComposer f)
    f,
  ) {
    final $$FaaliyetPersonelAtamaTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.faaliyetPersonelAtamaTable,
          getReferencedColumn: (t) => t.faaliyetId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FaaliyetPersonelAtamaTableTableFilterComposer(
                $db: $db,
                $table: $db.faaliyetPersonelAtamaTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GunlukFaaliyetTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GunlukFaaliyetTableTable> {
  $$GunlukFaaliyetTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get faaliyetAdi => $composableBuilder(
    column: $table.faaliyetAdi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tarih => $composableBuilder(
    column: $table.tarih,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get olusturanKullanici => $composableBuilder(
    column: $table.olusturanKullanici,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get olusturmaTarihi => $composableBuilder(
    column: $table.olusturmaTarihi,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GunlukFaaliyetTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GunlukFaaliyetTableTable> {
  $$GunlukFaaliyetTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get faaliyetAdi => $composableBuilder(
    column: $table.faaliyetAdi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tarih =>
      $composableBuilder(column: $table.tarih, builder: (column) => column);

  GeneratedColumn<String> get olusturanKullanici => $composableBuilder(
    column: $table.olusturanKullanici,
    builder: (column) => column,
  );

  GeneratedColumn<String> get olusturmaTarihi => $composableBuilder(
    column: $table.olusturmaTarihi,
    builder: (column) => column,
  );

  Expression<T> faaliyetPersonelAtamaTableRefs<T extends Object>(
    Expression<T> Function(
      $$FaaliyetPersonelAtamaTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$FaaliyetPersonelAtamaTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.faaliyetPersonelAtamaTable,
          getReferencedColumn: (t) => t.faaliyetId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FaaliyetPersonelAtamaTableTableAnnotationComposer(
                $db: $db,
                $table: $db.faaliyetPersonelAtamaTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GunlukFaaliyetTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GunlukFaaliyetTableTable,
          GunlukFaaliyetTableData,
          $$GunlukFaaliyetTableTableFilterComposer,
          $$GunlukFaaliyetTableTableOrderingComposer,
          $$GunlukFaaliyetTableTableAnnotationComposer,
          $$GunlukFaaliyetTableTableCreateCompanionBuilder,
          $$GunlukFaaliyetTableTableUpdateCompanionBuilder,
          (GunlukFaaliyetTableData, $$GunlukFaaliyetTableTableReferences),
          GunlukFaaliyetTableData,
          PrefetchHooks Function({bool faaliyetPersonelAtamaTableRefs})
        > {
  $$GunlukFaaliyetTableTableTableManager(
    _$AppDatabase db,
    $GunlukFaaliyetTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GunlukFaaliyetTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GunlukFaaliyetTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$GunlukFaaliyetTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> faaliyetAdi = const Value.absent(),
                Value<String> tarih = const Value.absent(),
                Value<String> olusturanKullanici = const Value.absent(),
                Value<String> olusturmaTarihi = const Value.absent(),
              }) => GunlukFaaliyetTableCompanion(
                id: id,
                faaliyetAdi: faaliyetAdi,
                tarih: tarih,
                olusturanKullanici: olusturanKullanici,
                olusturmaTarihi: olusturmaTarihi,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String faaliyetAdi,
                required String tarih,
                required String olusturanKullanici,
                required String olusturmaTarihi,
              }) => GunlukFaaliyetTableCompanion.insert(
                id: id,
                faaliyetAdi: faaliyetAdi,
                tarih: tarih,
                olusturanKullanici: olusturanKullanici,
                olusturmaTarihi: olusturmaTarihi,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GunlukFaaliyetTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({faaliyetPersonelAtamaTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (faaliyetPersonelAtamaTableRefs)
                  db.faaliyetPersonelAtamaTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (faaliyetPersonelAtamaTableRefs)
                    await $_getPrefetchedData<
                      GunlukFaaliyetTableData,
                      $GunlukFaaliyetTableTable,
                      FaaliyetPersonelAtamaTableData
                    >(
                      currentTable: table,
                      referencedTable: $$GunlukFaaliyetTableTableReferences
                          ._faaliyetPersonelAtamaTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$GunlukFaaliyetTableTableReferences(
                            db,
                            table,
                            p0,
                          ).faaliyetPersonelAtamaTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.faaliyetId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$GunlukFaaliyetTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GunlukFaaliyetTableTable,
      GunlukFaaliyetTableData,
      $$GunlukFaaliyetTableTableFilterComposer,
      $$GunlukFaaliyetTableTableOrderingComposer,
      $$GunlukFaaliyetTableTableAnnotationComposer,
      $$GunlukFaaliyetTableTableCreateCompanionBuilder,
      $$GunlukFaaliyetTableTableUpdateCompanionBuilder,
      (GunlukFaaliyetTableData, $$GunlukFaaliyetTableTableReferences),
      GunlukFaaliyetTableData,
      PrefetchHooks Function({bool faaliyetPersonelAtamaTableRefs})
    >;
typedef $$FaaliyetPersonelAtamaTableTableCreateCompanionBuilder =
    FaaliyetPersonelAtamaTableCompanion Function({
      Value<int> id,
      required int faaliyetId,
      required int personelId,
      required String gorevVeyaIzin,
      required String durum,
      Value<String?> aciklama,
    });
typedef $$FaaliyetPersonelAtamaTableTableUpdateCompanionBuilder =
    FaaliyetPersonelAtamaTableCompanion Function({
      Value<int> id,
      Value<int> faaliyetId,
      Value<int> personelId,
      Value<String> gorevVeyaIzin,
      Value<String> durum,
      Value<String?> aciklama,
    });

final class $$FaaliyetPersonelAtamaTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FaaliyetPersonelAtamaTableTable,
          FaaliyetPersonelAtamaTableData
        > {
  $$FaaliyetPersonelAtamaTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GunlukFaaliyetTableTable _faaliyetIdTable(_$AppDatabase db) =>
      db.gunlukFaaliyetTable.createAlias(
        'faaliyet_personel_atama_table__faaliyet_id__gunluk_faaliyet_table__id',
      );

  $$GunlukFaaliyetTableTableProcessedTableManager get faaliyetId {
    final $_column = $_itemColumn<int>('faaliyet_id')!;

    final manager = $$GunlukFaaliyetTableTableTableManager(
      $_db,
      $_db.gunlukFaaliyetTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_faaliyetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PersonelTableTable _personelIdTable(_$AppDatabase db) =>
      db.personelTable.createAlias(
        'faaliyet_personel_atama_table__personel_id__personel_table__id',
      );

  $$PersonelTableTableProcessedTableManager get personelId {
    final $_column = $_itemColumn<int>('personel_id')!;

    final manager = $$PersonelTableTableTableManager(
      $_db,
      $_db.personelTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FaaliyetPersonelAtamaTableTableFilterComposer
    extends Composer<_$AppDatabase, $FaaliyetPersonelAtamaTableTable> {
  $$FaaliyetPersonelAtamaTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gorevVeyaIzin => $composableBuilder(
    column: $table.gorevVeyaIzin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get durum => $composableBuilder(
    column: $table.durum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aciklama => $composableBuilder(
    column: $table.aciklama,
    builder: (column) => ColumnFilters(column),
  );

  $$GunlukFaaliyetTableTableFilterComposer get faaliyetId {
    final $$GunlukFaaliyetTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.faaliyetId,
      referencedTable: $db.gunlukFaaliyetTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GunlukFaaliyetTableTableFilterComposer(
            $db: $db,
            $table: $db.gunlukFaaliyetTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonelTableTableFilterComposer get personelId {
    final $$PersonelTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personelId,
      referencedTable: $db.personelTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonelTableTableFilterComposer(
            $db: $db,
            $table: $db.personelTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FaaliyetPersonelAtamaTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FaaliyetPersonelAtamaTableTable> {
  $$FaaliyetPersonelAtamaTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gorevVeyaIzin => $composableBuilder(
    column: $table.gorevVeyaIzin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get durum => $composableBuilder(
    column: $table.durum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aciklama => $composableBuilder(
    column: $table.aciklama,
    builder: (column) => ColumnOrderings(column),
  );

  $$GunlukFaaliyetTableTableOrderingComposer get faaliyetId {
    final $$GunlukFaaliyetTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.faaliyetId,
          referencedTable: $db.gunlukFaaliyetTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GunlukFaaliyetTableTableOrderingComposer(
                $db: $db,
                $table: $db.gunlukFaaliyetTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$PersonelTableTableOrderingComposer get personelId {
    final $$PersonelTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personelId,
      referencedTable: $db.personelTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonelTableTableOrderingComposer(
            $db: $db,
            $table: $db.personelTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FaaliyetPersonelAtamaTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FaaliyetPersonelAtamaTableTable> {
  $$FaaliyetPersonelAtamaTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gorevVeyaIzin => $composableBuilder(
    column: $table.gorevVeyaIzin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get durum =>
      $composableBuilder(column: $table.durum, builder: (column) => column);

  GeneratedColumn<String> get aciklama =>
      $composableBuilder(column: $table.aciklama, builder: (column) => column);

  $$GunlukFaaliyetTableTableAnnotationComposer get faaliyetId {
    final $$GunlukFaaliyetTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.faaliyetId,
          referencedTable: $db.gunlukFaaliyetTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GunlukFaaliyetTableTableAnnotationComposer(
                $db: $db,
                $table: $db.gunlukFaaliyetTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$PersonelTableTableAnnotationComposer get personelId {
    final $$PersonelTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personelId,
      referencedTable: $db.personelTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonelTableTableAnnotationComposer(
            $db: $db,
            $table: $db.personelTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FaaliyetPersonelAtamaTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FaaliyetPersonelAtamaTableTable,
          FaaliyetPersonelAtamaTableData,
          $$FaaliyetPersonelAtamaTableTableFilterComposer,
          $$FaaliyetPersonelAtamaTableTableOrderingComposer,
          $$FaaliyetPersonelAtamaTableTableAnnotationComposer,
          $$FaaliyetPersonelAtamaTableTableCreateCompanionBuilder,
          $$FaaliyetPersonelAtamaTableTableUpdateCompanionBuilder,
          (
            FaaliyetPersonelAtamaTableData,
            $$FaaliyetPersonelAtamaTableTableReferences,
          ),
          FaaliyetPersonelAtamaTableData,
          PrefetchHooks Function({bool faaliyetId, bool personelId})
        > {
  $$FaaliyetPersonelAtamaTableTableTableManager(
    _$AppDatabase db,
    $FaaliyetPersonelAtamaTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FaaliyetPersonelAtamaTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FaaliyetPersonelAtamaTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FaaliyetPersonelAtamaTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> faaliyetId = const Value.absent(),
                Value<int> personelId = const Value.absent(),
                Value<String> gorevVeyaIzin = const Value.absent(),
                Value<String> durum = const Value.absent(),
                Value<String?> aciklama = const Value.absent(),
              }) => FaaliyetPersonelAtamaTableCompanion(
                id: id,
                faaliyetId: faaliyetId,
                personelId: personelId,
                gorevVeyaIzin: gorevVeyaIzin,
                durum: durum,
                aciklama: aciklama,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int faaliyetId,
                required int personelId,
                required String gorevVeyaIzin,
                required String durum,
                Value<String?> aciklama = const Value.absent(),
              }) => FaaliyetPersonelAtamaTableCompanion.insert(
                id: id,
                faaliyetId: faaliyetId,
                personelId: personelId,
                gorevVeyaIzin: gorevVeyaIzin,
                durum: durum,
                aciklama: aciklama,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FaaliyetPersonelAtamaTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({faaliyetId = false, personelId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (faaliyetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.faaliyetId,
                                referencedTable:
                                    $$FaaliyetPersonelAtamaTableTableReferences
                                        ._faaliyetIdTable(db),
                                referencedColumn:
                                    $$FaaliyetPersonelAtamaTableTableReferences
                                        ._faaliyetIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (personelId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personelId,
                                referencedTable:
                                    $$FaaliyetPersonelAtamaTableTableReferences
                                        ._personelIdTable(db),
                                referencedColumn:
                                    $$FaaliyetPersonelAtamaTableTableReferences
                                        ._personelIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FaaliyetPersonelAtamaTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FaaliyetPersonelAtamaTableTable,
      FaaliyetPersonelAtamaTableData,
      $$FaaliyetPersonelAtamaTableTableFilterComposer,
      $$FaaliyetPersonelAtamaTableTableOrderingComposer,
      $$FaaliyetPersonelAtamaTableTableAnnotationComposer,
      $$FaaliyetPersonelAtamaTableTableCreateCompanionBuilder,
      $$FaaliyetPersonelAtamaTableTableUpdateCompanionBuilder,
      (
        FaaliyetPersonelAtamaTableData,
        $$FaaliyetPersonelAtamaTableTableReferences,
      ),
      FaaliyetPersonelAtamaTableData,
      PrefetchHooks Function({bool faaliyetId, bool personelId})
    >;
typedef $$RaporKayitTableTableCreateCompanionBuilder =
    RaporKayitTableCompanion Function({
      Value<int> id,
      required int personelId,
      required String raporBaslangic,
      required String raporBitis,
      Value<String?> aciklama,
    });
typedef $$RaporKayitTableTableUpdateCompanionBuilder =
    RaporKayitTableCompanion Function({
      Value<int> id,
      Value<int> personelId,
      Value<String> raporBaslangic,
      Value<String> raporBitis,
      Value<String?> aciklama,
    });

final class $$RaporKayitTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RaporKayitTableTable,
          RaporKayitTableData
        > {
  $$RaporKayitTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PersonelTableTable _personelIdTable(_$AppDatabase db) => db
      .personelTable
      .createAlias('rapor_kayit_table__personel_id__personel_table__id');

  $$PersonelTableTableProcessedTableManager get personelId {
    final $_column = $_itemColumn<int>('personel_id')!;

    final manager = $$PersonelTableTableTableManager(
      $_db,
      $_db.personelTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RaporKayitTableTableFilterComposer
    extends Composer<_$AppDatabase, $RaporKayitTableTable> {
  $$RaporKayitTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get raporBaslangic => $composableBuilder(
    column: $table.raporBaslangic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get raporBitis => $composableBuilder(
    column: $table.raporBitis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aciklama => $composableBuilder(
    column: $table.aciklama,
    builder: (column) => ColumnFilters(column),
  );

  $$PersonelTableTableFilterComposer get personelId {
    final $$PersonelTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personelId,
      referencedTable: $db.personelTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonelTableTableFilterComposer(
            $db: $db,
            $table: $db.personelTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RaporKayitTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RaporKayitTableTable> {
  $$RaporKayitTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get raporBaslangic => $composableBuilder(
    column: $table.raporBaslangic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get raporBitis => $composableBuilder(
    column: $table.raporBitis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aciklama => $composableBuilder(
    column: $table.aciklama,
    builder: (column) => ColumnOrderings(column),
  );

  $$PersonelTableTableOrderingComposer get personelId {
    final $$PersonelTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personelId,
      referencedTable: $db.personelTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonelTableTableOrderingComposer(
            $db: $db,
            $table: $db.personelTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RaporKayitTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RaporKayitTableTable> {
  $$RaporKayitTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get raporBaslangic => $composableBuilder(
    column: $table.raporBaslangic,
    builder: (column) => column,
  );

  GeneratedColumn<String> get raporBitis => $composableBuilder(
    column: $table.raporBitis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aciklama =>
      $composableBuilder(column: $table.aciklama, builder: (column) => column);

  $$PersonelTableTableAnnotationComposer get personelId {
    final $$PersonelTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personelId,
      referencedTable: $db.personelTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonelTableTableAnnotationComposer(
            $db: $db,
            $table: $db.personelTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RaporKayitTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RaporKayitTableTable,
          RaporKayitTableData,
          $$RaporKayitTableTableFilterComposer,
          $$RaporKayitTableTableOrderingComposer,
          $$RaporKayitTableTableAnnotationComposer,
          $$RaporKayitTableTableCreateCompanionBuilder,
          $$RaporKayitTableTableUpdateCompanionBuilder,
          (RaporKayitTableData, $$RaporKayitTableTableReferences),
          RaporKayitTableData,
          PrefetchHooks Function({bool personelId})
        > {
  $$RaporKayitTableTableTableManager(
    _$AppDatabase db,
    $RaporKayitTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RaporKayitTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RaporKayitTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RaporKayitTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> personelId = const Value.absent(),
                Value<String> raporBaslangic = const Value.absent(),
                Value<String> raporBitis = const Value.absent(),
                Value<String?> aciklama = const Value.absent(),
              }) => RaporKayitTableCompanion(
                id: id,
                personelId: personelId,
                raporBaslangic: raporBaslangic,
                raporBitis: raporBitis,
                aciklama: aciklama,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int personelId,
                required String raporBaslangic,
                required String raporBitis,
                Value<String?> aciklama = const Value.absent(),
              }) => RaporKayitTableCompanion.insert(
                id: id,
                personelId: personelId,
                raporBaslangic: raporBaslangic,
                raporBitis: raporBitis,
                aciklama: aciklama,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RaporKayitTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personelId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personelId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personelId,
                                referencedTable:
                                    $$RaporKayitTableTableReferences
                                        ._personelIdTable(db),
                                referencedColumn:
                                    $$RaporKayitTableTableReferences
                                        ._personelIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RaporKayitTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RaporKayitTableTable,
      RaporKayitTableData,
      $$RaporKayitTableTableFilterComposer,
      $$RaporKayitTableTableOrderingComposer,
      $$RaporKayitTableTableAnnotationComposer,
      $$RaporKayitTableTableCreateCompanionBuilder,
      $$RaporKayitTableTableUpdateCompanionBuilder,
      (RaporKayitTableData, $$RaporKayitTableTableReferences),
      RaporKayitTableData,
      PrefetchHooks Function({bool personelId})
    >;
typedef $$TimUyelikGecmisiTableTableCreateCompanionBuilder =
    TimUyelikGecmisiTableCompanion Function({
      Value<int> id,
      required int personelId,
      Value<int?> timId,
      required String tarih,
      required String islem,
    });
typedef $$TimUyelikGecmisiTableTableUpdateCompanionBuilder =
    TimUyelikGecmisiTableCompanion Function({
      Value<int> id,
      Value<int> personelId,
      Value<int?> timId,
      Value<String> tarih,
      Value<String> islem,
    });

final class $$TimUyelikGecmisiTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TimUyelikGecmisiTableTable,
          TimUyelikGecmisiTableData
        > {
  $$TimUyelikGecmisiTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TimTableTable _timIdTable(_$AppDatabase db) => db.timTable
      .createAlias('tim_uyelik_gecmisi_table__tim_id__tim_table__id');

  $$TimTableTableProcessedTableManager? get timId {
    final $_column = $_itemColumn<int>('tim_id');
    if ($_column == null) return null;
    final manager = $$TimTableTableTableManager(
      $_db,
      $_db.timTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_timIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TimUyelikGecmisiTableTableFilterComposer
    extends Composer<_$AppDatabase, $TimUyelikGecmisiTableTable> {
  $$TimUyelikGecmisiTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get personelId => $composableBuilder(
    column: $table.personelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tarih => $composableBuilder(
    column: $table.tarih,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get islem => $composableBuilder(
    column: $table.islem,
    builder: (column) => ColumnFilters(column),
  );

  $$TimTableTableFilterComposer get timId {
    final $$TimTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timId,
      referencedTable: $db.timTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimTableTableFilterComposer(
            $db: $db,
            $table: $db.timTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimUyelikGecmisiTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TimUyelikGecmisiTableTable> {
  $$TimUyelikGecmisiTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get personelId => $composableBuilder(
    column: $table.personelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tarih => $composableBuilder(
    column: $table.tarih,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get islem => $composableBuilder(
    column: $table.islem,
    builder: (column) => ColumnOrderings(column),
  );

  $$TimTableTableOrderingComposer get timId {
    final $$TimTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timId,
      referencedTable: $db.timTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimTableTableOrderingComposer(
            $db: $db,
            $table: $db.timTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimUyelikGecmisiTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimUyelikGecmisiTableTable> {
  $$TimUyelikGecmisiTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get personelId => $composableBuilder(
    column: $table.personelId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tarih =>
      $composableBuilder(column: $table.tarih, builder: (column) => column);

  GeneratedColumn<String> get islem =>
      $composableBuilder(column: $table.islem, builder: (column) => column);

  $$TimTableTableAnnotationComposer get timId {
    final $$TimTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timId,
      referencedTable: $db.timTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimTableTableAnnotationComposer(
            $db: $db,
            $table: $db.timTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimUyelikGecmisiTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimUyelikGecmisiTableTable,
          TimUyelikGecmisiTableData,
          $$TimUyelikGecmisiTableTableFilterComposer,
          $$TimUyelikGecmisiTableTableOrderingComposer,
          $$TimUyelikGecmisiTableTableAnnotationComposer,
          $$TimUyelikGecmisiTableTableCreateCompanionBuilder,
          $$TimUyelikGecmisiTableTableUpdateCompanionBuilder,
          (TimUyelikGecmisiTableData, $$TimUyelikGecmisiTableTableReferences),
          TimUyelikGecmisiTableData,
          PrefetchHooks Function({bool timId})
        > {
  $$TimUyelikGecmisiTableTableTableManager(
    _$AppDatabase db,
    $TimUyelikGecmisiTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimUyelikGecmisiTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TimUyelikGecmisiTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TimUyelikGecmisiTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> personelId = const Value.absent(),
                Value<int?> timId = const Value.absent(),
                Value<String> tarih = const Value.absent(),
                Value<String> islem = const Value.absent(),
              }) => TimUyelikGecmisiTableCompanion(
                id: id,
                personelId: personelId,
                timId: timId,
                tarih: tarih,
                islem: islem,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int personelId,
                Value<int?> timId = const Value.absent(),
                required String tarih,
                required String islem,
              }) => TimUyelikGecmisiTableCompanion.insert(
                id: id,
                personelId: personelId,
                timId: timId,
                tarih: tarih,
                islem: islem,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TimUyelikGecmisiTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({timId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (timId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.timId,
                                referencedTable:
                                    $$TimUyelikGecmisiTableTableReferences
                                        ._timIdTable(db),
                                referencedColumn:
                                    $$TimUyelikGecmisiTableTableReferences
                                        ._timIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TimUyelikGecmisiTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimUyelikGecmisiTableTable,
      TimUyelikGecmisiTableData,
      $$TimUyelikGecmisiTableTableFilterComposer,
      $$TimUyelikGecmisiTableTableOrderingComposer,
      $$TimUyelikGecmisiTableTableAnnotationComposer,
      $$TimUyelikGecmisiTableTableCreateCompanionBuilder,
      $$TimUyelikGecmisiTableTableUpdateCompanionBuilder,
      (TimUyelikGecmisiTableData, $$TimUyelikGecmisiTableTableReferences),
      TimUyelikGecmisiTableData,
      PrefetchHooks Function({bool timId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TimTableTableTableManager get timTable =>
      $$TimTableTableTableManager(_db, _db.timTable);
  $$KullaniciTableTableTableManager get kullaniciTable =>
      $$KullaniciTableTableTableManager(_db, _db.kullaniciTable);
  $$PersonelTableTableTableManager get personelTable =>
      $$PersonelTableTableTableManager(_db, _db.personelTable);
  $$GunlukFaaliyetTableTableTableManager get gunlukFaaliyetTable =>
      $$GunlukFaaliyetTableTableTableManager(_db, _db.gunlukFaaliyetTable);
  $$FaaliyetPersonelAtamaTableTableTableManager
  get faaliyetPersonelAtamaTable =>
      $$FaaliyetPersonelAtamaTableTableTableManager(
        _db,
        _db.faaliyetPersonelAtamaTable,
      );
  $$RaporKayitTableTableTableManager get raporKayitTable =>
      $$RaporKayitTableTableTableManager(_db, _db.raporKayitTable);
  $$TimUyelikGecmisiTableTableTableManager get timUyelikGecmisiTable =>
      $$TimUyelikGecmisiTableTableTableManager(_db, _db.timUyelikGecmisiTable);
}
