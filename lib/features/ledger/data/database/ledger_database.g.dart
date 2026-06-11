// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_database.dart';

// ignore_for_file: type=lint
class $ProfileRecordsTable extends ProfileRecords
    with TableInfo<$ProfileRecordsTable, ProfileRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailVerifiedMeta = const VerificationMeta(
    'emailVerified',
  );
  @override
  late final GeneratedColumn<bool> emailVerified = GeneratedColumn<bool>(
    'email_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("email_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingSyncMeta = const VerificationMeta(
    'pendingSync',
  );
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
    'pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    email,
    phone,
    emailVerified,
    updatedAt,
    pendingSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('email_verified')) {
      context.handle(
        _emailVerifiedMeta,
        emailVerified.isAcceptableOrUnknown(
          data['email_verified']!,
          _emailVerifiedMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
        _pendingSyncMeta,
        pendingSync.isAcceptableOrUnknown(
          data['pending_sync']!,
          _pendingSyncMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      emailVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}email_verified'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_sync'],
      )!,
    );
  }

  @override
  $ProfileRecordsTable createAlias(String alias) {
    return $ProfileRecordsTable(attachedDatabase, alias);
  }
}

class ProfileRecord extends DataClass implements Insertable<ProfileRecord> {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool emailVerified;
  final DateTime updatedAt;
  final bool pendingSync;
  const ProfileRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.emailVerified,
    required this.updatedAt,
    required this.pendingSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    map['phone'] = Variable<String>(phone);
    map['email_verified'] = Variable<bool>(emailVerified);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  ProfileRecordsCompanion toCompanion(bool nullToAbsent) {
    return ProfileRecordsCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      phone: Value(phone),
      emailVerified: Value(emailVerified),
      updatedAt: Value(updatedAt),
      pendingSync: Value(pendingSync),
    );
  }

  factory ProfileRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      phone: serializer.fromJson<String>(json['phone']),
      emailVerified: serializer.fromJson<bool>(json['emailVerified']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'phone': serializer.toJson<String>(phone),
      'emailVerified': serializer.toJson<bool>(emailVerified),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  ProfileRecord copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    bool? emailVerified,
    DateTime? updatedAt,
    bool? pendingSync,
  }) => ProfileRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    emailVerified: emailVerified ?? this.emailVerified,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingSync: pendingSync ?? this.pendingSync,
  );
  ProfileRecord copyWithCompanion(ProfileRecordsCompanion data) {
    return ProfileRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      emailVerified: data.emailVerified.present
          ? data.emailVerified.value
          : this.emailVerified,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingSync: data.pendingSync.present
          ? data.pendingSync.value
          : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('emailVerified: $emailVerified, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    email,
    phone,
    emailVerified,
    updatedAt,
    pendingSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.emailVerified == this.emailVerified &&
          other.updatedAt == this.updatedAt &&
          other.pendingSync == this.pendingSync);
}

