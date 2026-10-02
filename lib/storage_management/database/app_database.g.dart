// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ExpenseItemRowsTable extends ExpenseItemRows
    with TableInfo<$ExpenseItemRowsTable, ExpenseItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseItemRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentDueDateMeta = const VerificationMeta(
    'currentDueDate',
  );
  @override
  late final GeneratedColumn<DateTime> currentDueDate =
      GeneratedColumn<DateTime>(
        'current_due_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<int> frequency = GeneratedColumn<int>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FrequencyUnit, String>
  frequencyUnits =
      GeneratedColumn<String>(
        'frequency_units',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FrequencyUnit>(
        $ExpenseItemRowsTable.$converterfrequencyUnits,
      );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(otherCategory),
  );
  static const VerificationMeta _isCreditMeta = const VerificationMeta(
    'isCredit',
  );
  @override
  late final GeneratedColumn<bool> isCredit = GeneratedColumn<bool>(
    'is_credit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_credit" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<double> creditLimit = GeneratedColumn<double>(
    'credit_limit',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amount,
    startDate,
    currentDueDate,
    endDate,
    frequency,
    frequencyUnits,
    category,
    isCredit,
    creditLimit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_item_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('current_due_date')) {
      context.handle(
        _currentDueDateMeta,
        currentDueDate.isAcceptableOrUnknown(
          data['current_due_date']!,
          _currentDueDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentDueDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('is_credit')) {
      context.handle(
        _isCreditMeta,
        isCredit.isAcceptableOrUnknown(data['is_credit']!, _isCreditMeta),
      );
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      currentDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}current_due_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}frequency'],
      )!,
      frequencyUnits: $ExpenseItemRowsTable.$converterfrequencyUnits.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}frequency_units'],
        )!,
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      isCredit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_credit'],
      )!,
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}credit_limit'],
      ),
    );
  }

  @override
  $ExpenseItemRowsTable createAlias(String alias) {
    return $ExpenseItemRowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FrequencyUnit, String, String>
  $converterfrequencyUnits = const EnumNameConverter<FrequencyUnit>(
    FrequencyUnit.values,
  );
}

class ExpenseItemRow extends DataClass implements Insertable<ExpenseItemRow> {
  final int id;
  final String name;
  final double amount;
  final DateTime startDate;
  final DateTime currentDueDate;
  final DateTime? endDate;
  final int frequency;
  final FrequencyUnit frequencyUnits;
  final String category;
  final bool isCredit;
  final double? creditLimit;
  const ExpenseItemRow({
    required this.id,
    required this.name,
    required this.amount,
    required this.startDate,
    required this.currentDueDate,
    this.endDate,
    required this.frequency,
    required this.frequencyUnits,
    required this.category,
    required this.isCredit,
    this.creditLimit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    map['start_date'] = Variable<DateTime>(startDate);
    map['current_due_date'] = Variable<DateTime>(currentDueDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['frequency'] = Variable<int>(frequency);
    {
      map['frequency_units'] = Variable<String>(
        $ExpenseItemRowsTable.$converterfrequencyUnits.toSql(frequencyUnits),
      );
    }
    map['category'] = Variable<String>(category);
    map['is_credit'] = Variable<bool>(isCredit);
    if (!nullToAbsent || creditLimit != null) {
      map['credit_limit'] = Variable<double>(creditLimit);
    }
    return map;
  }

  ExpenseItemRowsCompanion toCompanion(bool nullToAbsent) {
    return ExpenseItemRowsCompanion(
      id: Value(id),
      name: Value(name),
      amount: Value(amount),
      startDate: Value(startDate),
      currentDueDate: Value(currentDueDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      frequency: Value(frequency),
      frequencyUnits: Value(frequencyUnits),
      category: Value(category),
      isCredit: Value(isCredit),
      creditLimit: creditLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimit),
    );
  }

  factory ExpenseItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseItemRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      currentDueDate: serializer.fromJson<DateTime>(json['currentDueDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      frequency: serializer.fromJson<int>(json['frequency']),
      frequencyUnits: $ExpenseItemRowsTable.$converterfrequencyUnits.fromJson(
        serializer.fromJson<String>(json['frequencyUnits']),
      ),
      category: serializer.fromJson<String>(json['category']),
      isCredit: serializer.fromJson<bool>(json['isCredit']),
      creditLimit: serializer.fromJson<double?>(json['creditLimit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'startDate': serializer.toJson<DateTime>(startDate),
      'currentDueDate': serializer.toJson<DateTime>(currentDueDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'frequency': serializer.toJson<int>(frequency),
      'frequencyUnits': serializer.toJson<String>(
        $ExpenseItemRowsTable.$converterfrequencyUnits.toJson(frequencyUnits),
      ),
      'category': serializer.toJson<String>(category),
      'isCredit': serializer.toJson<bool>(isCredit),
      'creditLimit': serializer.toJson<double?>(creditLimit),
    };
  }

  ExpenseItemRow copyWith({
    int? id,
    String? name,
    double? amount,
    DateTime? startDate,
    DateTime? currentDueDate,
    Value<DateTime?> endDate = const Value.absent(),
    int? frequency,
    FrequencyUnit? frequencyUnits,
    String? category,
    bool? isCredit,
    Value<double?> creditLimit = const Value.absent(),
  }) => ExpenseItemRow(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    startDate: startDate ?? this.startDate,
    currentDueDate: currentDueDate ?? this.currentDueDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    frequency: frequency ?? this.frequency,
    frequencyUnits: frequencyUnits ?? this.frequencyUnits,
    category: category ?? this.category,
    isCredit: isCredit ?? this.isCredit,
    creditLimit: creditLimit.present ? creditLimit.value : this.creditLimit,
  );
  ExpenseItemRow copyWithCompanion(ExpenseItemRowsCompanion data) {
    return ExpenseItemRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      currentDueDate: data.currentDueDate.present
          ? data.currentDueDate.value
          : this.currentDueDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      frequencyUnits: data.frequencyUnits.present
          ? data.frequencyUnits.value
          : this.frequencyUnits,
      category: data.category.present ? data.category.value : this.category,
      isCredit: data.isCredit.present ? data.isCredit.value : this.isCredit,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseItemRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('startDate: $startDate, ')
          ..write('currentDueDate: $currentDueDate, ')
          ..write('endDate: $endDate, ')
          ..write('frequency: $frequency, ')
          ..write('frequencyUnits: $frequencyUnits, ')
          ..write('category: $category, ')
          ..write('isCredit: $isCredit, ')
          ..write('creditLimit: $creditLimit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    startDate,
    currentDueDate,
    endDate,
    frequency,
    frequencyUnits,
    category,
    isCredit,
    creditLimit,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseItemRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.startDate == this.startDate &&
          other.currentDueDate == this.currentDueDate &&
          other.endDate == this.endDate &&
          other.frequency == this.frequency &&
          other.frequencyUnits == this.frequencyUnits &&
          other.category == this.category &&
          other.isCredit == this.isCredit &&
          other.creditLimit == this.creditLimit);
}

class ExpenseItemRowsCompanion extends UpdateCompanion<ExpenseItemRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> amount;
  final Value<DateTime> startDate;
  final Value<DateTime> currentDueDate;
  final Value<DateTime?> endDate;
  final Value<int> frequency;
  final Value<FrequencyUnit> frequencyUnits;
  final Value<String> category;
  final Value<bool> isCredit;
  final Value<double?> creditLimit;
  const ExpenseItemRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.startDate = const Value.absent(),
    this.currentDueDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.frequency = const Value.absent(),
    this.frequencyUnits = const Value.absent(),
    this.category = const Value.absent(),
    this.isCredit = const Value.absent(),
    this.creditLimit = const Value.absent(),
  });
  ExpenseItemRowsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double amount,
    required DateTime startDate,
    required DateTime currentDueDate,
    this.endDate = const Value.absent(),
    required int frequency,
    required FrequencyUnit frequencyUnits,
    this.category = const Value.absent(),
    this.isCredit = const Value.absent(),
    this.creditLimit = const Value.absent(),
  }) : name = Value(name),
       amount = Value(amount),
       startDate = Value(startDate),
       currentDueDate = Value(currentDueDate),
       frequency = Value(frequency),
       frequencyUnits = Value(frequencyUnits);
  static Insertable<ExpenseItemRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<DateTime>? startDate,
    Expression<DateTime>? currentDueDate,
    Expression<DateTime>? endDate,
    Expression<int>? frequency,
    Expression<String>? frequencyUnits,
    Expression<String>? category,
    Expression<bool>? isCredit,
    Expression<double>? creditLimit,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (startDate != null) 'start_date': startDate,
      if (currentDueDate != null) 'current_due_date': currentDueDate,
      if (endDate != null) 'end_date': endDate,
      if (frequency != null) 'frequency': frequency,
      if (frequencyUnits != null) 'frequency_units': frequencyUnits,
      if (category != null) 'category': category,
      if (isCredit != null) 'is_credit': isCredit,
      if (creditLimit != null) 'credit_limit': creditLimit,
    });
  }

  ExpenseItemRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? amount,
    Value<DateTime>? startDate,
    Value<DateTime>? currentDueDate,
    Value<DateTime?>? endDate,
    Value<int>? frequency,
    Value<FrequencyUnit>? frequencyUnits,
    Value<String>? category,
    Value<bool>? isCredit,
    Value<double?>? creditLimit,
  }) {
    return ExpenseItemRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      currentDueDate: currentDueDate ?? this.currentDueDate,
      endDate: endDate ?? this.endDate,
      frequency: frequency ?? this.frequency,
      frequencyUnits: frequencyUnits ?? this.frequencyUnits,
      category: category ?? this.category,
      isCredit: isCredit ?? this.isCredit,
      creditLimit: creditLimit ?? this.creditLimit,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (currentDueDate.present) {
      map['current_due_date'] = Variable<DateTime>(currentDueDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<int>(frequency.value);
    }
    if (frequencyUnits.present) {
      map['frequency_units'] = Variable<String>(
        $ExpenseItemRowsTable.$converterfrequencyUnits.toSql(
          frequencyUnits.value,
        ),
      );
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isCredit.present) {
      map['is_credit'] = Variable<bool>(isCredit.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<double>(creditLimit.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseItemRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('startDate: $startDate, ')
          ..write('currentDueDate: $currentDueDate, ')
          ..write('endDate: $endDate, ')
          ..write('frequency: $frequency, ')
          ..write('frequencyUnits: $frequencyUnits, ')
          ..write('category: $category, ')
          ..write('isCredit: $isCredit, ')
          ..write('creditLimit: $creditLimit')
          ..write(')'))
        .toString();
  }
}

class $IncomeStreamModelRowsTable extends IncomeStreamModelRows
    with TableInfo<$IncomeStreamModelRowsTable, IncomeStreamModelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncomeStreamModelRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<int> frequency = GeneratedColumn<int>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FrequencyUnit, String>
  frequencyUnits =
      GeneratedColumn<String>(
        'frequency_units',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FrequencyUnit>(
        $IncomeStreamModelRowsTable.$converterfrequencyUnits,
      );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amount,
    startDate,
    frequency,
    frequencyUnits,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'income_stream_model_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<IncomeStreamModelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IncomeStreamModelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncomeStreamModelRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}frequency'],
      )!,
      frequencyUnits: $IncomeStreamModelRowsTable.$converterfrequencyUnits
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}frequency_units'],
            )!,
          ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $IncomeStreamModelRowsTable createAlias(String alias) {
    return $IncomeStreamModelRowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FrequencyUnit, String, String>
  $converterfrequencyUnits = const EnumNameConverter<FrequencyUnit>(
    FrequencyUnit.values,
  );
}