class ProfileRecordsCompanion extends UpdateCompanion<ProfileRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> email;
  final Value<String> phone;
  final Value<bool> emailVerified;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingSync;
  final Value<int> rowid;
  const ProfileRecordsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.emailVerified = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileRecordsCompanion.insert({
    required String id,
    required String name,
    required String email,
    required String phone,
    this.emailVerified = const Value.absent(),
    required DateTime updatedAt,
    this.pendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       email = Value(email),
       phone = Value(phone),
       updatedAt = Value(updatedAt);
  static Insertable<ProfileRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<bool>? emailVerified,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (emailVerified != null) 'email_verified': emailVerified,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? email,
    Value<String>? phone,
    Value<bool>? emailVerified,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingSync,
    Value<int>? rowid,
  }) {
    return ProfileRecordsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emailVerified: emailVerified ?? this.emailVerified,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (emailVerified.present) {
      map['email_verified'] = Variable<bool>(emailVerified.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRecordsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('emailVerified: $emailVerified, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ServiceRecordsTable extends ServiceRecords
    with TableInfo<$ServiceRecordsTable, ServiceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServiceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthKeyMeta = const VerificationMeta(
    'monthKey',
  );
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
    'month_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateTypeMeta = const VerificationMeta(
    'templateType',
  );
  @override
  late final GeneratedColumn<String> templateType = GeneratedColumn<String>(
    'template_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultQuantityMeta = const VerificationMeta(
    'defaultQuantity',
  );
  @override
  late final GeneratedColumn<double> defaultQuantity = GeneratedColumn<double>(
    'default_quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _rateCentsMeta = const VerificationMeta(
    'rateCents',
  );
  @override
  late final GeneratedColumn<int> rateCents = GeneratedColumn<int>(
    'rate_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthlyAmountCentsMeta =
      const VerificationMeta('monthlyAmountCents');
  @override
  late final GeneratedColumn<int> monthlyAmountCents = GeneratedColumn<int>(
    'monthly_amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingSyncMeta = const VerificationMeta(
    'pendingSync',
  );
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
    'pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    monthKey,
    name,
    description,
    icon,
    templateType,
    unit,
    defaultQuantity,
    rateCents,
    monthlyAmountCents,
    updatedAt,
    pendingSync,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'service_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServiceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(
        _monthKeyMeta,
        monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('template_type')) {
      context.handle(
        _templateTypeMeta,
        templateType.isAcceptableOrUnknown(
          data['template_type']!,
          _templateTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateTypeMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('default_quantity')) {
      context.handle(
        _defaultQuantityMeta,
        defaultQuantity.isAcceptableOrUnknown(
          data['default_quantity']!,
          _defaultQuantityMeta,
        ),
      );
    }
    if (data.containsKey('rate_cents')) {
      context.handle(
        _rateCentsMeta,
        rateCents.isAcceptableOrUnknown(data['rate_cents']!, _rateCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_rateCentsMeta);
    }
    if (data.containsKey('monthly_amount_cents')) {
      context.handle(
        _monthlyAmountCentsMeta,
        monthlyAmountCents.isAcceptableOrUnknown(
          data['monthly_amount_cents']!,
          _monthlyAmountCentsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
        _pendingSyncMeta,
        pendingSync.isAcceptableOrUnknown(
          data['pending_sync']!,
          _pendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServiceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServiceRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      monthKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      templateType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_type'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      defaultQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}default_quantity'],
      )!,
      rateCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_cents'],
      )!,
      monthlyAmountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monthly_amount_cents'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_sync'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $ServiceRecordsTable createAlias(String alias) {
    return $ServiceRecordsTable(attachedDatabase, alias);
  }
}

class ServiceRecord extends DataClass implements Insertable<ServiceRecord> {
  final String id;
  final String userId;
  final String monthKey;
  final String name;
  final String description;
  final String icon;
  final String templateType;
  final String unit;
  final double defaultQuantity;
  final int rateCents;
  final int monthlyAmountCents;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool isDeleted;
  const ServiceRecord({
    required this.id,
    required this.userId,
    required this.monthKey,
    required this.name,
    required this.description,
    required this.icon,
    required this.templateType,
    required this.unit,
    required this.defaultQuantity,
    required this.rateCents,
    required this.monthlyAmountCents,
    required this.updatedAt,
    required this.pendingSync,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['month_key'] = Variable<String>(monthKey);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['icon'] = Variable<String>(icon);
    map['template_type'] = Variable<String>(templateType);
    map['unit'] = Variable<String>(unit);
    map['default_quantity'] = Variable<double>(defaultQuantity);
    map['rate_cents'] = Variable<int>(rateCents);
    map['monthly_amount_cents'] = Variable<int>(monthlyAmountCents);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_sync'] = Variable<bool>(pendingSync);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ServiceRecordsCompanion toCompanion(bool nullToAbsent) {
    return ServiceRecordsCompanion(
      id: Value(id),
      userId: Value(userId),
      monthKey: Value(monthKey),
      name: Value(name),
      description: Value(description),
      icon: Value(icon),
      templateType: Value(templateType),
      unit: Value(unit),
      defaultQuantity: Value(defaultQuantity),
      rateCents: Value(rateCents),
      monthlyAmountCents: Value(monthlyAmountCents),
      updatedAt: Value(updatedAt),
      pendingSync: Value(pendingSync),
      isDeleted: Value(isDeleted),
    );
  }

  factory ServiceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServiceRecord(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      monthKey: serializer.fromJson<String>(json['monthKey']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      icon: serializer.fromJson<String>(json['icon']),
      templateType: serializer.fromJson<String>(json['templateType']),
      unit: serializer.fromJson<String>(json['unit']),
      defaultQuantity: serializer.fromJson<double>(json['defaultQuantity']),
      rateCents: serializer.fromJson<int>(json['rateCents']),
      monthlyAmountCents: serializer.fromJson<int>(json['monthlyAmountCents']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'monthKey': serializer.toJson<String>(monthKey),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'icon': serializer.toJson<String>(icon),
      'templateType': serializer.toJson<String>(templateType),
      'unit': serializer.toJson<String>(unit),
      'defaultQuantity': serializer.toJson<double>(defaultQuantity),
      'rateCents': serializer.toJson<int>(rateCents),
      'monthlyAmountCents': serializer.toJson<int>(monthlyAmountCents),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  ServiceRecord copyWith({
    String? id,
    String? userId,
    String? monthKey,
    String? name,
    String? description,
    String? icon,
    String? templateType,
    String? unit,
    double? defaultQuantity,
    int? rateCents,
    int? monthlyAmountCents,
    DateTime? updatedAt,
    bool? pendingSync,
    bool? isDeleted,
  }) => ServiceRecord(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    monthKey: monthKey ?? this.monthKey,
    name: name ?? this.name,
    description: description ?? this.description,
    icon: icon ?? this.icon,
    templateType: templateType ?? this.templateType,
    unit: unit ?? this.unit,
    defaultQuantity: defaultQuantity ?? this.defaultQuantity,
    rateCents: rateCents ?? this.rateCents,
    monthlyAmountCents: monthlyAmountCents ?? this.monthlyAmountCents,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingSync: pendingSync ?? this.pendingSync,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  ServiceRecord copyWithCompanion(ServiceRecordsCompanion data) {
    return ServiceRecord(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      icon: data.icon.present ? data.icon.value : this.icon,
      templateType: data.templateType.present
          ? data.templateType.value
          : this.templateType,
      unit: data.unit.present ? data.unit.value : this.unit,
      defaultQuantity: data.defaultQuantity.present
          ? data.defaultQuantity.value
          : this.defaultQuantity,
      rateCents: data.rateCents.present ? data.rateCents.value : this.rateCents,
      monthlyAmountCents: data.monthlyAmountCents.present
          ? data.monthlyAmountCents.value
          : this.monthlyAmountCents,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingSync: data.pendingSync.present
          ? data.pendingSync.value
          : this.pendingSync,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServiceRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('monthKey: $monthKey, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('templateType: $templateType, ')
          ..write('unit: $unit, ')
          ..write('defaultQuantity: $defaultQuantity, ')
          ..write('rateCents: $rateCents, ')
          ..write('monthlyAmountCents: $monthlyAmountCents, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    monthKey,
    name,
    description,
    icon,
    templateType,
    unit,
    defaultQuantity,
    rateCents,
    monthlyAmountCents,
    updatedAt,
    pendingSync,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServiceRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.monthKey == this.monthKey &&
          other.name == this.name &&
          other.description == this.description &&
          other.icon == this.icon &&
          other.templateType == this.templateType &&
          other.unit == this.unit &&
          other.defaultQuantity == this.defaultQuantity &&
          other.rateCents == this.rateCents &&
          other.monthlyAmountCents == this.monthlyAmountCents &&
          other.updatedAt == this.updatedAt &&
          other.pendingSync == this.pendingSync &&
          other.isDeleted == this.isDeleted);
}

class ServiceRecordsCompanion extends UpdateCompanion<ServiceRecord> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> monthKey;
  final Value<String> name;
  final Value<String> description;
  final Value<String> icon;
  final Value<String> templateType;
  final Value<String> unit;
  final Value<double> defaultQuantity;
  final Value<int> rateCents;
  final Value<int> monthlyAmountCents;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingSync;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const ServiceRecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.templateType = const Value.absent(),
    this.unit = const Value.absent(),
    this.defaultQuantity = const Value.absent(),
    this.rateCents = const Value.absent(),
    this.monthlyAmountCents = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServiceRecordsCompanion.insert({
    required String id,
    required String userId,
    required String monthKey,
    required String name,
    required String description,
    required String icon,
    required String templateType,
    required String unit,
    this.defaultQuantity = const Value.absent(),
    required int rateCents,
    this.monthlyAmountCents = const Value.absent(),
    required DateTime updatedAt,
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       monthKey = Value(monthKey),
       name = Value(name),
       description = Value(description),
       icon = Value(icon),
       templateType = Value(templateType),
       unit = Value(unit),
       rateCents = Value(rateCents),
       updatedAt = Value(updatedAt);
  static Insertable<ServiceRecord> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? monthKey,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? icon,
    Expression<String>? templateType,
    Expression<String>? unit,
    Expression<double>? defaultQuantity,
    Expression<int>? rateCents,
    Expression<int>? monthlyAmountCents,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingSync,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (monthKey != null) 'month_key': monthKey,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (templateType != null) 'template_type': templateType,
      if (unit != null) 'unit': unit,
      if (defaultQuantity != null) 'default_quantity': defaultQuantity,
      if (rateCents != null) 'rate_cents': rateCents,
      if (monthlyAmountCents != null)
        'monthly_amount_cents': monthlyAmountCents,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServiceRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? monthKey,
    Value<String>? name,
    Value<String>? description,
    Value<String>? icon,
    Value<String>? templateType,
    Value<String>? unit,
    Value<double>? defaultQuantity,
    Value<int>? rateCents,
    Value<int>? monthlyAmountCents,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingSync,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return ServiceRecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      monthKey: monthKey ?? this.monthKey,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      templateType: templateType ?? this.templateType,
      unit: unit ?? this.unit,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
      rateCents: rateCents ?? this.rateCents,
      monthlyAmountCents: monthlyAmountCents ?? this.monthlyAmountCents,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (templateType.present) {
      map['template_type'] = Variable<String>(templateType.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (defaultQuantity.present) {
      map['default_quantity'] = Variable<double>(defaultQuantity.value);
    }
    if (rateCents.present) {
      map['rate_cents'] = Variable<int>(rateCents.value);
    }
    if (monthlyAmountCents.present) {
      map['monthly_amount_cents'] = Variable<int>(monthlyAmountCents.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServiceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('monthKey: $monthKey, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('templateType: $templateType, ')
          ..write('unit: $unit, ')
          ..write('defaultQuantity: $defaultQuantity, ')
          ..write('rateCents: $rateCents, ')
          ..write('monthlyAmountCents: $monthlyAmountCents, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntryRecordsTable extends EntryRecords
    with TableInfo<$EntryRecordsTable, EntryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
    'service_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthKeyMeta = const VerificationMeta(
    'monthKey',
  );
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
    'month_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _rateCentsMeta = const VerificationMeta(
    'rateCents',
  );
  @override
  late final GeneratedColumn<int> rateCents = GeneratedColumn<int>(
    'rate_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingSyncMeta = const VerificationMeta(
    'pendingSync',
  );
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
    'pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serviceId,
    monthKey,
    day,
    status,
    quantity,
    unit,
    rateCents,
    amountCents,
    note,
    updatedAt,
    pendingSync,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('service_id')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(
        _monthKeyMeta,
        monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('rate_cents')) {
      context.handle(
        _rateCentsMeta,
        rateCents.isAcceptableOrUnknown(data['rate_cents']!, _rateCentsMeta),
      );
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
        _pendingSyncMeta,
        pendingSync.isAcceptableOrUnknown(
          data['pending_sync']!,
          _pendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_id'],
      )!,
      monthKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_key'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      rateCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_cents'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_sync'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $EntryRecordsTable createAlias(String alias) {
    return $EntryRecordsTable(attachedDatabase, alias);
  }
}

class EntryRecord extends DataClass implements Insertable<EntryRecord> {
  final String id;
  final String serviceId;
  final String monthKey;
  final int day;
  final String status;
  final double quantity;
  final String unit;
  final int rateCents;
  final int amountCents;
  final String note;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool isDeleted;
  const EntryRecord({
    required this.id,
    required this.serviceId,
    required this.monthKey,
    required this.day,
    required this.status,
    required this.quantity,
    required this.unit,
    required this.rateCents,
    required this.amountCents,
    required this.note,
    required this.updatedAt,
    required this.pendingSync,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['service_id'] = Variable<String>(serviceId);
    map['month_key'] = Variable<String>(monthKey);
    map['day'] = Variable<int>(day);
    map['status'] = Variable<String>(status);
    map['quantity'] = Variable<double>(quantity);
    map['unit'] = Variable<String>(unit);
    map['rate_cents'] = Variable<int>(rateCents);
    map['amount_cents'] = Variable<int>(amountCents);
    map['note'] = Variable<String>(note);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_sync'] = Variable<bool>(pendingSync);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  EntryRecordsCompanion toCompanion(bool nullToAbsent) {
    return EntryRecordsCompanion(
      id: Value(id),
      serviceId: Value(serviceId),
      monthKey: Value(monthKey),
      day: Value(day),
      status: Value(status),
      quantity: Value(quantity),
      unit: Value(unit),
      rateCents: Value(rateCents),
      amountCents: Value(amountCents),
      note: Value(note),
      updatedAt: Value(updatedAt),
      pendingSync: Value(pendingSync),
      isDeleted: Value(isDeleted),
    );
  }

  factory EntryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryRecord(
      id: serializer.fromJson<String>(json['id']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      monthKey: serializer.fromJson<String>(json['monthKey']),
      day: serializer.fromJson<int>(json['day']),
      status: serializer.fromJson<String>(json['status']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      rateCents: serializer.fromJson<int>(json['rateCents']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      note: serializer.fromJson<String>(json['note']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serviceId': serializer.toJson<String>(serviceId),
      'monthKey': serializer.toJson<String>(monthKey),
      'day': serializer.toJson<int>(day),
      'status': serializer.toJson<String>(status),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String>(unit),
      'rateCents': serializer.toJson<int>(rateCents),
      'amountCents': serializer.toJson<int>(amountCents),
      'note': serializer.toJson<String>(note),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  EntryRecord copyWith({
    String? id,
    String? serviceId,
    String? monthKey,
    int? day,
    String? status,
    double? quantity,
    String? unit,
    int? rateCents,
    int? amountCents,
    String? note,
    DateTime? updatedAt,
    bool? pendingSync,
    bool? isDeleted,
  }) => EntryRecord(
    id: id ?? this.id,
    serviceId: serviceId ?? this.serviceId,
    monthKey: monthKey ?? this.monthKey,
    day: day ?? this.day,
    status: status ?? this.status,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    rateCents: rateCents ?? this.rateCents,
    amountCents: amountCents ?? this.amountCents,
    note: note ?? this.note,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingSync: pendingSync ?? this.pendingSync,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  EntryRecord copyWithCompanion(EntryRecordsCompanion data) {
    return EntryRecord(
      id: data.id.present ? data.id.value : this.id,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      day: data.day.present ? data.day.value : this.day,
      status: data.status.present ? data.status.value : this.status,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      rateCents: data.rateCents.present ? data.rateCents.value : this.rateCents,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingSync: data.pendingSync.present
          ? data.pendingSync.value
          : this.pendingSync,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryRecord(')
          ..write('id: $id, ')
          ..write('serviceId: $serviceId, ')
          ..write('monthKey: $monthKey, ')
          ..write('day: $day, ')
          ..write('status: $status, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('rateCents: $rateCents, ')
          ..write('amountCents: $amountCents, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serviceId,
    monthKey,
    day,
    status,
    quantity,
    unit,
    rateCents,
    amountCents,
    note,
    updatedAt,
    pendingSync,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryRecord &&
          other.id == this.id &&
          other.serviceId == this.serviceId &&
          other.monthKey == this.monthKey &&
          other.day == this.day &&
          other.status == this.status &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.rateCents == this.rateCents &&
          other.amountCents == this.amountCents &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt &&
          other.pendingSync == this.pendingSync &&
          other.isDeleted == this.isDeleted);
}

class EntryRecordsCompanion extends UpdateCompanion<EntryRecord> {
  final Value<String> id;
  final Value<String> serviceId;
  final Value<String> monthKey;
  final Value<int> day;
  final Value<String> status;
  final Value<double> quantity;
  final Value<String> unit;
  final Value<int> rateCents;
  final Value<int> amountCents;
  final Value<String> note;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingSync;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const EntryRecordsCompanion({
    this.id = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.day = const Value.absent(),
    this.status = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.rateCents = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryRecordsCompanion.insert({
    required String id,
    required String serviceId,
    required String monthKey,
    required int day,
    required String status,
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.rateCents = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime updatedAt,
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       serviceId = Value(serviceId),
       monthKey = Value(monthKey),
       day = Value(day),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<EntryRecord> custom({
    Expression<String>? id,
    Expression<String>? serviceId,
    Expression<String>? monthKey,
    Expression<int>? day,
    Expression<String>? status,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<int>? rateCents,
    Expression<int>? amountCents,
    Expression<String>? note,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingSync,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serviceId != null) 'service_id': serviceId,
      if (monthKey != null) 'month_key': monthKey,
      if (day != null) 'day': day,
      if (status != null) 'status': status,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (rateCents != null) 'rate_cents': rateCents,
      if (amountCents != null) 'amount_cents': amountCents,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? serviceId,
    Value<String>? monthKey,
    Value<int>? day,
    Value<String>? status,
    Value<double>? quantity,
    Value<String>? unit,
    Value<int>? rateCents,
    Value<int>? amountCents,
    Value<String>? note,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingSync,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return EntryRecordsCompanion(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      monthKey: monthKey ?? this.monthKey,
      day: day ?? this.day,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      rateCents: rateCents ?? this.rateCents,
      amountCents: amountCents ?? this.amountCents,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (rateCents.present) {
      map['rate_cents'] = Variable<int>(rateCents.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serviceId: $serviceId, ')
          ..write('monthKey: $monthKey, ')
          ..write('day: $day, ')
          ..write('status: $status, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('rateCents: $rateCents, ')
          ..write('amountCents: $amountCents, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ServiceMonthLogRecordsTable extends ServiceMonthLogRecords
    with TableInfo<$ServiceMonthLogRecordsTable, ServiceMonthLogRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServiceMonthLogRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
    'service_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthKeyMeta = const VerificationMeta(
    'monthKey',
  );
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
    'month_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _entriesJsonMeta = const VerificationMeta(
    'entriesJson',
  );
  @override
  late final GeneratedColumn<String> entriesJson = GeneratedColumn<String>(
    'entries_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{"schemaVersion":1,"overrides":{}}'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingSyncMeta = const VerificationMeta(
    'pendingSync',
  );
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
    'pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serviceId,
    monthKey,
    schemaVersion,
    entriesJson,
    updatedAt,
    pendingSync,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'service_month_log_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServiceMonthLogRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('service_id')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(
        _monthKeyMeta,
        monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    if (data.containsKey('entries_json')) {
      context.handle(
        _entriesJsonMeta,
        entriesJson.isAcceptableOrUnknown(
          data['entries_json']!,
          _entriesJsonMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
        _pendingSyncMeta,
        pendingSync.isAcceptableOrUnknown(
          data['pending_sync']!,
          _pendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServiceMonthLogRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServiceMonthLogRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_id'],
      )!,
      monthKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_key'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      entriesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entries_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_sync'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $ServiceMonthLogRecordsTable createAlias(String alias) {
    return $ServiceMonthLogRecordsTable(attachedDatabase, alias);
  }
}

class ServiceMonthLogRecord extends DataClass
    implements Insertable<ServiceMonthLogRecord> {
  final String id;
  final String serviceId;
  final String monthKey;
  final int schemaVersion;
  final String entriesJson;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool isDeleted;
  const ServiceMonthLogRecord({
    required this.id,
    required this.serviceId,
    required this.monthKey,
    required this.schemaVersion,
    required this.entriesJson,
    required this.updatedAt,
    required this.pendingSync,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['service_id'] = Variable<String>(serviceId);
    map['month_key'] = Variable<String>(monthKey);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['entries_json'] = Variable<String>(entriesJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_sync'] = Variable<bool>(pendingSync);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ServiceMonthLogRecordsCompanion toCompanion(bool nullToAbsent) {
    return ServiceMonthLogRecordsCompanion(
      id: Value(id),
      serviceId: Value(serviceId),
      monthKey: Value(monthKey),
      schemaVersion: Value(schemaVersion),
      entriesJson: Value(entriesJson),
      updatedAt: Value(updatedAt),
      pendingSync: Value(pendingSync),
      isDeleted: Value(isDeleted),
    );
  }

  factory ServiceMonthLogRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServiceMonthLogRecord(
      id: serializer.fromJson<String>(json['id']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      monthKey: serializer.fromJson<String>(json['monthKey']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      entriesJson: serializer.fromJson<String>(json['entriesJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serviceId': serializer.toJson<String>(serviceId),
      'monthKey': serializer.toJson<String>(monthKey),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'entriesJson': serializer.toJson<String>(entriesJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  ServiceMonthLogRecord copyWith({
    String? id,
    String? serviceId,
    String? monthKey,
    int? schemaVersion,
    String? entriesJson,
    DateTime? updatedAt,
    bool? pendingSync,
    bool? isDeleted,
  }) => ServiceMonthLogRecord(
    id: id ?? this.id,
    serviceId: serviceId ?? this.serviceId,
    monthKey: monthKey ?? this.monthKey,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    entriesJson: entriesJson ?? this.entriesJson,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingSync: pendingSync ?? this.pendingSync,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  ServiceMonthLogRecord copyWithCompanion(
    ServiceMonthLogRecordsCompanion data,
  ) {
    return ServiceMonthLogRecord(
      id: data.id.present ? data.id.value : this.id,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      entriesJson: data.entriesJson.present
          ? data.entriesJson.value
          : this.entriesJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingSync: data.pendingSync.present
          ? data.pendingSync.value
          : this.pendingSync,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServiceMonthLogRecord(')
          ..write('id: $id, ')
          ..write('serviceId: $serviceId, ')
          ..write('monthKey: $monthKey, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('entriesJson: $entriesJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serviceId,
    monthKey,
    schemaVersion,
    entriesJson,
    updatedAt,
    pendingSync,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServiceMonthLogRecord &&
          other.id == this.id &&
          other.serviceId == this.serviceId &&
          other.monthKey == this.monthKey &&
          other.schemaVersion == this.schemaVersion &&
          other.entriesJson == this.entriesJson &&
          other.updatedAt == this.updatedAt &&
          other.pendingSync == this.pendingSync &&
          other.isDeleted == this.isDeleted);
}

class ServiceMonthLogRecordsCompanion
    extends UpdateCompanion<ServiceMonthLogRecord> {
  final Value<String> id;
  final Value<String> serviceId;
  final Value<String> monthKey;
  final Value<int> schemaVersion;
  final Value<String> entriesJson;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingSync;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const ServiceMonthLogRecordsCompanion({
    this.id = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.entriesJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServiceMonthLogRecordsCompanion.insert({
    required String id,
    required String serviceId,
    required String monthKey,
    this.schemaVersion = const Value.absent(),
    this.entriesJson = const Value.absent(),
    required DateTime updatedAt,
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       serviceId = Value(serviceId),
       monthKey = Value(monthKey),
       updatedAt = Value(updatedAt);
  static Insertable<ServiceMonthLogRecord> custom({
    Expression<String>? id,
    Expression<String>? serviceId,
    Expression<String>? monthKey,
    Expression<int>? schemaVersion,
    Expression<String>? entriesJson,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingSync,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serviceId != null) 'service_id': serviceId,
      if (monthKey != null) 'month_key': monthKey,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (entriesJson != null) 'entries_json': entriesJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServiceMonthLogRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? serviceId,
    Value<String>? monthKey,
    Value<int>? schemaVersion,
    Value<String>? entriesJson,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingSync,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return ServiceMonthLogRecordsCompanion(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      monthKey: monthKey ?? this.monthKey,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      entriesJson: entriesJson ?? this.entriesJson,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (entriesJson.present) {
      map['entries_json'] = Variable<String>(entriesJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServiceMonthLogRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serviceId: $serviceId, ')
          ..write('monthKey: $monthKey, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('entriesJson: $entriesJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdvancePaymentRecordsTable extends AdvancePaymentRecords
    with TableInfo<$AdvancePaymentRecordsTable, AdvancePaymentRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdvancePaymentRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
    'service_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthKeyMeta = const VerificationMeta(
    'monthKey',
  );
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
    'month_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidOnMeta = const VerificationMeta('paidOn');
  @override
  late final GeneratedColumn<DateTime> paidOn = GeneratedColumn<DateTime>(
    'paid_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingSyncMeta = const VerificationMeta(
    'pendingSync',
  );
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
    'pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serviceId,
    monthKey,
    amountCents,
    paidOn,
    note,
    updatedAt,
    pendingSync,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'advance_payment_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdvancePaymentRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('service_id')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(
        _monthKeyMeta,
        monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('paid_on')) {
      context.handle(
        _paidOnMeta,
        paidOn.isAcceptableOrUnknown(data['paid_on']!, _paidOnMeta),
      );
    } else if (isInserting) {
      context.missing(_paidOnMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
        _pendingSyncMeta,
        pendingSync.isAcceptableOrUnknown(
          data['pending_sync']!,
          _pendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AdvancePaymentRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdvancePaymentRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_id'],
      )!,
      monthKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_key'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      paidOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_on'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_sync'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $AdvancePaymentRecordsTable createAlias(String alias) {
    return $AdvancePaymentRecordsTable(attachedDatabase, alias);
  }
}

class AdvancePaymentRecord extends DataClass
    implements Insertable<AdvancePaymentRecord> {
  final String id;
  final String serviceId;
  final String monthKey;
  final int amountCents;
  final DateTime paidOn;
  final String note;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool isDeleted;
  const AdvancePaymentRecord({
    required this.id,
    required this.serviceId,
    required this.monthKey,
    required this.amountCents,
    required this.paidOn,
    required this.note,
    required this.updatedAt,
    required this.pendingSync,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['service_id'] = Variable<String>(serviceId);
    map['month_key'] = Variable<String>(monthKey);
    map['amount_cents'] = Variable<int>(amountCents);
    map['paid_on'] = Variable<DateTime>(paidOn);
    map['note'] = Variable<String>(note);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_sync'] = Variable<bool>(pendingSync);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  AdvancePaymentRecordsCompanion toCompanion(bool nullToAbsent) {
    return AdvancePaymentRecordsCompanion(
      id: Value(id),
      serviceId: Value(serviceId),
      monthKey: Value(monthKey),
      amountCents: Value(amountCents),
      paidOn: Value(paidOn),
      note: Value(note),
      updatedAt: Value(updatedAt),
      pendingSync: Value(pendingSync),
      isDeleted: Value(isDeleted),
    );
  }

  factory AdvancePaymentRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdvancePaymentRecord(
      id: serializer.fromJson<String>(json['id']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      monthKey: serializer.fromJson<String>(json['monthKey']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      paidOn: serializer.fromJson<DateTime>(json['paidOn']),
      note: serializer.fromJson<String>(json['note']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serviceId': serializer.toJson<String>(serviceId),
      'monthKey': serializer.toJson<String>(monthKey),
      'amountCents': serializer.toJson<int>(amountCents),
      'paidOn': serializer.toJson<DateTime>(paidOn),
      'note': serializer.toJson<String>(note),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  AdvancePaymentRecord copyWith({
    String? id,
    String? serviceId,
    String? monthKey,
    int? amountCents,
    DateTime? paidOn,
    String? note,
    DateTime? updatedAt,
    bool? pendingSync,
    bool? isDeleted,
  }) => AdvancePaymentRecord(
    id: id ?? this.id,
    serviceId: serviceId ?? this.serviceId,
    monthKey: monthKey ?? this.monthKey,
    amountCents: amountCents ?? this.amountCents,
    paidOn: paidOn ?? this.paidOn,
    note: note ?? this.note,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingSync: pendingSync ?? this.pendingSync,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  AdvancePaymentRecord copyWithCompanion(AdvancePaymentRecordsCompanion data) {
    return AdvancePaymentRecord(
      id: data.id.present ? data.id.value : this.id,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      paidOn: data.paidOn.present ? data.paidOn.value : this.paidOn,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingSync: data.pendingSync.present
          ? data.pendingSync.value
          : this.pendingSync,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdvancePaymentRecord(')
          ..write('id: $id, ')
          ..write('serviceId: $serviceId, ')
          ..write('monthKey: $monthKey, ')
          ..write('amountCents: $amountCents, ')
          ..write('paidOn: $paidOn, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serviceId,
    monthKey,
    amountCents,
    paidOn,
    note,
    updatedAt,
    pendingSync,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdvancePaymentRecord &&
          other.id == this.id &&
          other.serviceId == this.serviceId &&
          other.monthKey == this.monthKey &&
          other.amountCents == this.amountCents &&
          other.paidOn == this.paidOn &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt &&
          other.pendingSync == this.pendingSync &&
          other.isDeleted == this.isDeleted);
}

class AdvancePaymentRecordsCompanion
    extends UpdateCompanion<AdvancePaymentRecord> {
  final Value<String> id;
  final Value<String> serviceId;
  final Value<String> monthKey;
  final Value<int> amountCents;
  final Value<DateTime> paidOn;
  final Value<String> note;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingSync;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const AdvancePaymentRecordsCompanion({
    this.id = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.paidOn = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdvancePaymentRecordsCompanion.insert({
    required String id,
    required String serviceId,
    required String monthKey,
    required int amountCents,
    required DateTime paidOn,
    this.note = const Value.absent(),
    required DateTime updatedAt,
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       serviceId = Value(serviceId),
       monthKey = Value(monthKey),
       amountCents = Value(amountCents),
       paidOn = Value(paidOn),
       updatedAt = Value(updatedAt);
  static Insertable<AdvancePaymentRecord> custom({
    Expression<String>? id,
    Expression<String>? serviceId,
    Expression<String>? monthKey,
    Expression<int>? amountCents,
    Expression<DateTime>? paidOn,
    Expression<String>? note,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingSync,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serviceId != null) 'service_id': serviceId,
      if (monthKey != null) 'month_key': monthKey,
      if (amountCents != null) 'amount_cents': amountCents,
      if (paidOn != null) 'paid_on': paidOn,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdvancePaymentRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? serviceId,
    Value<String>? monthKey,
    Value<int>? amountCents,
    Value<DateTime>? paidOn,
    Value<String>? note,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingSync,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return AdvancePaymentRecordsCompanion(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      monthKey: monthKey ?? this.monthKey,
      amountCents: amountCents ?? this.amountCents,
      paidOn: paidOn ?? this.paidOn,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (paidOn.present) {
      map['paid_on'] = Variable<DateTime>(paidOn.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdvancePaymentRecordsCompanion(')
          ..write('id: $id, ')
          ..write('serviceId: $serviceId, ')
          ..write('monthKey: $monthKey, ')
          ..write('amountCents: $amountCents, ')
          ..write('paidOn: $paidOn, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentTransactionRecordsTable extends PaymentTransactionRecords
    with TableInfo<$PaymentTransactionRecordsTable, PaymentTransactionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentTransactionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
    'service_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthKeyMeta = const VerificationMeta(
    'monthKey',
  );
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
    'month_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentDateMeta = const VerificationMeta(
    'paymentDate',
  );
  @override
  late final GeneratedColumn<DateTime> paymentDate = GeneratedColumn<DateTime>(
    'payment_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentModeMeta = const VerificationMeta(
    'paymentMode',
  );
  @override
  late final GeneratedColumn<String> paymentMode = GeneratedColumn<String>(
    'payment_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _currentMonthAmountCentsMeta =
      const VerificationMeta('currentMonthAmountCents');
  @override
  late final GeneratedColumn<int> currentMonthAmountCents =
      GeneratedColumn<int>(
        'current_month_amount_cents',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _previousBalanceAmountCentsMeta =
      const VerificationMeta('previousBalanceAmountCents');
  @override
  late final GeneratedColumn<int> previousBalanceAmountCents =
      GeneratedColumn<int>(
        'previous_balance_amount_cents',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _advanceAmountCentsMeta =
      const VerificationMeta('advanceAmountCents');
  @override
  late final GeneratedColumn<int> advanceAmountCents = GeneratedColumn<int>(
    'advance_amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingSyncMeta = const VerificationMeta(
    'pendingSync',
  );
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
    'pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    serviceId,
    monthKey,
    amountCents,
    paymentDate,
    paymentMode,
    note,
    currentMonthAmountCents,
    previousBalanceAmountCents,
    advanceAmountCents,
    createdAt,
    updatedAt,
    pendingSync,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_transaction_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentTransactionRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('service_id')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(
        _monthKeyMeta,
        monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('payment_date')) {
      context.handle(
        _paymentDateMeta,
        paymentDate.isAcceptableOrUnknown(
          data['payment_date']!,
          _paymentDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentDateMeta);
    }
    if (data.containsKey('payment_mode')) {
      context.handle(
        _paymentModeMeta,
        paymentMode.isAcceptableOrUnknown(
          data['payment_mode']!,
          _paymentModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentModeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('current_month_amount_cents')) {
      context.handle(
        _currentMonthAmountCentsMeta,
        currentMonthAmountCents.isAcceptableOrUnknown(
          data['current_month_amount_cents']!,
          _currentMonthAmountCentsMeta,
        ),
      );
    }
    if (data.containsKey('previous_balance_amount_cents')) {
      context.handle(
        _previousBalanceAmountCentsMeta,
        previousBalanceAmountCents.isAcceptableOrUnknown(
          data['previous_balance_amount_cents']!,
          _previousBalanceAmountCentsMeta,
        ),
      );
    }
    if (data.containsKey('advance_amount_cents')) {
      context.handle(
        _advanceAmountCentsMeta,
        advanceAmountCents.isAcceptableOrUnknown(
          data['advance_amount_cents']!,
          _advanceAmountCentsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
        _pendingSyncMeta,
        pendingSync.isAcceptableOrUnknown(
          data['pending_sync']!,
          _pendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentTransactionRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentTransactionRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_id'],
      )!,
      monthKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_key'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      paymentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}payment_date'],
      )!,
      paymentMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_mode'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      currentMonthAmountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_month_amount_cents'],
      )!,
      previousBalanceAmountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}previous_balance_amount_cents'],
      )!,
      advanceAmountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}advance_amount_cents'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_sync'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $PaymentTransactionRecordsTable createAlias(String alias) {
    return $PaymentTransactionRecordsTable(attachedDatabase, alias);
  }
}

class PaymentTransactionRecord extends DataClass
    implements Insertable<PaymentTransactionRecord> {
  final String id;
  final String userId;
  final String serviceId;
  final String monthKey;
  final int amountCents;
  final DateTime paymentDate;
  final String paymentMode;
  final String note;
  final int currentMonthAmountCents;
  final int previousBalanceAmountCents;
  final int advanceAmountCents;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool isDeleted;
  const PaymentTransactionRecord({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.monthKey,
    required this.amountCents,
    required this.paymentDate,
    required this.paymentMode,
    required this.note,
    required this.currentMonthAmountCents,
    required this.previousBalanceAmountCents,
    required this.advanceAmountCents,
    required this.createdAt,
    required this.updatedAt,
    required this.pendingSync,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['service_id'] = Variable<String>(serviceId);
    map['month_key'] = Variable<String>(monthKey);
    map['amount_cents'] = Variable<int>(amountCents);
    map['payment_date'] = Variable<DateTime>(paymentDate);
    map['payment_mode'] = Variable<String>(paymentMode);
    map['note'] = Variable<String>(note);
    map['current_month_amount_cents'] = Variable<int>(currentMonthAmountCents);
    map['previous_balance_amount_cents'] = Variable<int>(
      previousBalanceAmountCents,
    );
    map['advance_amount_cents'] = Variable<int>(advanceAmountCents);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_sync'] = Variable<bool>(pendingSync);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  PaymentTransactionRecordsCompanion toCompanion(bool nullToAbsent) {
    return PaymentTransactionRecordsCompanion(
      id: Value(id),
      userId: Value(userId),
      serviceId: Value(serviceId),
      monthKey: Value(monthKey),
      amountCents: Value(amountCents),
      paymentDate: Value(paymentDate),
      paymentMode: Value(paymentMode),
      note: Value(note),
      currentMonthAmountCents: Value(currentMonthAmountCents),
      previousBalanceAmountCents: Value(previousBalanceAmountCents),
      advanceAmountCents: Value(advanceAmountCents),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      pendingSync: Value(pendingSync),
      isDeleted: Value(isDeleted),
    );
  }

  factory PaymentTransactionRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentTransactionRecord(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      monthKey: serializer.fromJson<String>(json['monthKey']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      paymentDate: serializer.fromJson<DateTime>(json['paymentDate']),
      paymentMode: serializer.fromJson<String>(json['paymentMode']),
      note: serializer.fromJson<String>(json['note']),
      currentMonthAmountCents: serializer.fromJson<int>(
        json['currentMonthAmountCents'],
      ),
      previousBalanceAmountCents: serializer.fromJson<int>(
        json['previousBalanceAmountCents'],
      ),
      advanceAmountCents: serializer.fromJson<int>(json['advanceAmountCents']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'serviceId': serializer.toJson<String>(serviceId),
      'monthKey': serializer.toJson<String>(monthKey),
      'amountCents': serializer.toJson<int>(amountCents),
      'paymentDate': serializer.toJson<DateTime>(paymentDate),
      'paymentMode': serializer.toJson<String>(paymentMode),
      'note': serializer.toJson<String>(note),
      'currentMonthAmountCents': serializer.toJson<int>(
        currentMonthAmountCents,
      ),
      'previousBalanceAmountCents': serializer.toJson<int>(
        previousBalanceAmountCents,
      ),
      'advanceAmountCents': serializer.toJson<int>(advanceAmountCents),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  PaymentTransactionRecord copyWith({
    String? id,
    String? userId,
    String? serviceId,
    String? monthKey,
    int? amountCents,
    DateTime? paymentDate,
    String? paymentMode,
    String? note,
    int? currentMonthAmountCents,
    int? previousBalanceAmountCents,
    int? advanceAmountCents,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pendingSync,
    bool? isDeleted,
  }) => PaymentTransactionRecord(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    serviceId: serviceId ?? this.serviceId,
    monthKey: monthKey ?? this.monthKey,
    amountCents: amountCents ?? this.amountCents,
    paymentDate: paymentDate ?? this.paymentDate,
    paymentMode: paymentMode ?? this.paymentMode,
    note: note ?? this.note,
    currentMonthAmountCents:
        currentMonthAmountCents ?? this.currentMonthAmountCents,
    previousBalanceAmountCents:
        previousBalanceAmountCents ?? this.previousBalanceAmountCents,
    advanceAmountCents: advanceAmountCents ?? this.advanceAmountCents,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingSync: pendingSync ?? this.pendingSync,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  PaymentTransactionRecord copyWithCompanion(
    PaymentTransactionRecordsCompanion data,
  ) {
    return PaymentTransactionRecord(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      paymentDate: data.paymentDate.present
          ? data.paymentDate.value
          : this.paymentDate,
      paymentMode: data.paymentMode.present
          ? data.paymentMode.value
          : this.paymentMode,
      note: data.note.present ? data.note.value : this.note,
      currentMonthAmountCents: data.currentMonthAmountCents.present
          ? data.currentMonthAmountCents.value
          : this.currentMonthAmountCents,
      previousBalanceAmountCents: data.previousBalanceAmountCents.present
          ? data.previousBalanceAmountCents.value
          : this.previousBalanceAmountCents,
      advanceAmountCents: data.advanceAmountCents.present
          ? data.advanceAmountCents.value
          : this.advanceAmountCents,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingSync: data.pendingSync.present
          ? data.pendingSync.value
          : this.pendingSync,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentTransactionRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('serviceId: $serviceId, ')
          ..write('monthKey: $monthKey, ')
          ..write('amountCents: $amountCents, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('note: $note, ')
          ..write('currentMonthAmountCents: $currentMonthAmountCents, ')
          ..write('previousBalanceAmountCents: $previousBalanceAmountCents, ')
          ..write('advanceAmountCents: $advanceAmountCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    serviceId,
    monthKey,
    amountCents,
    paymentDate,
    paymentMode,
    note,
    currentMonthAmountCents,
    previousBalanceAmountCents,
    advanceAmountCents,
    createdAt,
    updatedAt,
    pendingSync,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentTransactionRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.serviceId == this.serviceId &&
          other.monthKey == this.monthKey &&
          other.amountCents == this.amountCents &&
          other.paymentDate == this.paymentDate &&
          other.paymentMode == this.paymentMode &&
          other.note == this.note &&
          other.currentMonthAmountCents == this.currentMonthAmountCents &&
          other.previousBalanceAmountCents == this.previousBalanceAmountCents &&
          other.advanceAmountCents == this.advanceAmountCents &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.pendingSync == this.pendingSync &&
          other.isDeleted == this.isDeleted);
}

class PaymentTransactionRecordsCompanion
    extends UpdateCompanion<PaymentTransactionRecord> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> serviceId;
  final Value<String> monthKey;
  final Value<int> amountCents;
  final Value<DateTime> paymentDate;
  final Value<String> paymentMode;
  final Value<String> note;
  final Value<int> currentMonthAmountCents;
  final Value<int> previousBalanceAmountCents;
  final Value<int> advanceAmountCents;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingSync;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const PaymentTransactionRecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.paymentMode = const Value.absent(),
    this.note = const Value.absent(),
    this.currentMonthAmountCents = const Value.absent(),
    this.previousBalanceAmountCents = const Value.absent(),
    this.advanceAmountCents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentTransactionRecordsCompanion.insert({
    required String id,
    required String userId,
    required String serviceId,
    required String monthKey,
    required int amountCents,
    required DateTime paymentDate,
    required String paymentMode,
    this.note = const Value.absent(),
    this.currentMonthAmountCents = const Value.absent(),
    this.previousBalanceAmountCents = const Value.absent(),
    this.advanceAmountCents = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       serviceId = Value(serviceId),
       monthKey = Value(monthKey),
       amountCents = Value(amountCents),
       paymentDate = Value(paymentDate),
       paymentMode = Value(paymentMode),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PaymentTransactionRecord> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? serviceId,
    Expression<String>? monthKey,
    Expression<int>? amountCents,
    Expression<DateTime>? paymentDate,
    Expression<String>? paymentMode,
    Expression<String>? note,
    Expression<int>? currentMonthAmountCents,
    Expression<int>? previousBalanceAmountCents,
    Expression<int>? advanceAmountCents,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingSync,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (serviceId != null) 'service_id': serviceId,
      if (monthKey != null) 'month_key': monthKey,
      if (amountCents != null) 'amount_cents': amountCents,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (note != null) 'note': note,
      if (currentMonthAmountCents != null)
        'current_month_amount_cents': currentMonthAmountCents,
      if (previousBalanceAmountCents != null)
        'previous_balance_amount_cents': previousBalanceAmountCents,
      if (advanceAmountCents != null)
        'advance_amount_cents': advanceAmountCents,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentTransactionRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? serviceId,
    Value<String>? monthKey,
    Value<int>? amountCents,
    Value<DateTime>? paymentDate,
    Value<String>? paymentMode,
    Value<String>? note,
    Value<int>? currentMonthAmountCents,
    Value<int>? previousBalanceAmountCents,
    Value<int>? advanceAmountCents,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingSync,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return PaymentTransactionRecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      monthKey: monthKey ?? this.monthKey,
      amountCents: amountCents ?? this.amountCents,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMode: paymentMode ?? this.paymentMode,
      note: note ?? this.note,
      currentMonthAmountCents:
          currentMonthAmountCents ?? this.currentMonthAmountCents,
      previousBalanceAmountCents:
          previousBalanceAmountCents ?? this.previousBalanceAmountCents,
      advanceAmountCents: advanceAmountCents ?? this.advanceAmountCents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<DateTime>(paymentDate.value);
    }
    if (paymentMode.present) {
      map['payment_mode'] = Variable<String>(paymentMode.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (currentMonthAmountCents.present) {
      map['current_month_amount_cents'] = Variable<int>(
        currentMonthAmountCents.value,
      );
    }
    if (previousBalanceAmountCents.present) {
      map['previous_balance_amount_cents'] = Variable<int>(
        previousBalanceAmountCents.value,
      );
    }
    if (advanceAmountCents.present) {
      map['advance_amount_cents'] = Variable<int>(advanceAmountCents.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentTransactionRecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('serviceId: $serviceId, ')
          ..write('monthKey: $monthKey, ')
          ..write('amountCents: $amountCents, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('note: $note, ')
          ..write('currentMonthAmountCents: $currentMonthAmountCents, ')
          ..write('previousBalanceAmountCents: $previousBalanceAmountCents, ')
          ..write('advanceAmountCents: $advanceAmountCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MonthlySettlementRecordsTable extends MonthlySettlementRecords
    with TableInfo<$MonthlySettlementRecordsTable, MonthlySettlementRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthlySettlementRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
    'service_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthKeyMeta = const VerificationMeta(
    'monthKey',
  );
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
    'month_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grossAmountCentsMeta = const VerificationMeta(
    'grossAmountCents',
  );
  @override
  late final GeneratedColumn<int> grossAmountCents = GeneratedColumn<int>(
    'gross_amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _advanceUsedCentsMeta = const VerificationMeta(
    'advanceUsedCents',
  );
  @override
  late final GeneratedColumn<int> advanceUsedCents = GeneratedColumn<int>(
    'advance_used_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _previousCarryForwardCentsMeta =
      const VerificationMeta('previousCarryForwardCents');
  @override
  late final GeneratedColumn<int> previousCarryForwardCents =
      GeneratedColumn<int>(
        'previous_carry_forward_cents',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _previousAdvanceCentsMeta =
      const VerificationMeta('previousAdvanceCents');
  @override
  late final GeneratedColumn<int> previousAdvanceCents = GeneratedColumn<int>(
    'previous_advance_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _payableAmountCentsMeta =
      const VerificationMeta('payableAmountCents');
  @override
  late final GeneratedColumn<int> payableAmountCents = GeneratedColumn<int>(
    'payable_amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paidAmountCentsMeta = const VerificationMeta(
    'paidAmountCents',
  );
  @override
  late final GeneratedColumn<int> paidAmountCents = GeneratedColumn<int>(
    'paid_amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _remainingAmountCentsMeta =
      const VerificationMeta('remainingAmountCents');
  @override
  late final GeneratedColumn<int> remainingAmountCents = GeneratedColumn<int>(
    'remaining_amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _carryForwardToNextMonthCentsMeta =
      const VerificationMeta('carryForwardToNextMonthCents');
  @override
  late final GeneratedColumn<int> carryForwardToNextMonthCents =
      GeneratedColumn<int>(
        'carry_forward_to_next_month_cents',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _advanceToNextMonthCentsMeta =
      const VerificationMeta('advanceToNextMonthCents');
  @override
  late final GeneratedColumn<int> advanceToNextMonthCents =
      GeneratedColumn<int>(
        'advance_to_next_month_cents',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
    'generated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingSyncMeta = const VerificationMeta(
    'pendingSync',
  );
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
    'pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    serviceId,
    monthKey,
    grossAmountCents,
    advanceUsedCents,
    previousCarryForwardCents,
    previousAdvanceCents,
    payableAmountCents,
    paidAmountCents,
    remainingAmountCents,
    carryForwardToNextMonthCents,
    advanceToNextMonthCents,
    status,
    generatedAt,
    updatedAt,
    pendingSync,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monthly_settlement_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthlySettlementRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('service_id')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(
        _monthKeyMeta,
        monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('gross_amount_cents')) {
      context.handle(
        _grossAmountCentsMeta,
        grossAmountCents.isAcceptableOrUnknown(
          data['gross_amount_cents']!,
          _grossAmountCentsMeta,
        ),
      );
    }
    if (data.containsKey('advance_used_cents')) {
      context.handle(
        _advanceUsedCentsMeta,
        advanceUsedCents.isAcceptableOrUnknown(
          data['advance_used_cents']!,
          _advanceUsedCentsMeta,
        ),
      );
    }
    if (data.containsKey('previous_carry_forward_cents')) {
      context.handle(
        _previousCarryForwardCentsMeta,
        previousCarryForwardCents.isAcceptableOrUnknown(
          data['previous_carry_forward_cents']!,
          _previousCarryForwardCentsMeta,
        ),
      );
    }
    if (data.containsKey('previous_advance_cents')) {
      context.handle(
        _previousAdvanceCentsMeta,
        previousAdvanceCents.isAcceptableOrUnknown(
          data['previous_advance_cents']!,
          _previousAdvanceCentsMeta,
        ),
      );
    }
    if (data.containsKey('payable_amount_cents')) {
      context.handle(
        _payableAmountCentsMeta,
        payableAmountCents.isAcceptableOrUnknown(
          data['payable_amount_cents']!,
          _payableAmountCentsMeta,
        ),
      );
    }
    if (data.containsKey('paid_amount_cents')) {
      context.handle(
        _paidAmountCentsMeta,
        paidAmountCents.isAcceptableOrUnknown(
          data['paid_amount_cents']!,
          _paidAmountCentsMeta,
        ),
      );
    }
    if (data.containsKey('remaining_amount_cents')) {
      context.handle(
        _remainingAmountCentsMeta,
        remainingAmountCents.isAcceptableOrUnknown(
          data['remaining_amount_cents']!,
          _remainingAmountCentsMeta,
        ),
      );
    }
    if (data.containsKey('carry_forward_to_next_month_cents')) {
      context.handle(
        _carryForwardToNextMonthCentsMeta,
        carryForwardToNextMonthCents.isAcceptableOrUnknown(
          data['carry_forward_to_next_month_cents']!,
          _carryForwardToNextMonthCentsMeta,
        ),
      );
    }
    if (data.containsKey('advance_to_next_month_cents')) {
      context.handle(
        _advanceToNextMonthCentsMeta,
        advanceToNextMonthCents.isAcceptableOrUnknown(
          data['advance_to_next_month_cents']!,
          _advanceToNextMonthCentsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
        _pendingSyncMeta,
        pendingSync.isAcceptableOrUnknown(
          data['pending_sync']!,
          _pendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MonthlySettlementRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthlySettlementRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_id'],
      )!,
      monthKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_key'],
      )!,
      grossAmountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gross_amount_cents'],
      )!,
      advanceUsedCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}advance_used_cents'],
      )!,
      previousCarryForwardCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}previous_carry_forward_cents'],
      )!,
      previousAdvanceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}previous_advance_cents'],
      )!,
      payableAmountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payable_amount_cents'],
      )!,
      paidAmountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_amount_cents'],
      )!,
      remainingAmountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remaining_amount_cents'],
      )!,
      carryForwardToNextMonthCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carry_forward_to_next_month_cents'],
      )!,
      advanceToNextMonthCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}advance_to_next_month_cents'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      generatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}generated_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_sync'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $MonthlySettlementRecordsTable createAlias(String alias) {
    return $MonthlySettlementRecordsTable(attachedDatabase, alias);
  }
}

class MonthlySettlementRecord extends DataClass
    implements Insertable<MonthlySettlementRecord> {
  final String id;
  final String userId;
  final String serviceId;
  final String monthKey;
  final int grossAmountCents;
  final int advanceUsedCents;
  final int previousCarryForwardCents;
  final int previousAdvanceCents;
  final int payableAmountCents;
  final int paidAmountCents;
  final int remainingAmountCents;
  final int carryForwardToNextMonthCents;
  final int advanceToNextMonthCents;
  final String status;
  final DateTime generatedAt;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool isDeleted;
  const MonthlySettlementRecord({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.monthKey,
    required this.grossAmountCents,
    required this.advanceUsedCents,
    required this.previousCarryForwardCents,
    required this.previousAdvanceCents,
    required this.payableAmountCents,
    required this.paidAmountCents,
    required this.remainingAmountCents,
    required this.carryForwardToNextMonthCents,
    required this.advanceToNextMonthCents,
    required this.status,
    required this.generatedAt,
    required this.updatedAt,
    required this.pendingSync,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['service_id'] = Variable<String>(serviceId);
    map['month_key'] = Variable<String>(monthKey);
    map['gross_amount_cents'] = Variable<int>(grossAmountCents);
    map['advance_used_cents'] = Variable<int>(advanceUsedCents);
    map['previous_carry_forward_cents'] = Variable<int>(
      previousCarryForwardCents,
    );
    map['previous_advance_cents'] = Variable<int>(previousAdvanceCents);
    map['payable_amount_cents'] = Variable<int>(payableAmountCents);
    map['paid_amount_cents'] = Variable<int>(paidAmountCents);
    map['remaining_amount_cents'] = Variable<int>(remainingAmountCents);
    map['carry_forward_to_next_month_cents'] = Variable<int>(
      carryForwardToNextMonthCents,
    );
    map['advance_to_next_month_cents'] = Variable<int>(advanceToNextMonthCents);
    map['status'] = Variable<String>(status);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_sync'] = Variable<bool>(pendingSync);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  MonthlySettlementRecordsCompanion toCompanion(bool nullToAbsent) {
    return MonthlySettlementRecordsCompanion(
      id: Value(id),
      userId: Value(userId),
      serviceId: Value(serviceId),
      monthKey: Value(monthKey),
      grossAmountCents: Value(grossAmountCents),
      advanceUsedCents: Value(advanceUsedCents),
      previousCarryForwardCents: Value(previousCarryForwardCents),
      previousAdvanceCents: Value(previousAdvanceCents),
      payableAmountCents: Value(payableAmountCents),
      paidAmountCents: Value(paidAmountCents),
      remainingAmountCents: Value(remainingAmountCents),
      carryForwardToNextMonthCents: Value(carryForwardToNextMonthCents),
      advanceToNextMonthCents: Value(advanceToNextMonthCents),
      status: Value(status),
      generatedAt: Value(generatedAt),
      updatedAt: Value(updatedAt),
      pendingSync: Value(pendingSync),
      isDeleted: Value(isDeleted),
    );
  }

  factory MonthlySettlementRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthlySettlementRecord(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      monthKey: serializer.fromJson<String>(json['monthKey']),
      grossAmountCents: serializer.fromJson<int>(json['grossAmountCents']),
      advanceUsedCents: serializer.fromJson<int>(json['advanceUsedCents']),
      previousCarryForwardCents: serializer.fromJson<int>(
        json['previousCarryForwardCents'],
      ),
      previousAdvanceCents: serializer.fromJson<int>(
        json['previousAdvanceCents'],
      ),
      payableAmountCents: serializer.fromJson<int>(json['payableAmountCents']),
      paidAmountCents: serializer.fromJson<int>(json['paidAmountCents']),
      remainingAmountCents: serializer.fromJson<int>(
        json['remainingAmountCents'],
      ),
      carryForwardToNextMonthCents: serializer.fromJson<int>(
        json['carryForwardToNextMonthCents'],
      ),
      advanceToNextMonthCents: serializer.fromJson<int>(
        json['advanceToNextMonthCents'],
      ),
      status: serializer.fromJson<String>(json['status']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'serviceId': serializer.toJson<String>(serviceId),
      'monthKey': serializer.toJson<String>(monthKey),
      'grossAmountCents': serializer.toJson<int>(grossAmountCents),
      'advanceUsedCents': serializer.toJson<int>(advanceUsedCents),
      'previousCarryForwardCents': serializer.toJson<int>(
        previousCarryForwardCents,
      ),
      'previousAdvanceCents': serializer.toJson<int>(previousAdvanceCents),
      'payableAmountCents': serializer.toJson<int>(payableAmountCents),
      'paidAmountCents': serializer.toJson<int>(paidAmountCents),
      'remainingAmountCents': serializer.toJson<int>(remainingAmountCents),
      'carryForwardToNextMonthCents': serializer.toJson<int>(
        carryForwardToNextMonthCents,
      ),
      'advanceToNextMonthCents': serializer.toJson<int>(
        advanceToNextMonthCents,
      ),
      'status': serializer.toJson<String>(status),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  MonthlySettlementRecord copyWith({
    String? id,
    String? userId,
    String? serviceId,
    String? monthKey,
    int? grossAmountCents,
    int? advanceUsedCents,
    int? previousCarryForwardCents,
    int? previousAdvanceCents,
    int? payableAmountCents,
    int? paidAmountCents,
    int? remainingAmountCents,
    int? carryForwardToNextMonthCents,
    int? advanceToNextMonthCents,
    String? status,
    DateTime? generatedAt,
    DateTime? updatedAt,
    bool? pendingSync,
    bool? isDeleted,
  }) => MonthlySettlementRecord(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    serviceId: serviceId ?? this.serviceId,
    monthKey: monthKey ?? this.monthKey,
    grossAmountCents: grossAmountCents ?? this.grossAmountCents,
    advanceUsedCents: advanceUsedCents ?? this.advanceUsedCents,
    previousCarryForwardCents:
        previousCarryForwardCents ?? this.previousCarryForwardCents,
    previousAdvanceCents: previousAdvanceCents ?? this.previousAdvanceCents,
    payableAmountCents: payableAmountCents ?? this.payableAmountCents,
    paidAmountCents: paidAmountCents ?? this.paidAmountCents,
    remainingAmountCents: remainingAmountCents ?? this.remainingAmountCents,
    carryForwardToNextMonthCents:
        carryForwardToNextMonthCents ?? this.carryForwardToNextMonthCents,
    advanceToNextMonthCents:
        advanceToNextMonthCents ?? this.advanceToNextMonthCents,
    status: status ?? this.status,
    generatedAt: generatedAt ?? this.generatedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingSync: pendingSync ?? this.pendingSync,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  MonthlySettlementRecord copyWithCompanion(
    MonthlySettlementRecordsCompanion data,
  ) {
    return MonthlySettlementRecord(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      grossAmountCents: data.grossAmountCents.present
          ? data.grossAmountCents.value
          : this.grossAmountCents,
      advanceUsedCents: data.advanceUsedCents.present
          ? data.advanceUsedCents.value
          : this.advanceUsedCents,
      previousCarryForwardCents: data.previousCarryForwardCents.present
          ? data.previousCarryForwardCents.value
          : this.previousCarryForwardCents,
      previousAdvanceCents: data.previousAdvanceCents.present
          ? data.previousAdvanceCents.value
          : this.previousAdvanceCents,
      payableAmountCents: data.payableAmountCents.present
          ? data.payableAmountCents.value
          : this.payableAmountCents,
      paidAmountCents: data.paidAmountCents.present
          ? data.paidAmountCents.value
          : this.paidAmountCents,
      remainingAmountCents: data.remainingAmountCents.present
          ? data.remainingAmountCents.value
          : this.remainingAmountCents,
      carryForwardToNextMonthCents: data.carryForwardToNextMonthCents.present
          ? data.carryForwardToNextMonthCents.value
          : this.carryForwardToNextMonthCents,
      advanceToNextMonthCents: data.advanceToNextMonthCents.present
          ? data.advanceToNextMonthCents.value
          : this.advanceToNextMonthCents,
      status: data.status.present ? data.status.value : this.status,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingSync: data.pendingSync.present
          ? data.pendingSync.value
          : this.pendingSync,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthlySettlementRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('serviceId: $serviceId, ')
          ..write('monthKey: $monthKey, ')
          ..write('grossAmountCents: $grossAmountCents, ')
          ..write('advanceUsedCents: $advanceUsedCents, ')
          ..write('previousCarryForwardCents: $previousCarryForwardCents, ')
          ..write('previousAdvanceCents: $previousAdvanceCents, ')
          ..write('payableAmountCents: $payableAmountCents, ')
          ..write('paidAmountCents: $paidAmountCents, ')
          ..write('remainingAmountCents: $remainingAmountCents, ')
          ..write(
            'carryForwardToNextMonthCents: $carryForwardToNextMonthCents, ',
          )
          ..write('advanceToNextMonthCents: $advanceToNextMonthCents, ')
          ..write('status: $status, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    serviceId,
    monthKey,
    grossAmountCents,
    advanceUsedCents,
    previousCarryForwardCents,
    previousAdvanceCents,
    payableAmountCents,
    paidAmountCents,
    remainingAmountCents,
    carryForwardToNextMonthCents,
    advanceToNextMonthCents,
    status,
    generatedAt,
    updatedAt,
    pendingSync,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlySettlementRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.serviceId == this.serviceId &&
          other.monthKey == this.monthKey &&
          other.grossAmountCents == this.grossAmountCents &&
          other.advanceUsedCents == this.advanceUsedCents &&
          other.previousCarryForwardCents == this.previousCarryForwardCents &&
          other.previousAdvanceCents == this.previousAdvanceCents &&
          other.payableAmountCents == this.payableAmountCents &&
          other.paidAmountCents == this.paidAmountCents &&
          other.remainingAmountCents == this.remainingAmountCents &&
          other.carryForwardToNextMonthCents ==
              this.carryForwardToNextMonthCents &&
          other.advanceToNextMonthCents == this.advanceToNextMonthCents &&
          other.status == this.status &&
          other.generatedAt == this.generatedAt &&
          other.updatedAt == this.updatedAt &&
          other.pendingSync == this.pendingSync &&
          other.isDeleted == this.isDeleted);
}

class MonthlySettlementRecordsCompanion
    extends UpdateCompanion<MonthlySettlementRecord> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> serviceId;
  final Value<String> monthKey;
  final Value<int> grossAmountCents;
  final Value<int> advanceUsedCents;
  final Value<int> previousCarryForwardCents;
  final Value<int> previousAdvanceCents;
  final Value<int> payableAmountCents;
  final Value<int> paidAmountCents;
  final Value<int> remainingAmountCents;
  final Value<int> carryForwardToNextMonthCents;
  final Value<int> advanceToNextMonthCents;
  final Value<String> status;
  final Value<DateTime> generatedAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingSync;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const MonthlySettlementRecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.grossAmountCents = const Value.absent(),
    this.advanceUsedCents = const Value.absent(),
    this.previousCarryForwardCents = const Value.absent(),
    this.previousAdvanceCents = const Value.absent(),
    this.payableAmountCents = const Value.absent(),
    this.paidAmountCents = const Value.absent(),
    this.remainingAmountCents = const Value.absent(),
    this.carryForwardToNextMonthCents = const Value.absent(),
    this.advanceToNextMonthCents = const Value.absent(),
    this.status = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonthlySettlementRecordsCompanion.insert({
    required String id,
    required String userId,
    required String serviceId,
    required String monthKey,
    this.grossAmountCents = const Value.absent(),
    this.advanceUsedCents = const Value.absent(),
    this.previousCarryForwardCents = const Value.absent(),
    this.previousAdvanceCents = const Value.absent(),
    this.payableAmountCents = const Value.absent(),
    this.paidAmountCents = const Value.absent(),
    this.remainingAmountCents = const Value.absent(),
    this.carryForwardToNextMonthCents = const Value.absent(),
    this.advanceToNextMonthCents = const Value.absent(),
    required String status,
    required DateTime generatedAt,
    required DateTime updatedAt,
    this.pendingSync = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       serviceId = Value(serviceId),
       monthKey = Value(monthKey),
       status = Value(status),
       generatedAt = Value(generatedAt),
       updatedAt = Value(updatedAt);
  static Insertable<MonthlySettlementRecord> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? serviceId,
    Expression<String>? monthKey,
    Expression<int>? grossAmountCents,
    Expression<int>? advanceUsedCents,
    Expression<int>? previousCarryForwardCents,
    Expression<int>? previousAdvanceCents,
    Expression<int>? payableAmountCents,
    Expression<int>? paidAmountCents,
    Expression<int>? remainingAmountCents,
    Expression<int>? carryForwardToNextMonthCents,
    Expression<int>? advanceToNextMonthCents,
    Expression<String>? status,
    Expression<DateTime>? generatedAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingSync,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (serviceId != null) 'service_id': serviceId,
      if (monthKey != null) 'month_key': monthKey,
      if (grossAmountCents != null) 'gross_amount_cents': grossAmountCents,
      if (advanceUsedCents != null) 'advance_used_cents': advanceUsedCents,
      if (previousCarryForwardCents != null)
        'previous_carry_forward_cents': previousCarryForwardCents,
      if (previousAdvanceCents != null)
        'previous_advance_cents': previousAdvanceCents,
      if (payableAmountCents != null)
        'payable_amount_cents': payableAmountCents,
      if (paidAmountCents != null) 'paid_amount_cents': paidAmountCents,
      if (remainingAmountCents != null)
        'remaining_amount_cents': remainingAmountCents,
      if (carryForwardToNextMonthCents != null)
        'carry_forward_to_next_month_cents': carryForwardToNextMonthCents,
      if (advanceToNextMonthCents != null)
        'advance_to_next_month_cents': advanceToNextMonthCents,
      if (status != null) 'status': status,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonthlySettlementRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? serviceId,
    Value<String>? monthKey,
    Value<int>? grossAmountCents,
    Value<int>? advanceUsedCents,
    Value<int>? previousCarryForwardCents,
    Value<int>? previousAdvanceCents,
    Value<int>? payableAmountCents,
    Value<int>? paidAmountCents,
    Value<int>? remainingAmountCents,
    Value<int>? carryForwardToNextMonthCents,
    Value<int>? advanceToNextMonthCents,
    Value<String>? status,
    Value<DateTime>? generatedAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingSync,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return MonthlySettlementRecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      monthKey: monthKey ?? this.monthKey,
      grossAmountCents: grossAmountCents ?? this.grossAmountCents,
      advanceUsedCents: advanceUsedCents ?? this.advanceUsedCents,
      previousCarryForwardCents:
          previousCarryForwardCents ?? this.previousCarryForwardCents,
      previousAdvanceCents: previousAdvanceCents ?? this.previousAdvanceCents,
      payableAmountCents: payableAmountCents ?? this.payableAmountCents,
      paidAmountCents: paidAmountCents ?? this.paidAmountCents,
      remainingAmountCents: remainingAmountCents ?? this.remainingAmountCents,
      carryForwardToNextMonthCents:
          carryForwardToNextMonthCents ?? this.carryForwardToNextMonthCents,
      advanceToNextMonthCents:
          advanceToNextMonthCents ?? this.advanceToNextMonthCents,
      status: status ?? this.status,
      generatedAt: generatedAt ?? this.generatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (grossAmountCents.present) {
      map['gross_amount_cents'] = Variable<int>(grossAmountCents.value);
    }
    if (advanceUsedCents.present) {
      map['advance_used_cents'] = Variable<int>(advanceUsedCents.value);
    }
    if (previousCarryForwardCents.present) {
      map['previous_carry_forward_cents'] = Variable<int>(
        previousCarryForwardCents.value,
      );
    }
    if (previousAdvanceCents.present) {
      map['previous_advance_cents'] = Variable<int>(previousAdvanceCents.value);
    }
    if (payableAmountCents.present) {
      map['payable_amount_cents'] = Variable<int>(payableAmountCents.value);
    }
    if (paidAmountCents.present) {
      map['paid_amount_cents'] = Variable<int>(paidAmountCents.value);
    }
    if (remainingAmountCents.present) {
      map['remaining_amount_cents'] = Variable<int>(remainingAmountCents.value);
    }
    if (carryForwardToNextMonthCents.present) {
      map['carry_forward_to_next_month_cents'] = Variable<int>(
        carryForwardToNextMonthCents.value,
      );
    }
    if (advanceToNextMonthCents.present) {
      map['advance_to_next_month_cents'] = Variable<int>(
        advanceToNextMonthCents.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthlySettlementRecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('serviceId: $serviceId, ')
          ..write('monthKey: $monthKey, ')
          ..write('grossAmountCents: $grossAmountCents, ')
          ..write('advanceUsedCents: $advanceUsedCents, ')
          ..write('previousCarryForwardCents: $previousCarryForwardCents, ')
          ..write('previousAdvanceCents: $previousAdvanceCents, ')
          ..write('payableAmountCents: $payableAmountCents, ')
          ..write('paidAmountCents: $paidAmountCents, ')
          ..write('remainingAmountCents: $remainingAmountCents, ')
          ..write(
            'carryForwardToNextMonthCents: $carryForwardToNextMonthCents, ',
          )
          ..write('advanceToNextMonthCents: $advanceToNextMonthCents, ')
          ..write('status: $status, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataRecordsTable extends SyncMetadataRecords
    with TableInfo<$SyncMetadataRecordsTable, SyncMetadataRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, entityType, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncMetadataRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $SyncMetadataRecordsTable createAlias(String alias) {
    return $SyncMetadataRecordsTable(attachedDatabase, alias);
  }
}

class SyncMetadataRecord extends DataClass
    implements Insertable<SyncMetadataRecord> {
  final String id;
  final String entityType;
  final DateTime? lastSyncedAt;
  const SyncMetadataRecord({
    required this.id,
    required this.entityType,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  SyncMetadataRecordsCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataRecordsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory SyncMetadataRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataRecord(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  SyncMetadataRecord copyWith({
    String? id,
    String? entityType,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => SyncMetadataRecord(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  SyncMetadataRecord copyWithCompanion(SyncMetadataRecordsCompanion data) {
    return SyncMetadataRecord(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataRecord(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entityType, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataRecord &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class SyncMetadataRecordsCompanion extends UpdateCompanion<SyncMetadataRecord> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const SyncMetadataRecordsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataRecordsCompanion.insert({
    required String id,
    required String entityType,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType);
  static Insertable<SyncMetadataRecord> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return SyncMetadataRecordsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataRecordsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LedgerDatabase extends GeneratedDatabase {
  _$LedgerDatabase(QueryExecutor e) : super(e);
  $LedgerDatabaseManager get managers => $LedgerDatabaseManager(this);
  late final $ProfileRecordsTable profileRecords = $ProfileRecordsTable(this);
  late final $ServiceRecordsTable serviceRecords = $ServiceRecordsTable(this);
  late final $EntryRecordsTable entryRecords = $EntryRecordsTable(this);
  late final $ServiceMonthLogRecordsTable serviceMonthLogRecords =
      $ServiceMonthLogRecordsTable(this);
  late final $AdvancePaymentRecordsTable advancePaymentRecords =
      $AdvancePaymentRecordsTable(this);
  late final $PaymentTransactionRecordsTable paymentTransactionRecords =
      $PaymentTransactionRecordsTable(this);
  late final $MonthlySettlementRecordsTable monthlySettlementRecords =
      $MonthlySettlementRecordsTable(this);
  late final $SyncMetadataRecordsTable syncMetadataRecords =
      $SyncMetadataRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profileRecords,
    serviceRecords,
    entryRecords,
    serviceMonthLogRecords,
    advancePaymentRecords,
    paymentTransactionRecords,
    monthlySettlementRecords,
    syncMetadataRecords,
  ];
}

typedef $$ProfileRecordsTableCreateCompanionBuilder =
    ProfileRecordsCompanion Function({
      required String id,
      required String name,
      required String email,
      required String phone,
      Value<bool> emailVerified,
      required DateTime updatedAt,
      Value<bool> pendingSync,
      Value<int> rowid,
    });
typedef $$ProfileRecordsTableUpdateCompanionBuilder =
    ProfileRecordsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> email,
      Value<String> phone,
      Value<bool> emailVerified,
      Value<DateTime> updatedAt,
      Value<bool> pendingSync,
      Value<int> rowid,
    });

class $$ProfileRecordsTableFilterComposer
    extends Composer<_$LedgerDatabase, $ProfileRecordsTable> {
  $$ProfileRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfileRecordsTableOrderingComposer
    extends Composer<_$LedgerDatabase, $ProfileRecordsTable> {
  $$ProfileRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfileRecordsTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $ProfileRecordsTable> {
  $$ProfileRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<bool> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => column,
  );
}

class $$ProfileRecordsTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $ProfileRecordsTable,
          ProfileRecord,
          $$ProfileRecordsTableFilterComposer,
          $$ProfileRecordsTableOrderingComposer,
          $$ProfileRecordsTableAnnotationComposer,
          $$ProfileRecordsTableCreateCompanionBuilder,
          $$ProfileRecordsTableUpdateCompanionBuilder,
          (
            ProfileRecord,
            BaseReferences<
              _$LedgerDatabase,
              $ProfileRecordsTable,
              ProfileRecord
            >,
          ),
          ProfileRecord,
          PrefetchHooks Function()
        > {
  $$ProfileRecordsTableTableManager(
    _$LedgerDatabase db,
    $ProfileRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<bool> emailVerified = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfileRecordsCompanion(
                id: id,
                name: name,
                email: email,
                phone: phone,
                emailVerified: emailVerified,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String email,
                required String phone,
                Value<bool> emailVerified = const Value.absent(),
                required DateTime updatedAt,
                Value<bool> pendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfileRecordsCompanion.insert(
                id: id,
                name: name,
                email: email,
                phone: phone,
                emailVerified: emailVerified,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $ProfileRecordsTable,
      ProfileRecord,
      $$ProfileRecordsTableFilterComposer,
      $$ProfileRecordsTableOrderingComposer,
      $$ProfileRecordsTableAnnotationComposer,
      $$ProfileRecordsTableCreateCompanionBuilder,
      $$ProfileRecordsTableUpdateCompanionBuilder,
      (
        ProfileRecord,
        BaseReferences<_$LedgerDatabase, $ProfileRecordsTable, ProfileRecord>,
      ),
      ProfileRecord,
      PrefetchHooks Function()
    >;
typedef $$ServiceRecordsTableCreateCompanionBuilder =
    ServiceRecordsCompanion Function({
      required String id,
      required String userId,
      required String monthKey,
      required String name,
      required String description,
      required String icon,
      required String templateType,
      required String unit,
      Value<double> defaultQuantity,
      required int rateCents,
      Value<int> monthlyAmountCents,
      required DateTime updatedAt,
      Value<bool> pendingSync,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$ServiceRecordsTableUpdateCompanionBuilder =
    ServiceRecordsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> monthKey,
      Value<String> name,
      Value<String> description,
      Value<String> icon,
      Value<String> templateType,
      Value<String> unit,
      Value<double> defaultQuantity,
      Value<int> rateCents,
      Value<int> monthlyAmountCents,
      Value<DateTime> updatedAt,
      Value<bool> pendingSync,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$ServiceRecordsTableFilterComposer
    extends Composer<_$LedgerDatabase, $ServiceRecordsTable> {
  $$ServiceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get defaultQuantity => $composableBuilder(
    column: $table.defaultQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateCents => $composableBuilder(
    column: $table.rateCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthlyAmountCents => $composableBuilder(
    column: $table.monthlyAmountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ServiceRecordsTableOrderingComposer
    extends Composer<_$LedgerDatabase, $ServiceRecordsTable> {
  $$ServiceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get defaultQuantity => $composableBuilder(
    column: $table.defaultQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateCents => $composableBuilder(
    column: $table.rateCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthlyAmountCents => $composableBuilder(
    column: $table.monthlyAmountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServiceRecordsTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $ServiceRecordsTable> {
  $$ServiceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get defaultQuantity => $composableBuilder(
    column: $table.defaultQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rateCents =>
      $composableBuilder(column: $table.rateCents, builder: (column) => column);

  GeneratedColumn<int> get monthlyAmountCents => $composableBuilder(
    column: $table.monthlyAmountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$ServiceRecordsTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $ServiceRecordsTable,
          ServiceRecord,
          $$ServiceRecordsTableFilterComposer,
          $$ServiceRecordsTableOrderingComposer,
          $$ServiceRecordsTableAnnotationComposer,
          $$ServiceRecordsTableCreateCompanionBuilder,
          $$ServiceRecordsTableUpdateCompanionBuilder,
          (
            ServiceRecord,
            BaseReferences<
              _$LedgerDatabase,
              $ServiceRecordsTable,
              ServiceRecord
            >,
          ),
          ServiceRecord,
          PrefetchHooks Function()
        > {
  $$ServiceRecordsTableTableManager(
    _$LedgerDatabase db,
    $ServiceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServiceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServiceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServiceRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> monthKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> templateType = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> defaultQuantity = const Value.absent(),
                Value<int> rateCents = const Value.absent(),
                Value<int> monthlyAmountCents = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServiceRecordsCompanion(
                id: id,
                userId: userId,
                monthKey: monthKey,
                name: name,
                description: description,
                icon: icon,
                templateType: templateType,
                unit: unit,
                defaultQuantity: defaultQuantity,
                rateCents: rateCents,
                monthlyAmountCents: monthlyAmountCents,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String monthKey,
                required String name,
                required String description,
                required String icon,
                required String templateType,
                required String unit,
                Value<double> defaultQuantity = const Value.absent(),
                required int rateCents,
                Value<int> monthlyAmountCents = const Value.absent(),
                required DateTime updatedAt,
                Value<bool> pendingSync = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServiceRecordsCompanion.insert(
                id: id,
                userId: userId,
                monthKey: monthKey,
                name: name,
                description: description,
                icon: icon,
                templateType: templateType,
                unit: unit,
                defaultQuantity: defaultQuantity,
                rateCents: rateCents,
                monthlyAmountCents: monthlyAmountCents,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServiceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $ServiceRecordsTable,
      ServiceRecord,
      $$ServiceRecordsTableFilterComposer,
      $$ServiceRecordsTableOrderingComposer,
      $$ServiceRecordsTableAnnotationComposer,
      $$ServiceRecordsTableCreateCompanionBuilder,
      $$ServiceRecordsTableUpdateCompanionBuilder,
      (
        ServiceRecord,
        BaseReferences<_$LedgerDatabase, $ServiceRecordsTable, ServiceRecord>,
      ),
      ServiceRecord,
      PrefetchHooks Function()
    >;
typedef $$EntryRecordsTableCreateCompanionBuilder =
    EntryRecordsCompanion Function({
      required String id,
      required String serviceId,
      required String monthKey,
      required int day,
      required String status,
      Value<double> quantity,
      Value<String> unit,
      Value<int> rateCents,
      Value<int> amountCents,
      Value<String> note,
      required DateTime updatedAt,
      Value<bool> pendingSync,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$EntryRecordsTableUpdateCompanionBuilder =
    EntryRecordsCompanion Function({
      Value<String> id,
      Value<String> serviceId,
      Value<String> monthKey,
      Value<int> day,
      Value<String> status,
      Value<double> quantity,
      Value<String> unit,
      Value<int> rateCents,
      Value<int> amountCents,
      Value<String> note,
      Value<DateTime> updatedAt,
      Value<bool> pendingSync,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$EntryRecordsTableFilterComposer
    extends Composer<_$LedgerDatabase, $EntryRecordsTable> {
  $$EntryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateCents => $composableBuilder(
    column: $table.rateCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntryRecordsTableOrderingComposer
    extends Composer<_$LedgerDatabase, $EntryRecordsTable> {
  $$EntryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateCents => $composableBuilder(
    column: $table.rateCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntryRecordsTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $EntryRecordsTable> {
  $$EntryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get rateCents =>
      $composableBuilder(column: $table.rateCents, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$EntryRecordsTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $EntryRecordsTable,
          EntryRecord,
          $$EntryRecordsTableFilterComposer,
          $$EntryRecordsTableOrderingComposer,
          $$EntryRecordsTableAnnotationComposer,
          $$EntryRecordsTableCreateCompanionBuilder,
          $$EntryRecordsTableUpdateCompanionBuilder,
          (
            EntryRecord,
            BaseReferences<_$LedgerDatabase, $EntryRecordsTable, EntryRecord>,
          ),
          EntryRecord,
          PrefetchHooks Function()
        > {
  $$EntryRecordsTableTableManager(_$LedgerDatabase db, $EntryRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> serviceId = const Value.absent(),
                Value<String> monthKey = const Value.absent(),
                Value<int> day = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> rateCents = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryRecordsCompanion(
                id: id,
                serviceId: serviceId,
                monthKey: monthKey,
                day: day,
                status: status,
                quantity: quantity,
                unit: unit,
                rateCents: rateCents,
                amountCents: amountCents,
                note: note,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String serviceId,
                required String monthKey,
                required int day,
                required String status,
                Value<double> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> rateCents = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String> note = const Value.absent(),
                required DateTime updatedAt,
                Value<bool> pendingSync = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryRecordsCompanion.insert(
                id: id,
                serviceId: serviceId,
                monthKey: monthKey,
                day: day,
                status: status,
                quantity: quantity,
                unit: unit,
                rateCents: rateCents,
                amountCents: amountCents,
                note: note,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $EntryRecordsTable,
      EntryRecord,
      $$EntryRecordsTableFilterComposer,
      $$EntryRecordsTableOrderingComposer,
      $$EntryRecordsTableAnnotationComposer,
      $$EntryRecordsTableCreateCompanionBuilder,
      $$EntryRecordsTableUpdateCompanionBuilder,
      (
        EntryRecord,
        BaseReferences<_$LedgerDatabase, $EntryRecordsTable, EntryRecord>,
      ),
      EntryRecord,
      PrefetchHooks Function()
    >;
typedef $$ServiceMonthLogRecordsTableCreateCompanionBuilder =
    ServiceMonthLogRecordsCompanion Function({
      required String id,
      required String serviceId,
      required String monthKey,
      Value<int> schemaVersion,
      Value<String> entriesJson,
      required DateTime updatedAt,
      Value<bool> pendingSync,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$ServiceMonthLogRecordsTableUpdateCompanionBuilder =
    ServiceMonthLogRecordsCompanion Function({
      Value<String> id,
      Value<String> serviceId,
      Value<String> monthKey,
      Value<int> schemaVersion,
      Value<String> entriesJson,
      Value<DateTime> updatedAt,
      Value<bool> pendingSync,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$ServiceMonthLogRecordsTableFilterComposer
    extends Composer<_$LedgerDatabase, $ServiceMonthLogRecordsTable> {
  $$ServiceMonthLogRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entriesJson => $composableBuilder(
    column: $table.entriesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ServiceMonthLogRecordsTableOrderingComposer
    extends Composer<_$LedgerDatabase, $ServiceMonthLogRecordsTable> {
  $$ServiceMonthLogRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entriesJson => $composableBuilder(
    column: $table.entriesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServiceMonthLogRecordsTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $ServiceMonthLogRecordsTable> {
  $$ServiceMonthLogRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entriesJson => $composableBuilder(
    column: $table.entriesJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$ServiceMonthLogRecordsTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $ServiceMonthLogRecordsTable,
          ServiceMonthLogRecord,
          $$ServiceMonthLogRecordsTableFilterComposer,
          $$ServiceMonthLogRecordsTableOrderingComposer,
          $$ServiceMonthLogRecordsTableAnnotationComposer,
          $$ServiceMonthLogRecordsTableCreateCompanionBuilder,
          $$ServiceMonthLogRecordsTableUpdateCompanionBuilder,
          (
            ServiceMonthLogRecord,
            BaseReferences<
              _$LedgerDatabase,
              $ServiceMonthLogRecordsTable,
              ServiceMonthLogRecord
            >,
          ),
          ServiceMonthLogRecord,
          PrefetchHooks Function()
        > {
  $$ServiceMonthLogRecordsTableTableManager(
    _$LedgerDatabase db,
    $ServiceMonthLogRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServiceMonthLogRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ServiceMonthLogRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ServiceMonthLogRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> serviceId = const Value.absent(),
                Value<String> monthKey = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String> entriesJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServiceMonthLogRecordsCompanion(
                id: id,
                serviceId: serviceId,
                monthKey: monthKey,
                schemaVersion: schemaVersion,
                entriesJson: entriesJson,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String serviceId,
                required String monthKey,
                Value<int> schemaVersion = const Value.absent(),
                Value<String> entriesJson = const Value.absent(),
                required DateTime updatedAt,
                Value<bool> pendingSync = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServiceMonthLogRecordsCompanion.insert(
                id: id,
                serviceId: serviceId,
                monthKey: monthKey,
                schemaVersion: schemaVersion,
                entriesJson: entriesJson,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServiceMonthLogRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $ServiceMonthLogRecordsTable,
      ServiceMonthLogRecord,
      $$ServiceMonthLogRecordsTableFilterComposer,
      $$ServiceMonthLogRecordsTableOrderingComposer,
      $$ServiceMonthLogRecordsTableAnnotationComposer,
      $$ServiceMonthLogRecordsTableCreateCompanionBuilder,
      $$ServiceMonthLogRecordsTableUpdateCompanionBuilder,
      (
        ServiceMonthLogRecord,
        BaseReferences<
          _$LedgerDatabase,
          $ServiceMonthLogRecordsTable,
          ServiceMonthLogRecord
        >,
      ),
      ServiceMonthLogRecord,
      PrefetchHooks Function()
    >;
typedef $$AdvancePaymentRecordsTableCreateCompanionBuilder =
    AdvancePaymentRecordsCompanion Function({
      required String id,
      required String serviceId,
      required String monthKey,
      required int amountCents,
      required DateTime paidOn,
      Value<String> note,
      required DateTime updatedAt,
      Value<bool> pendingSync,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$AdvancePaymentRecordsTableUpdateCompanionBuilder =
    AdvancePaymentRecordsCompanion Function({
      Value<String> id,
      Value<String> serviceId,
      Value<String> monthKey,
      Value<int> amountCents,
      Value<DateTime> paidOn,
      Value<String> note,
      Value<DateTime> updatedAt,
      Value<bool> pendingSync,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$AdvancePaymentRecordsTableFilterComposer
    extends Composer<_$LedgerDatabase, $AdvancePaymentRecordsTable> {
  $$AdvancePaymentRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidOn => $composableBuilder(
    column: $table.paidOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdvancePaymentRecordsTableOrderingComposer
    extends Composer<_$LedgerDatabase, $AdvancePaymentRecordsTable> {
  $$AdvancePaymentRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidOn => $composableBuilder(
    column: $table.paidOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdvancePaymentRecordsTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $AdvancePaymentRecordsTable> {
  $$AdvancePaymentRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get paidOn =>
      $composableBuilder(column: $table.paidOn, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$AdvancePaymentRecordsTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $AdvancePaymentRecordsTable,
          AdvancePaymentRecord,
          $$AdvancePaymentRecordsTableFilterComposer,
          $$AdvancePaymentRecordsTableOrderingComposer,
          $$AdvancePaymentRecordsTableAnnotationComposer,
          $$AdvancePaymentRecordsTableCreateCompanionBuilder,
          $$AdvancePaymentRecordsTableUpdateCompanionBuilder,
          (
            AdvancePaymentRecord,
            BaseReferences<
              _$LedgerDatabase,
              $AdvancePaymentRecordsTable,
              AdvancePaymentRecord
            >,
          ),
          AdvancePaymentRecord,
          PrefetchHooks Function()
        > {
  $$AdvancePaymentRecordsTableTableManager(
    _$LedgerDatabase db,
    $AdvancePaymentRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdvancePaymentRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AdvancePaymentRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AdvancePaymentRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> serviceId = const Value.absent(),
                Value<String> monthKey = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<DateTime> paidOn = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdvancePaymentRecordsCompanion(
                id: id,
                serviceId: serviceId,
                monthKey: monthKey,
                amountCents: amountCents,
                paidOn: paidOn,
                note: note,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String serviceId,
                required String monthKey,
                required int amountCents,
                required DateTime paidOn,
                Value<String> note = const Value.absent(),
                required DateTime updatedAt,
                Value<bool> pendingSync = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdvancePaymentRecordsCompanion.insert(
                id: id,
                serviceId: serviceId,
                monthKey: monthKey,
                amountCents: amountCents,
                paidOn: paidOn,
                note: note,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdvancePaymentRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $AdvancePaymentRecordsTable,
      AdvancePaymentRecord,
      $$AdvancePaymentRecordsTableFilterComposer,
      $$AdvancePaymentRecordsTableOrderingComposer,
      $$AdvancePaymentRecordsTableAnnotationComposer,
      $$AdvancePaymentRecordsTableCreateCompanionBuilder,
      $$AdvancePaymentRecordsTableUpdateCompanionBuilder,
      (
        AdvancePaymentRecord,
        BaseReferences<
          _$LedgerDatabase,
          $AdvancePaymentRecordsTable,
          AdvancePaymentRecord
        >,
      ),
      AdvancePaymentRecord,
      PrefetchHooks Function()
    >;
typedef $$PaymentTransactionRecordsTableCreateCompanionBuilder =
    PaymentTransactionRecordsCompanion Function({
      required String id,
      required String userId,
      required String serviceId,
      required String monthKey,
      required int amountCents,
      required DateTime paymentDate,
      required String paymentMode,
      Value<String> note,
      Value<int> currentMonthAmountCents,
      Value<int> previousBalanceAmountCents,
      Value<int> advanceAmountCents,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> pendingSync,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$PaymentTransactionRecordsTableUpdateCompanionBuilder =
    PaymentTransactionRecordsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> serviceId,
      Value<String> monthKey,
      Value<int> amountCents,
      Value<DateTime> paymentDate,
      Value<String> paymentMode,
      Value<String> note,
      Value<int> currentMonthAmountCents,
      Value<int> previousBalanceAmountCents,
      Value<int> advanceAmountCents,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pendingSync,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$PaymentTransactionRecordsTableFilterComposer
    extends Composer<_$LedgerDatabase, $PaymentTransactionRecordsTable> {
  $$PaymentTransactionRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentMonthAmountCents => $composableBuilder(
    column: $table.currentMonthAmountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get previousBalanceAmountCents => $composableBuilder(
    column: $table.previousBalanceAmountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get advanceAmountCents => $composableBuilder(
    column: $table.advanceAmountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaymentTransactionRecordsTableOrderingComposer
    extends Composer<_$LedgerDatabase, $PaymentTransactionRecordsTable> {
  $$PaymentTransactionRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentMonthAmountCents => $composableBuilder(
    column: $table.currentMonthAmountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get previousBalanceAmountCents => $composableBuilder(
    column: $table.previousBalanceAmountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get advanceAmountCents => $composableBuilder(
    column: $table.advanceAmountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaymentTransactionRecordsTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $PaymentTransactionRecordsTable> {
  $$PaymentTransactionRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get currentMonthAmountCents => $composableBuilder(
    column: $table.currentMonthAmountCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get previousBalanceAmountCents => $composableBuilder(
    column: $table.previousBalanceAmountCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get advanceAmountCents => $composableBuilder(
    column: $table.advanceAmountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$PaymentTransactionRecordsTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $PaymentTransactionRecordsTable,
          PaymentTransactionRecord,
          $$PaymentTransactionRecordsTableFilterComposer,
          $$PaymentTransactionRecordsTableOrderingComposer,
          $$PaymentTransactionRecordsTableAnnotationComposer,
          $$PaymentTransactionRecordsTableCreateCompanionBuilder,
          $$PaymentTransactionRecordsTableUpdateCompanionBuilder,
          (
            PaymentTransactionRecord,
            BaseReferences<
              _$LedgerDatabase,
              $PaymentTransactionRecordsTable,
              PaymentTransactionRecord
            >,
          ),
          PaymentTransactionRecord,
          PrefetchHooks Function()
        > {
  $$PaymentTransactionRecordsTableTableManager(
    _$LedgerDatabase db,
    $PaymentTransactionRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentTransactionRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PaymentTransactionRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PaymentTransactionRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> serviceId = const Value.absent(),
                Value<String> monthKey = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<DateTime> paymentDate = const Value.absent(),
                Value<String> paymentMode = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> currentMonthAmountCents = const Value.absent(),
                Value<int> previousBalanceAmountCents = const Value.absent(),
                Value<int> advanceAmountCents = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentTransactionRecordsCompanion(
                id: id,
                userId: userId,
                serviceId: serviceId,
                monthKey: monthKey,
                amountCents: amountCents,
                paymentDate: paymentDate,
                paymentMode: paymentMode,
                note: note,
                currentMonthAmountCents: currentMonthAmountCents,
                previousBalanceAmountCents: previousBalanceAmountCents,
                advanceAmountCents: advanceAmountCents,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String serviceId,
                required String monthKey,
                required int amountCents,
                required DateTime paymentDate,
                required String paymentMode,
                Value<String> note = const Value.absent(),
                Value<int> currentMonthAmountCents = const Value.absent(),
                Value<int> previousBalanceAmountCents = const Value.absent(),
                Value<int> advanceAmountCents = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> pendingSync = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentTransactionRecordsCompanion.insert(
                id: id,
                userId: userId,
                serviceId: serviceId,
                monthKey: monthKey,
                amountCents: amountCents,
                paymentDate: paymentDate,
                paymentMode: paymentMode,
                note: note,
                currentMonthAmountCents: currentMonthAmountCents,
                previousBalanceAmountCents: previousBalanceAmountCents,
                advanceAmountCents: advanceAmountCents,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaymentTransactionRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $PaymentTransactionRecordsTable,
      PaymentTransactionRecord,
      $$PaymentTransactionRecordsTableFilterComposer,
      $$PaymentTransactionRecordsTableOrderingComposer,
      $$PaymentTransactionRecordsTableAnnotationComposer,
      $$PaymentTransactionRecordsTableCreateCompanionBuilder,
      $$PaymentTransactionRecordsTableUpdateCompanionBuilder,
      (
        PaymentTransactionRecord,
        BaseReferences<
          _$LedgerDatabase,
          $PaymentTransactionRecordsTable,
          PaymentTransactionRecord
        >,
      ),
      PaymentTransactionRecord,
      PrefetchHooks Function()
    >;
typedef $$MonthlySettlementRecordsTableCreateCompanionBuilder =
    MonthlySettlementRecordsCompanion Function({
      required String id,
      required String userId,
      required String serviceId,
      required String monthKey,
      Value<int> grossAmountCents,
      Value<int> advanceUsedCents,
      Value<int> previousCarryForwardCents,
      Value<int> previousAdvanceCents,
      Value<int> payableAmountCents,
      Value<int> paidAmountCents,
      Value<int> remainingAmountCents,
      Value<int> carryForwardToNextMonthCents,
      Value<int> advanceToNextMonthCents,
      required String status,
      required DateTime generatedAt,
      required DateTime updatedAt,
      Value<bool> pendingSync,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$MonthlySettlementRecordsTableUpdateCompanionBuilder =
    MonthlySettlementRecordsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> serviceId,
      Value<String> monthKey,
      Value<int> grossAmountCents,
      Value<int> advanceUsedCents,
      Value<int> previousCarryForwardCents,
      Value<int> previousAdvanceCents,
      Value<int> payableAmountCents,
      Value<int> paidAmountCents,
      Value<int> remainingAmountCents,
      Value<int> carryForwardToNextMonthCents,
      Value<int> advanceToNextMonthCents,
      Value<String> status,
      Value<DateTime> generatedAt,
      Value<DateTime> updatedAt,
      Value<bool> pendingSync,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$MonthlySettlementRecordsTableFilterComposer
    extends Composer<_$LedgerDatabase, $MonthlySettlementRecordsTable> {
  $$MonthlySettlementRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grossAmountCents => $composableBuilder(
    column: $table.grossAmountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get advanceUsedCents => $composableBuilder(
    column: $table.advanceUsedCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get previousCarryForwardCents => $composableBuilder(
    column: $table.previousCarryForwardCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get previousAdvanceCents => $composableBuilder(
    column: $table.previousAdvanceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payableAmountCents => $composableBuilder(
    column: $table.payableAmountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidAmountCents => $composableBuilder(
    column: $table.paidAmountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remainingAmountCents => $composableBuilder(
    column: $table.remainingAmountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carryForwardToNextMonthCents => $composableBuilder(
    column: $table.carryForwardToNextMonthCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get advanceToNextMonthCents => $composableBuilder(
    column: $table.advanceToNextMonthCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MonthlySettlementRecordsTableOrderingComposer
    extends Composer<_$LedgerDatabase, $MonthlySettlementRecordsTable> {
  $$MonthlySettlementRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grossAmountCents => $composableBuilder(
    column: $table.grossAmountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get advanceUsedCents => $composableBuilder(
    column: $table.advanceUsedCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get previousCarryForwardCents => $composableBuilder(
    column: $table.previousCarryForwardCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get previousAdvanceCents => $composableBuilder(
    column: $table.previousAdvanceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payableAmountCents => $composableBuilder(
    column: $table.payableAmountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidAmountCents => $composableBuilder(
    column: $table.paidAmountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remainingAmountCents => $composableBuilder(
    column: $table.remainingAmountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carryForwardToNextMonthCents => $composableBuilder(
    column: $table.carryForwardToNextMonthCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get advanceToNextMonthCents => $composableBuilder(
    column: $table.advanceToNextMonthCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MonthlySettlementRecordsTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $MonthlySettlementRecordsTable> {
  $$MonthlySettlementRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<int> get grossAmountCents => $composableBuilder(
    column: $table.grossAmountCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get advanceUsedCents => $composableBuilder(
    column: $table.advanceUsedCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get previousCarryForwardCents => $composableBuilder(
    column: $table.previousCarryForwardCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get previousAdvanceCents => $composableBuilder(
    column: $table.previousAdvanceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get payableAmountCents => $composableBuilder(
    column: $table.payableAmountCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paidAmountCents => $composableBuilder(
    column: $table.paidAmountCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remainingAmountCents => $composableBuilder(
    column: $table.remainingAmountCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get carryForwardToNextMonthCents => $composableBuilder(
    column: $table.carryForwardToNextMonthCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get advanceToNextMonthCents => $composableBuilder(
    column: $table.advanceToNextMonthCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$MonthlySettlementRecordsTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $MonthlySettlementRecordsTable,
          MonthlySettlementRecord,
          $$MonthlySettlementRecordsTableFilterComposer,
          $$MonthlySettlementRecordsTableOrderingComposer,
          $$MonthlySettlementRecordsTableAnnotationComposer,
          $$MonthlySettlementRecordsTableCreateCompanionBuilder,
          $$MonthlySettlementRecordsTableUpdateCompanionBuilder,
          (
            MonthlySettlementRecord,
            BaseReferences<
              _$LedgerDatabase,
              $MonthlySettlementRecordsTable,
              MonthlySettlementRecord
            >,
          ),
          MonthlySettlementRecord,
          PrefetchHooks Function()
        > {
  $$MonthlySettlementRecordsTableTableManager(
    _$LedgerDatabase db,
    $MonthlySettlementRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthlySettlementRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MonthlySettlementRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MonthlySettlementRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> serviceId = const Value.absent(),
                Value<String> monthKey = const Value.absent(),
                Value<int> grossAmountCents = const Value.absent(),
                Value<int> advanceUsedCents = const Value.absent(),
                Value<int> previousCarryForwardCents = const Value.absent(),
                Value<int> previousAdvanceCents = const Value.absent(),
                Value<int> payableAmountCents = const Value.absent(),
                Value<int> paidAmountCents = const Value.absent(),
                Value<int> remainingAmountCents = const Value.absent(),
                Value<int> carryForwardToNextMonthCents = const Value.absent(),
                Value<int> advanceToNextMonthCents = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> generatedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthlySettlementRecordsCompanion(
                id: id,
                userId: userId,
                serviceId: serviceId,
                monthKey: monthKey,
                grossAmountCents: grossAmountCents,
                advanceUsedCents: advanceUsedCents,
                previousCarryForwardCents: previousCarryForwardCents,
                previousAdvanceCents: previousAdvanceCents,
                payableAmountCents: payableAmountCents,
                paidAmountCents: paidAmountCents,
                remainingAmountCents: remainingAmountCents,
                carryForwardToNextMonthCents: carryForwardToNextMonthCents,
                advanceToNextMonthCents: advanceToNextMonthCents,
                status: status,
                generatedAt: generatedAt,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String serviceId,
                required String monthKey,
                Value<int> grossAmountCents = const Value.absent(),
                Value<int> advanceUsedCents = const Value.absent(),
                Value<int> previousCarryForwardCents = const Value.absent(),
                Value<int> previousAdvanceCents = const Value.absent(),
                Value<int> payableAmountCents = const Value.absent(),
                Value<int> paidAmountCents = const Value.absent(),
                Value<int> remainingAmountCents = const Value.absent(),
                Value<int> carryForwardToNextMonthCents = const Value.absent(),
                Value<int> advanceToNextMonthCents = const Value.absent(),
                required String status,
                required DateTime generatedAt,
                required DateTime updatedAt,
                Value<bool> pendingSync = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthlySettlementRecordsCompanion.insert(
                id: id,
                userId: userId,
                serviceId: serviceId,
                monthKey: monthKey,
                grossAmountCents: grossAmountCents,
                advanceUsedCents: advanceUsedCents,
                previousCarryForwardCents: previousCarryForwardCents,
                previousAdvanceCents: previousAdvanceCents,
                payableAmountCents: payableAmountCents,
                paidAmountCents: paidAmountCents,
                remainingAmountCents: remainingAmountCents,
                carryForwardToNextMonthCents: carryForwardToNextMonthCents,
                advanceToNextMonthCents: advanceToNextMonthCents,
                status: status,
                generatedAt: generatedAt,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MonthlySettlementRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $MonthlySettlementRecordsTable,
      MonthlySettlementRecord,
      $$MonthlySettlementRecordsTableFilterComposer,
      $$MonthlySettlementRecordsTableOrderingComposer,
      $$MonthlySettlementRecordsTableAnnotationComposer,
      $$MonthlySettlementRecordsTableCreateCompanionBuilder,
      $$MonthlySettlementRecordsTableUpdateCompanionBuilder,
      (
        MonthlySettlementRecord,
        BaseReferences<
          _$LedgerDatabase,
          $MonthlySettlementRecordsTable,
          MonthlySettlementRecord
        >,
      ),
      MonthlySettlementRecord,
      PrefetchHooks Function()
    >;
typedef $$SyncMetadataRecordsTableCreateCompanionBuilder =
    SyncMetadataRecordsCompanion Function({
      required String id,
      required String entityType,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$SyncMetadataRecordsTableUpdateCompanionBuilder =
    SyncMetadataRecordsCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$SyncMetadataRecordsTableFilterComposer
    extends Composer<_$LedgerDatabase, $SyncMetadataRecordsTable> {
  $$SyncMetadataRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetadataRecordsTableOrderingComposer
    extends Composer<_$LedgerDatabase, $SyncMetadataRecordsTable> {
  $$SyncMetadataRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataRecordsTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $SyncMetadataRecordsTable> {
  $$SyncMetadataRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$SyncMetadataRecordsTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $SyncMetadataRecordsTable,
          SyncMetadataRecord,
          $$SyncMetadataRecordsTableFilterComposer,
          $$SyncMetadataRecordsTableOrderingComposer,
          $$SyncMetadataRecordsTableAnnotationComposer,
          $$SyncMetadataRecordsTableCreateCompanionBuilder,
          $$SyncMetadataRecordsTableUpdateCompanionBuilder,
          (
            SyncMetadataRecord,
            BaseReferences<
              _$LedgerDatabase,
              $SyncMetadataRecordsTable,
              SyncMetadataRecord
            >,
          ),
          SyncMetadataRecord,
          PrefetchHooks Function()
        > {
  $$SyncMetadataRecordsTableTableManager(
    _$LedgerDatabase db,
    $SyncMetadataRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SyncMetadataRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataRecordsCompanion(
                id: id,
                entityType: entityType,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataRecordsCompanion.insert(
                id: id,
                entityType: entityType,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $SyncMetadataRecordsTable,
      SyncMetadataRecord,
      $$SyncMetadataRecordsTableFilterComposer,
      $$SyncMetadataRecordsTableOrderingComposer,
      $$SyncMetadataRecordsTableAnnotationComposer,
      $$SyncMetadataRecordsTableCreateCompanionBuilder,
      $$SyncMetadataRecordsTableUpdateCompanionBuilder,
      (
        SyncMetadataRecord,
        BaseReferences<
          _$LedgerDatabase,
          $SyncMetadataRecordsTable,
          SyncMetadataRecord
        >,
      ),
      SyncMetadataRecord,
      PrefetchHooks Function()
    >;

class $LedgerDatabaseManager {
  final _$LedgerDatabase _db;
  $LedgerDatabaseManager(this._db);
  $$ProfileRecordsTableTableManager get profileRecords =>
      $$ProfileRecordsTableTableManager(_db, _db.profileRecords);
  $$ServiceRecordsTableTableManager get serviceRecords =>
      $$ServiceRecordsTableTableManager(_db, _db.serviceRecords);
  $$EntryRecordsTableTableManager get entryRecords =>
      $$EntryRecordsTableTableManager(_db, _db.entryRecords);
  $$ServiceMonthLogRecordsTableTableManager get serviceMonthLogRecords =>
      $$ServiceMonthLogRecordsTableTableManager(
        _db,
        _db.serviceMonthLogRecords,
      );
  $$AdvancePaymentRecordsTableTableManager get advancePaymentRecords =>
      $$AdvancePaymentRecordsTableTableManager(_db, _db.advancePaymentRecords);
  $$PaymentTransactionRecordsTableTableManager get paymentTransactionRecords =>
      $$PaymentTransactionRecordsTableTableManager(
        _db,
        _db.paymentTransactionRecords,
      );
  $$MonthlySettlementRecordsTableTableManager get monthlySettlementRecords =>
      $$MonthlySettlementRecordsTableTableManager(
        _db,
        _db.monthlySettlementRecords,
      );
  $$SyncMetadataRecordsTableTableManager get syncMetadataRecords =>
      $$SyncMetadataRecordsTableTableManager(_db, _db.syncMetadataRecords);
}