class IncomeStreamModelRow extends DataClass
    implements Insertable<IncomeStreamModelRow> {
  final int id;
  final String name;
  final double amount;
  final DateTime startDate;
  final int frequency;
  final FrequencyUnit frequencyUnits;
  final bool isActive;
  const IncomeStreamModelRow({
    required this.id,
    required this.name,
    required this.amount,
    required this.startDate,
    required this.frequency,
    required this.frequencyUnits,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    map['start_date'] = Variable<DateTime>(startDate);
    map['frequency'] = Variable<int>(frequency);
    {
      map['frequency_units'] = Variable<String>(
        $IncomeStreamModelRowsTable.$converterfrequencyUnits.toSql(
          frequencyUnits,
        ),
      );
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  IncomeStreamModelRowsCompanion toCompanion(bool nullToAbsent) {
    return IncomeStreamModelRowsCompanion(
      id: Value(id),
      name: Value(name),
      amount: Value(amount),
      startDate: Value(startDate),
      frequency: Value(frequency),
      frequencyUnits: Value(frequencyUnits),
      isActive: Value(isActive),
    );
  }

  factory IncomeStreamModelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncomeStreamModelRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      frequency: serializer.fromJson<int>(json['frequency']),
      frequencyUnits: $IncomeStreamModelRowsTable.$converterfrequencyUnits
          .fromJson(serializer.fromJson<String>(json['frequencyUnits'])),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'startDate': serializer.toJson<DateTime>(startDate),
      'frequency': serializer.toJson<int>(frequency),
      'frequencyUnits': serializer.toJson<String>(
        $IncomeStreamModelRowsTable.$converterfrequencyUnits.toJson(
          frequencyUnits,
        ),
      ),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  IncomeStreamModelRow copyWith({
    int? id,
    String? name,
    double? amount,
    DateTime? startDate,
    int? frequency,
    FrequencyUnit? frequencyUnits,
    bool? isActive,
  }) => IncomeStreamModelRow(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    startDate: startDate ?? this.startDate,
    frequency: frequency ?? this.frequency,
    frequencyUnits: frequencyUnits ?? this.frequencyUnits,
    isActive: isActive ?? this.isActive,
  );
  IncomeStreamModelRow copyWithCompanion(IncomeStreamModelRowsCompanion data) {
    return IncomeStreamModelRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      frequencyUnits: data.frequencyUnits.present
          ? data.frequencyUnits.value
          : this.frequencyUnits,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncomeStreamModelRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('startDate: $startDate, ')
          ..write('frequency: $frequency, ')
          ..write('frequencyUnits: $frequencyUnits, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    startDate,
    frequency,
    frequencyUnits,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncomeStreamModelRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.startDate == this.startDate &&
          other.frequency == this.frequency &&
          other.frequencyUnits == this.frequencyUnits &&
          other.isActive == this.isActive);
}

class IncomeStreamModelRowsCompanion
    extends UpdateCompanion<IncomeStreamModelRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> amount;
  final Value<DateTime> startDate;
  final Value<int> frequency;
  final Value<FrequencyUnit> frequencyUnits;
  final Value<bool> isActive;
  const IncomeStreamModelRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.startDate = const Value.absent(),
    this.frequency = const Value.absent(),
    this.frequencyUnits = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  IncomeStreamModelRowsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double amount,
    required DateTime startDate,
    required int frequency,
    required FrequencyUnit frequencyUnits,
    this.isActive = const Value.absent(),
  }) : name = Value(name),
       amount = Value(amount),
       startDate = Value(startDate),
       frequency = Value(frequency),
       frequencyUnits = Value(frequencyUnits);
  static Insertable<IncomeStreamModelRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<DateTime>? startDate,
    Expression<int>? frequency,
    Expression<String>? frequencyUnits,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (startDate != null) 'start_date': startDate,
      if (frequency != null) 'frequency': frequency,
      if (frequencyUnits != null) 'frequency_units': frequencyUnits,
      if (isActive != null) 'is_active': isActive,
    });
  }

  IncomeStreamModelRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? amount,
    Value<DateTime>? startDate,
    Value<int>? frequency,
    Value<FrequencyUnit>? frequencyUnits,
    Value<bool>? isActive,
  }) {
    return IncomeStreamModelRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      frequency: frequency ?? this.frequency,
      frequencyUnits: frequencyUnits ?? this.frequencyUnits,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<int>(frequency.value);
    }
    if (frequencyUnits.present) {
      map['frequency_units'] = Variable<String>(
        $IncomeStreamModelRowsTable.$converterfrequencyUnits.toSql(
          frequencyUnits.value,
        ),
      );
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncomeStreamModelRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('startDate: $startDate, ')
          ..write('frequency: $frequency, ')
          ..write('frequencyUnits: $frequencyUnits, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $CategoryRowsTable extends CategoryRows
    with TableInfo<$CategoryRowsTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $CategoryRowsTable createAlias(String alias) {
    return $CategoryRowsTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final int id;
  final String name;
  const CategoryRow({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  CategoryRowsCompanion toCompanion(bool nullToAbsent) {
    return CategoryRowsCompanion(id: Value(id), name: Value(name));
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  CategoryRow copyWith({int? id, String? name}) =>
      CategoryRow(id: id ?? this.id, name: name ?? this.name);
  CategoryRow copyWithCompanion(CategoryRowsCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow && other.id == this.id && other.name == this.name);
}

class CategoryRowsCompanion extends UpdateCompanion<CategoryRow> {
  final Value<int> id;
  final Value<String> name;
  const CategoryRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  CategoryRowsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<CategoryRow> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  CategoryRowsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return CategoryRowsCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $AppMetaRowsTable extends AppMetaRows
    with TableInfo<$AppMetaRowsTable, AppMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (id = 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _currentBalanceMeta = const VerificationMeta(
    'currentBalance',
  );
  @override
  late final GeneratedColumn<double> currentBalance = GeneratedColumn<double>(
    'current_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
    'last_updated',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _includeNextCheckMeta = const VerificationMeta(
    'includeNextCheck',
  );
  @override
  late final GeneratedColumn<bool> includeNextCheck = GeneratedColumn<bool>(
    'include_next_check',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_next_check" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currentBalance,
    lastUpdated,
    includeNextCheck,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current_balance')) {
      context.handle(
        _currentBalanceMeta,
        currentBalance.isAcceptableOrUnknown(
          data['current_balance']!,
          _currentBalanceMeta,
        ),
      );
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedMeta);
    }
    if (data.containsKey('include_next_check')) {
      context.handle(
        _includeNextCheckMeta,
        includeNextCheck.isAcceptableOrUnknown(
          data['include_next_check']!,
          _includeNextCheckMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      currentBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_balance'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      )!,
      includeNextCheck: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_next_check'],
      )!,
    );
  }

  @override
  $AppMetaRowsTable createAlias(String alias) {
    return $AppMetaRowsTable(attachedDatabase, alias);
  }
}

class AppMetaRow extends DataClass implements Insertable<AppMetaRow> {
  final int id;
  final double currentBalance;
  final DateTime lastUpdated;
  final bool includeNextCheck;
  const AppMetaRow({
    required this.id,
    required this.currentBalance,
    required this.lastUpdated,
    required this.includeNextCheck,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['current_balance'] = Variable<double>(currentBalance);
    map['last_updated'] = Variable<DateTime>(lastUpdated);
    map['include_next_check'] = Variable<bool>(includeNextCheck);
    return map;
  }

  AppMetaRowsCompanion toCompanion(bool nullToAbsent) {
    return AppMetaRowsCompanion(
      id: Value(id),
      currentBalance: Value(currentBalance),
      lastUpdated: Value(lastUpdated),
      includeNextCheck: Value(includeNextCheck),
    );
  }

  factory AppMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaRow(
      id: serializer.fromJson<int>(json['id']),
      currentBalance: serializer.fromJson<double>(json['currentBalance']),
      lastUpdated: serializer.fromJson<DateTime>(json['lastUpdated']),
      includeNextCheck: serializer.fromJson<bool>(json['includeNextCheck']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currentBalance': serializer.toJson<double>(currentBalance),
      'lastUpdated': serializer.toJson<DateTime>(lastUpdated),
      'includeNextCheck': serializer.toJson<bool>(includeNextCheck),
    };
  }

  AppMetaRow copyWith({
    int? id,
    double? currentBalance,
    DateTime? lastUpdated,
    bool? includeNextCheck,
  }) => AppMetaRow(
    id: id ?? this.id,
    currentBalance: currentBalance ?? this.currentBalance,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    includeNextCheck: includeNextCheck ?? this.includeNextCheck,
  );
  AppMetaRow copyWithCompanion(AppMetaRowsCompanion data) {
    return AppMetaRow(
      id: data.id.present ? data.id.value : this.id,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
      includeNextCheck: data.includeNextCheck.present
          ? data.includeNextCheck.value
          : this.includeNextCheck,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRow(')
          ..write('id: $id, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('includeNextCheck: $includeNextCheck')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, currentBalance, lastUpdated, includeNextCheck);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaRow &&
          other.id == this.id &&
          other.currentBalance == this.currentBalance &&
          other.lastUpdated == this.lastUpdated &&
          other.includeNextCheck == this.includeNextCheck);
}

class AppMetaRowsCompanion extends UpdateCompanion<AppMetaRow> {
  final Value<int> id;
  final Value<double> currentBalance;
  final Value<DateTime> lastUpdated;
  final Value<bool> includeNextCheck;
  const AppMetaRowsCompanion({
    this.id = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.includeNextCheck = const Value.absent(),
  });
  AppMetaRowsCompanion.insert({
    this.id = const Value.absent(),
    this.currentBalance = const Value.absent(),
    required DateTime lastUpdated,
    this.includeNextCheck = const Value.absent(),
  }) : lastUpdated = Value(lastUpdated);
  static Insertable<AppMetaRow> custom({
    Expression<int>? id,
    Expression<double>? currentBalance,
    Expression<DateTime>? lastUpdated,
    Expression<bool>? includeNextCheck,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (includeNextCheck != null) 'include_next_check': includeNextCheck,
    });
  }

  AppMetaRowsCompanion copyWith({
    Value<int>? id,
    Value<double>? currentBalance,
    Value<DateTime>? lastUpdated,
    Value<bool>? includeNextCheck,
  }) {
    return AppMetaRowsCompanion(
      id: id ?? this.id,
      currentBalance: currentBalance ?? this.currentBalance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      includeNextCheck: includeNextCheck ?? this.includeNextCheck,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<double>(currentBalance.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (includeNextCheck.present) {
      map['include_next_check'] = Variable<bool>(includeNextCheck.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRowsCompanion(')
          ..write('id: $id, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('includeNextCheck: $includeNextCheck')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExpenseItemRowsTable expenseItemRows = $ExpenseItemRowsTable(
    this,
  );
  late final $IncomeStreamModelRowsTable incomeStreamModelRows =
      $IncomeStreamModelRowsTable(this);
  late final $CategoryRowsTable categoryRows = $CategoryRowsTable(this);
  late final $AppMetaRowsTable appMetaRows = $AppMetaRowsTable(this);
  late final ExpensesDao expensesDao = ExpensesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    expenseItemRows,
    incomeStreamModelRows,
    categoryRows,
    appMetaRows,
  ];
}

typedef $$ExpenseItemRowsTableCreateCompanionBuilder =
    ExpenseItemRowsCompanion Function({
      Value<int> id,
      required String name,
      required double amount,
      required DateTime startDate,
      required DateTime currentDueDate,
      Value<DateTime?> endDate,
      required int frequency,
      required FrequencyUnit frequencyUnits,
      Value<String> category,
      Value<bool> isCredit,
      Value<double?> creditLimit,
    });
typedef $$ExpenseItemRowsTableUpdateCompanionBuilder =
    ExpenseItemRowsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> amount,
      Value<DateTime> startDate,
      Value<DateTime> currentDueDate,
      Value<DateTime?> endDate,
      Value<int> frequency,
      Value<FrequencyUnit> frequencyUnits,
      Value<String> category,
      Value<bool> isCredit,
      Value<double?> creditLimit,
    });

class $$ExpenseItemRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ExpenseItemRowsTable> {
  $$ExpenseItemRowsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get currentDueDate => $composableBuilder(
    column: $table.currentDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FrequencyUnit, FrequencyUnit, String>
  get frequencyUnits => $composableBuilder(
    column: $table.frequencyUnits,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCredit => $composableBuilder(
    column: $table.isCredit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpenseItemRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpenseItemRowsTable> {
  $$ExpenseItemRowsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get currentDueDate => $composableBuilder(
    column: $table.currentDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequencyUnits => $composableBuilder(
    column: $table.frequencyUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCredit => $composableBuilder(
    column: $table.isCredit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpenseItemRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpenseItemRowsTable> {
  $$ExpenseItemRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get currentDueDate => $composableBuilder(
    column: $table.currentDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FrequencyUnit, String> get frequencyUnits =>
      $composableBuilder(
        column: $table.frequencyUnits,
        builder: (column) => column,
      );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isCredit =>
      $composableBuilder(column: $table.isCredit, builder: (column) => column);

  GeneratedColumn<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );
}

class $$ExpenseItemRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpenseItemRowsTable,
          ExpenseItemRow,
          $$ExpenseItemRowsTableFilterComposer,
          $$ExpenseItemRowsTableOrderingComposer,
          $$ExpenseItemRowsTableAnnotationComposer,
          $$ExpenseItemRowsTableCreateCompanionBuilder,
          $$ExpenseItemRowsTableUpdateCompanionBuilder,
          (
            ExpenseItemRow,
            BaseReferences<
              _$AppDatabase,
              $ExpenseItemRowsTable,
              ExpenseItemRow
            >,
          ),
          ExpenseItemRow,
          PrefetchHooks Function()
        > {
  $$ExpenseItemRowsTableTableManager(
    _$AppDatabase db,
    $ExpenseItemRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseItemRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseItemRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseItemRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> currentDueDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<int> frequency = const Value.absent(),
                Value<FrequencyUnit> frequencyUnits = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> isCredit = const Value.absent(),
                Value<double?> creditLimit = const Value.absent(),
              }) => ExpenseItemRowsCompanion(
                id: id,
                name: name,
                amount: amount,
                startDate: startDate,
                currentDueDate: currentDueDate,
                endDate: endDate,
                frequency: frequency,
                frequencyUnits: frequencyUnits,
                category: category,
                isCredit: isCredit,
                creditLimit: creditLimit,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double amount,
                required DateTime startDate,
                required DateTime currentDueDate,
                Value<DateTime?> endDate = const Value.absent(),
                required int frequency,
                required FrequencyUnit frequencyUnits,
                Value<String> category = const Value.absent(),
                Value<bool> isCredit = const Value.absent(),
                Value<double?> creditLimit = const Value.absent(),
              }) => ExpenseItemRowsCompanion.insert(
                id: id,
                name: name,
                amount: amount,
                startDate: startDate,
                currentDueDate: currentDueDate,
                endDate: endDate,
                frequency: frequency,
                frequencyUnits: frequencyUnits,
                category: category,
                isCredit: isCredit,
                creditLimit: creditLimit,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpenseItemRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpenseItemRowsTable,
      ExpenseItemRow,
      $$ExpenseItemRowsTableFilterComposer,
      $$ExpenseItemRowsTableOrderingComposer,
      $$ExpenseItemRowsTableAnnotationComposer,
      $$ExpenseItemRowsTableCreateCompanionBuilder,
      $$ExpenseItemRowsTableUpdateCompanionBuilder,
      (
        ExpenseItemRow,
        BaseReferences<_$AppDatabase, $ExpenseItemRowsTable, ExpenseItemRow>,
      ),
      ExpenseItemRow,
      PrefetchHooks Function()
    >;
typedef $$IncomeStreamModelRowsTableCreateCompanionBuilder =
    IncomeStreamModelRowsCompanion Function({
      Value<int> id,
      required String name,
      required double amount,
      required DateTime startDate,
      required int frequency,
      required FrequencyUnit frequencyUnits,
      Value<bool> isActive,
    });
typedef $$IncomeStreamModelRowsTableUpdateCompanionBuilder =
    IncomeStreamModelRowsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> amount,
      Value<DateTime> startDate,
      Value<int> frequency,
      Value<FrequencyUnit> frequencyUnits,
      Value<bool> isActive,
    });

class $$IncomeStreamModelRowsTableFilterComposer
    extends Composer<_$AppDatabase, $IncomeStreamModelRowsTable> {
  $$IncomeStreamModelRowsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FrequencyUnit, FrequencyUnit, String>
  get frequencyUnits => $composableBuilder(
    column: $table.frequencyUnits,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IncomeStreamModelRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $IncomeStreamModelRowsTable> {
  $$IncomeStreamModelRowsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequencyUnits => $composableBuilder(
    column: $table.frequencyUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IncomeStreamModelRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncomeStreamModelRowsTable> {
  $$IncomeStreamModelRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FrequencyUnit, String> get frequencyUnits =>
      $composableBuilder(
        column: $table.frequencyUnits,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$IncomeStreamModelRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncomeStreamModelRowsTable,
          IncomeStreamModelRow,
          $$IncomeStreamModelRowsTableFilterComposer,
          $$IncomeStreamModelRowsTableOrderingComposer,
          $$IncomeStreamModelRowsTableAnnotationComposer,
          $$IncomeStreamModelRowsTableCreateCompanionBuilder,
          $$IncomeStreamModelRowsTableUpdateCompanionBuilder,
          (
            IncomeStreamModelRow,
            BaseReferences<
              _$AppDatabase,
              $IncomeStreamModelRowsTable,
              IncomeStreamModelRow
            >,
          ),
          IncomeStreamModelRow,
          PrefetchHooks Function()
        > {
  $$IncomeStreamModelRowsTableTableManager(
    _$AppDatabase db,
    $IncomeStreamModelRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncomeStreamModelRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$IncomeStreamModelRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$IncomeStreamModelRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<int> frequency = const Value.absent(),
                Value<FrequencyUnit> frequencyUnits = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => IncomeStreamModelRowsCompanion(
                id: id,
                name: name,
                amount: amount,
                startDate: startDate,
                frequency: frequency,
                frequencyUnits: frequencyUnits,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double amount,
                required DateTime startDate,
                required int frequency,
                required FrequencyUnit frequencyUnits,
                Value<bool> isActive = const Value.absent(),
              }) => IncomeStreamModelRowsCompanion.insert(
                id: id,
                name: name,
                amount: amount,
                startDate: startDate,
                frequency: frequency,
                frequencyUnits: frequencyUnits,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IncomeStreamModelRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncomeStreamModelRowsTable,
      IncomeStreamModelRow,
      $$IncomeStreamModelRowsTableFilterComposer,
      $$IncomeStreamModelRowsTableOrderingComposer,
      $$IncomeStreamModelRowsTableAnnotationComposer,
      $$IncomeStreamModelRowsTableCreateCompanionBuilder,
      $$IncomeStreamModelRowsTableUpdateCompanionBuilder,
      (
        IncomeStreamModelRow,
        BaseReferences<
          _$AppDatabase,
          $IncomeStreamModelRowsTable,
          IncomeStreamModelRow
        >,
      ),
      IncomeStreamModelRow,
      PrefetchHooks Function()
    >;
typedef $$CategoryRowsTableCreateCompanionBuilder =
    CategoryRowsCompanion Function({Value<int> id, required String name});
typedef $$CategoryRowsTableUpdateCompanionBuilder =
    CategoryRowsCompanion Function({Value<int> id, Value<String> name});

class $$CategoryRowsTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryRowsTable> {
  $$CategoryRowsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoryRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryRowsTable> {
  $$CategoryRowsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryRowsTable> {
  $$CategoryRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$CategoryRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryRowsTable,
          CategoryRow,
          $$CategoryRowsTableFilterComposer,
          $$CategoryRowsTableOrderingComposer,
          $$CategoryRowsTableAnnotationComposer,
          $$CategoryRowsTableCreateCompanionBuilder,
          $$CategoryRowsTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$AppDatabase, $CategoryRowsTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$CategoryRowsTableTableManager(_$AppDatabase db, $CategoryRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => CategoryRowsCompanion(id: id, name: name),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String name}) =>
                  CategoryRowsCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryRowsTable,
      CategoryRow,
      $$CategoryRowsTableFilterComposer,
      $$CategoryRowsTableOrderingComposer,
      $$CategoryRowsTableAnnotationComposer,
      $$CategoryRowsTableCreateCompanionBuilder,
      $$CategoryRowsTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$AppDatabase, $CategoryRowsTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$AppMetaRowsTableCreateCompanionBuilder =
    AppMetaRowsCompanion Function({
      Value<int> id,
      Value<double> currentBalance,
      required DateTime lastUpdated,
      Value<bool> includeNextCheck,
    });
typedef $$AppMetaRowsTableUpdateCompanionBuilder =
    AppMetaRowsCompanion Function({
      Value<int> id,
      Value<double> currentBalance,
      Value<DateTime> lastUpdated,
      Value<bool> includeNextCheck,
    });

class $$AppMetaRowsTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaRowsTable> {
  $$AppMetaRowsTableFilterComposer({
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

  ColumnFilters<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get includeNextCheck => $composableBuilder(
    column: $table.includeNextCheck,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaRowsTable> {
  $$AppMetaRowsTableOrderingComposer({
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

  ColumnOrderings<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get includeNextCheck => $composableBuilder(
    column: $table.includeNextCheck,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaRowsTable> {
  $$AppMetaRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get includeNextCheck => $composableBuilder(
    column: $table.includeNextCheck,
    builder: (column) => column,
  );
}

class $$AppMetaRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaRowsTable,
          AppMetaRow,
          $$AppMetaRowsTableFilterComposer,
          $$AppMetaRowsTableOrderingComposer,
          $$AppMetaRowsTableAnnotationComposer,
          $$AppMetaRowsTableCreateCompanionBuilder,
          $$AppMetaRowsTableUpdateCompanionBuilder,
          (
            AppMetaRow,
            BaseReferences<_$AppDatabase, $AppMetaRowsTable, AppMetaRow>,
          ),
          AppMetaRow,
          PrefetchHooks Function()
        > {
  $$AppMetaRowsTableTableManager(_$AppDatabase db, $AppMetaRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> currentBalance = const Value.absent(),
                Value<DateTime> lastUpdated = const Value.absent(),
                Value<bool> includeNextCheck = const Value.absent(),
              }) => AppMetaRowsCompanion(
                id: id,
                currentBalance: currentBalance,
                lastUpdated: lastUpdated,
                includeNextCheck: includeNextCheck,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> currentBalance = const Value.absent(),
                required DateTime lastUpdated,
                Value<bool> includeNextCheck = const Value.absent(),
              }) => AppMetaRowsCompanion.insert(
                id: id,
                currentBalance: currentBalance,
                lastUpdated: lastUpdated,
                includeNextCheck: includeNextCheck,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaRowsTable,
      AppMetaRow,
      $$AppMetaRowsTableFilterComposer,
      $$AppMetaRowsTableOrderingComposer,
      $$AppMetaRowsTableAnnotationComposer,
      $$AppMetaRowsTableCreateCompanionBuilder,
      $$AppMetaRowsTableUpdateCompanionBuilder,
      (
        AppMetaRow,
        BaseReferences<_$AppDatabase, $AppMetaRowsTable, AppMetaRow>,
      ),
      AppMetaRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExpenseItemRowsTableTableManager get expenseItemRows =>
      $$ExpenseItemRowsTableTableManager(_db, _db.expenseItemRows);
  $$IncomeStreamModelRowsTableTableManager get incomeStreamModelRows =>
      $$IncomeStreamModelRowsTableTableManager(_db, _db.incomeStreamModelRows);
  $$CategoryRowsTableTableManager get categoryRows =>
      $$CategoryRowsTableTableManager(_db, _db.categoryRows);
  $$AppMetaRowsTableTableManager get appMetaRows =>
      $$AppMetaRowsTableTableManager(_db, _db.appMetaRows);
}
