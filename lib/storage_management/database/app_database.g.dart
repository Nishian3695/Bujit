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
  static const VerificationMeta _googleTaskIdMeta = const VerificationMeta(
    'googleTaskId',
  );
  @override
  late final GeneratedColumn<String> googleTaskId = GeneratedColumn<String>(
    'google_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remindInTasksMeta = const VerificationMeta(
    'remindInTasks',
  );
  @override
  late final GeneratedColumn<bool> remindInTasks = GeneratedColumn<bool>(
    'remind_in_tasks',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remind_in_tasks" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<FundingSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(FundingSource.balance.name),
      ).withConverter<FundingSource>($ExpenseItemRowsTable.$convertersource);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedAccountIdMeta = const VerificationMeta(
    'linkedAccountId',
  );
  @override
  late final GeneratedColumn<String> linkedAccountId = GeneratedColumn<String>(
    'linked_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    googleTaskId,
    remindInTasks,
    source,
    sourceId,
    linkedAccountId,
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
    if (data.containsKey('google_task_id')) {
      context.handle(
        _googleTaskIdMeta,
        googleTaskId.isAcceptableOrUnknown(
          data['google_task_id']!,
          _googleTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('remind_in_tasks')) {
      context.handle(
        _remindInTasksMeta,
        remindInTasks.isAcceptableOrUnknown(
          data['remind_in_tasks']!,
          _remindInTasksMeta,
        ),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('linked_account_id')) {
      context.handle(
        _linkedAccountIdMeta,
        linkedAccountId.isAcceptableOrUnknown(
          data['linked_account_id']!,
          _linkedAccountIdMeta,
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
      googleTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}google_task_id'],
      ),
      remindInTasks: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remind_in_tasks'],
      )!,
      source: $ExpenseItemRowsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      linkedAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_account_id'],
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
  static JsonTypeConverter2<FundingSource, String, String> $convertersource =
      const EnumNameConverter<FundingSource>(FundingSource.values);
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
  final String? googleTaskId;
  final bool remindInTasks;
  final FundingSource source;
  final String? sourceId;
  final String? linkedAccountId;
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
    this.googleTaskId,
    required this.remindInTasks,
    required this.source,
    this.sourceId,
    this.linkedAccountId,
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
    if (!nullToAbsent || googleTaskId != null) {
      map['google_task_id'] = Variable<String>(googleTaskId);
    }
    map['remind_in_tasks'] = Variable<bool>(remindInTasks);
    {
      map['source'] = Variable<String>(
        $ExpenseItemRowsTable.$convertersource.toSql(source),
      );
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || linkedAccountId != null) {
      map['linked_account_id'] = Variable<String>(linkedAccountId);
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
      googleTaskId: googleTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(googleTaskId),
      remindInTasks: Value(remindInTasks),
      source: Value(source),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      linkedAccountId: linkedAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedAccountId),
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
      googleTaskId: serializer.fromJson<String?>(json['googleTaskId']),
      remindInTasks: serializer.fromJson<bool>(json['remindInTasks']),
      source: $ExpenseItemRowsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      linkedAccountId: serializer.fromJson<String?>(json['linkedAccountId']),
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
      'googleTaskId': serializer.toJson<String?>(googleTaskId),
      'remindInTasks': serializer.toJson<bool>(remindInTasks),
      'source': serializer.toJson<String>(
        $ExpenseItemRowsTable.$convertersource.toJson(source),
      ),
      'sourceId': serializer.toJson<String?>(sourceId),
      'linkedAccountId': serializer.toJson<String?>(linkedAccountId),
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
    Value<String?> googleTaskId = const Value.absent(),
    bool? remindInTasks,
    FundingSource? source,
    Value<String?> sourceId = const Value.absent(),
    Value<String?> linkedAccountId = const Value.absent(),
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
    googleTaskId: googleTaskId.present ? googleTaskId.value : this.googleTaskId,
    remindInTasks: remindInTasks ?? this.remindInTasks,
    source: source ?? this.source,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    linkedAccountId: linkedAccountId.present
        ? linkedAccountId.value
        : this.linkedAccountId,
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
      googleTaskId: data.googleTaskId.present
          ? data.googleTaskId.value
          : this.googleTaskId,
      remindInTasks: data.remindInTasks.present
          ? data.remindInTasks.value
          : this.remindInTasks,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      linkedAccountId: data.linkedAccountId.present
          ? data.linkedAccountId.value
          : this.linkedAccountId,
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
          ..write('creditLimit: $creditLimit, ')
          ..write('googleTaskId: $googleTaskId, ')
          ..write('remindInTasks: $remindInTasks, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('linkedAccountId: $linkedAccountId')
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
    googleTaskId,
    remindInTasks,
    source,
    sourceId,
    linkedAccountId,
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
          other.creditLimit == this.creditLimit &&
          other.googleTaskId == this.googleTaskId &&
          other.remindInTasks == this.remindInTasks &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.linkedAccountId == this.linkedAccountId);
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
  final Value<String?> googleTaskId;
  final Value<bool> remindInTasks;
  final Value<FundingSource> source;
  final Value<String?> sourceId;
  final Value<String?> linkedAccountId;
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
    this.googleTaskId = const Value.absent(),
    this.remindInTasks = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.linkedAccountId = const Value.absent(),
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
    this.googleTaskId = const Value.absent(),
    this.remindInTasks = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.linkedAccountId = const Value.absent(),
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
    Expression<String>? googleTaskId,
    Expression<bool>? remindInTasks,
    Expression<String>? source,
    Expression<String>? sourceId,
    Expression<String>? linkedAccountId,
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
      if (googleTaskId != null) 'google_task_id': googleTaskId,
      if (remindInTasks != null) 'remind_in_tasks': remindInTasks,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (linkedAccountId != null) 'linked_account_id': linkedAccountId,
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
    Value<String?>? googleTaskId,
    Value<bool>? remindInTasks,
    Value<FundingSource>? source,
    Value<String?>? sourceId,
    Value<String?>? linkedAccountId,
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
      googleTaskId: googleTaskId ?? this.googleTaskId,
      remindInTasks: remindInTasks ?? this.remindInTasks,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
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
    if (googleTaskId.present) {
      map['google_task_id'] = Variable<String>(googleTaskId.value);
    }
    if (remindInTasks.present) {
      map['remind_in_tasks'] = Variable<bool>(remindInTasks.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $ExpenseItemRowsTable.$convertersource.toSql(source.value),
      );
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (linkedAccountId.present) {
      map['linked_account_id'] = Variable<String>(linkedAccountId.value);
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
          ..write('creditLimit: $creditLimit, ')
          ..write('googleTaskId: $googleTaskId, ')
          ..write('remindInTasks: $remindInTasks, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('linkedAccountId: $linkedAccountId')
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
  static const VerificationMeta _googleTaskIdMeta = const VerificationMeta(
    'googleTaskId',
  );
  @override
  late final GeneratedColumn<String> googleTaskId = GeneratedColumn<String>(
    'google_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    googleTaskId,
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
    if (data.containsKey('google_task_id')) {
      context.handle(
        _googleTaskIdMeta,
        googleTaskId.isAcceptableOrUnknown(
          data['google_task_id']!,
          _googleTaskIdMeta,
        ),
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
      googleTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}google_task_id'],
      ),
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
  final String? googleTaskId;
  const IncomeStreamModelRow({
    required this.id,
    required this.name,
    required this.amount,
    required this.startDate,
    required this.frequency,
    required this.frequencyUnits,
    required this.isActive,
    this.googleTaskId,
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
    if (!nullToAbsent || googleTaskId != null) {
      map['google_task_id'] = Variable<String>(googleTaskId);
    }
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
      googleTaskId: googleTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(googleTaskId),
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
      googleTaskId: serializer.fromJson<String?>(json['googleTaskId']),
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
      'googleTaskId': serializer.toJson<String?>(googleTaskId),
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
    Value<String?> googleTaskId = const Value.absent(),
  }) => IncomeStreamModelRow(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    startDate: startDate ?? this.startDate,
    frequency: frequency ?? this.frequency,
    frequencyUnits: frequencyUnits ?? this.frequencyUnits,
    isActive: isActive ?? this.isActive,
    googleTaskId: googleTaskId.present ? googleTaskId.value : this.googleTaskId,
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
      googleTaskId: data.googleTaskId.present
          ? data.googleTaskId.value
          : this.googleTaskId,
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
          ..write('isActive: $isActive, ')
          ..write('googleTaskId: $googleTaskId')
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
    googleTaskId,
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
          other.isActive == this.isActive &&
          other.googleTaskId == this.googleTaskId);
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
  final Value<String?> googleTaskId;
  const IncomeStreamModelRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.startDate = const Value.absent(),
    this.frequency = const Value.absent(),
    this.frequencyUnits = const Value.absent(),
    this.isActive = const Value.absent(),
    this.googleTaskId = const Value.absent(),
  });
  IncomeStreamModelRowsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double amount,
    required DateTime startDate,
    required int frequency,
    required FrequencyUnit frequencyUnits,
    this.isActive = const Value.absent(),
    this.googleTaskId = const Value.absent(),
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
    Expression<String>? googleTaskId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (startDate != null) 'start_date': startDate,
      if (frequency != null) 'frequency': frequency,
      if (frequencyUnits != null) 'frequency_units': frequencyUnits,
      if (isActive != null) 'is_active': isActive,
      if (googleTaskId != null) 'google_task_id': googleTaskId,
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
    Value<String?>? googleTaskId,
  }) {
    return IncomeStreamModelRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      frequency: frequency ?? this.frequency,
      frequencyUnits: frequencyUnits ?? this.frequencyUnits,
      isActive: isActive ?? this.isActive,
      googleTaskId: googleTaskId ?? this.googleTaskId,
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
    if (googleTaskId.present) {
      map['google_task_id'] = Variable<String>(googleTaskId.value);
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
          ..write('isActive: $isActive, ')
          ..write('googleTaskId: $googleTaskId')
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
  static const VerificationMeta _balanceExtraMeta = const VerificationMeta(
    'balanceExtra',
  );
  @override
  late final GeneratedColumn<double> balanceExtra = GeneratedColumn<double>(
    'balance_extra',
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
  static const VerificationMeta _singleEventExpiryDaysMeta =
      const VerificationMeta('singleEventExpiryDays');
  @override
  late final GeneratedColumn<int> singleEventExpiryDays = GeneratedColumn<int>(
    'single_event_expiry_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _tutorialStepMeta = const VerificationMeta(
    'tutorialStep',
  );
  @override
  late final GeneratedColumn<int> tutorialStep = GeneratedColumn<int>(
    'tutorial_step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tutorialSeenMeta = const VerificationMeta(
    'tutorialSeen',
  );
  @override
  late final GeneratedColumn<bool> tutorialSeen = GeneratedColumn<bool>(
    'tutorial_seen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tutorial_seen" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _useCommaSeparatorsMeta =
      const VerificationMeta('useCommaSeparators');
  @override
  late final GeneratedColumn<bool> useCommaSeparators = GeneratedColumn<bool>(
    'use_comma_separators',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_comma_separators" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _appLockEnabledMeta = const VerificationMeta(
    'appLockEnabled',
  );
  @override
  late final GeneratedColumn<bool> appLockEnabled = GeneratedColumn<bool>(
    'app_lock_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("app_lock_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _disclaimerAcceptedMeta =
      const VerificationMeta('disclaimerAccepted');
  @override
  late final GeneratedColumn<bool> disclaimerAccepted = GeneratedColumn<bool>(
    'disclaimer_accepted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("disclaimer_accepted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastBankSyncMeta = const VerificationMeta(
    'lastBankSync',
  );
  @override
  late final GeneratedColumn<DateTime> lastBankSync = GeneratedColumn<DateTime>(
    'last_bank_sync',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingLinkedBalanceIdsMeta =
      const VerificationMeta('pendingLinkedBalanceIds');
  @override
  late final GeneratedColumn<String> pendingLinkedBalanceIds =
      GeneratedColumn<String>(
        'pending_linked_balance_ids',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(""),
      );
  static const VerificationMeta _tasksSyncEnabledMeta = const VerificationMeta(
    'tasksSyncEnabled',
  );
  @override
  late final GeneratedColumn<bool> tasksSyncEnabled = GeneratedColumn<bool>(
    'tasks_sync_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tasks_sync_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tasksListIdMeta = const VerificationMeta(
    'tasksListId',
  );
  @override
  late final GeneratedColumn<String> tasksListId = GeneratedColumn<String>(
    'tasks_list_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tasksAccountMeta = const VerificationMeta(
    'tasksAccount',
  );
  @override
  late final GeneratedColumn<String> tasksAccount = GeneratedColumn<String>(
    'tasks_account',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("system"),
  );
  static const VerificationMeta _accentColorMeta = const VerificationMeta(
    'accentColor',
  );
  @override
  late final GeneratedColumn<String> accentColor = GeneratedColumn<String>(
    'accent_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("blue"),
  );
  static const VerificationMeta _customAccentMeta = const VerificationMeta(
    'customAccent',
  );
  @override
  late final GeneratedColumn<int> customAccent = GeneratedColumn<int>(
    'custom_accent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF2979FF),
  );
  static const VerificationMeta _tasksProviderMeta = const VerificationMeta(
    'tasksProvider',
  );
  @override
  late final GeneratedColumn<String> tasksProvider = GeneratedColumn<String>(
    'tasks_provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("google"),
  );
  static const VerificationMeta _launchCountMeta = const VerificationMeta(
    'launchCount',
  );
  @override
  late final GeneratedColumn<int> launchCount = GeneratedColumn<int>(
    'launch_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reviewRequestedMeta = const VerificationMeta(
    'reviewRequested',
  );
  @override
  late final GeneratedColumn<bool> reviewRequested = GeneratedColumn<bool>(
    'review_requested',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("review_requested" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currentBalance,
    balanceExtra,
    lastUpdated,
    includeNextCheck,
    singleEventExpiryDays,
    tutorialStep,
    tutorialSeen,
    useCommaSeparators,
    appLockEnabled,
    disclaimerAccepted,
    lastBankSync,
    pendingLinkedBalanceIds,
    tasksSyncEnabled,
    tasksListId,
    tasksAccount,
    themeMode,
    accentColor,
    customAccent,
    tasksProvider,
    launchCount,
    reviewRequested,
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
    if (data.containsKey('balance_extra')) {
      context.handle(
        _balanceExtraMeta,
        balanceExtra.isAcceptableOrUnknown(
          data['balance_extra']!,
          _balanceExtraMeta,
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
    if (data.containsKey('single_event_expiry_days')) {
      context.handle(
        _singleEventExpiryDaysMeta,
        singleEventExpiryDays.isAcceptableOrUnknown(
          data['single_event_expiry_days']!,
          _singleEventExpiryDaysMeta,
        ),
      );
    }
    if (data.containsKey('tutorial_step')) {
      context.handle(
        _tutorialStepMeta,
        tutorialStep.isAcceptableOrUnknown(
          data['tutorial_step']!,
          _tutorialStepMeta,
        ),
      );
    }
    if (data.containsKey('tutorial_seen')) {
      context.handle(
        _tutorialSeenMeta,
        tutorialSeen.isAcceptableOrUnknown(
          data['tutorial_seen']!,
          _tutorialSeenMeta,
        ),
      );
    }
    if (data.containsKey('use_comma_separators')) {
      context.handle(
        _useCommaSeparatorsMeta,
        useCommaSeparators.isAcceptableOrUnknown(
          data['use_comma_separators']!,
          _useCommaSeparatorsMeta,
        ),
      );
    }
    if (data.containsKey('app_lock_enabled')) {
      context.handle(
        _appLockEnabledMeta,
        appLockEnabled.isAcceptableOrUnknown(
          data['app_lock_enabled']!,
          _appLockEnabledMeta,
        ),
      );
    }
    if (data.containsKey('disclaimer_accepted')) {
      context.handle(
        _disclaimerAcceptedMeta,
        disclaimerAccepted.isAcceptableOrUnknown(
          data['disclaimer_accepted']!,
          _disclaimerAcceptedMeta,
        ),
      );
    }
    if (data.containsKey('last_bank_sync')) {
      context.handle(
        _lastBankSyncMeta,
        lastBankSync.isAcceptableOrUnknown(
          data['last_bank_sync']!,
          _lastBankSyncMeta,
        ),
      );
    }
    if (data.containsKey('pending_linked_balance_ids')) {
      context.handle(
        _pendingLinkedBalanceIdsMeta,
        pendingLinkedBalanceIds.isAcceptableOrUnknown(
          data['pending_linked_balance_ids']!,
          _pendingLinkedBalanceIdsMeta,
        ),
      );
    }
    if (data.containsKey('tasks_sync_enabled')) {
      context.handle(
        _tasksSyncEnabledMeta,
        tasksSyncEnabled.isAcceptableOrUnknown(
          data['tasks_sync_enabled']!,
          _tasksSyncEnabledMeta,
        ),
      );
    }
    if (data.containsKey('tasks_list_id')) {
      context.handle(
        _tasksListIdMeta,
        tasksListId.isAcceptableOrUnknown(
          data['tasks_list_id']!,
          _tasksListIdMeta,
        ),
      );
    }
    if (data.containsKey('tasks_account')) {
      context.handle(
        _tasksAccountMeta,
        tasksAccount.isAcceptableOrUnknown(
          data['tasks_account']!,
          _tasksAccountMeta,
        ),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('accent_color')) {
      context.handle(
        _accentColorMeta,
        accentColor.isAcceptableOrUnknown(
          data['accent_color']!,
          _accentColorMeta,
        ),
      );
    }
    if (data.containsKey('custom_accent')) {
      context.handle(
        _customAccentMeta,
        customAccent.isAcceptableOrUnknown(
          data['custom_accent']!,
          _customAccentMeta,
        ),
      );
    }
    if (data.containsKey('tasks_provider')) {
      context.handle(
        _tasksProviderMeta,
        tasksProvider.isAcceptableOrUnknown(
          data['tasks_provider']!,
          _tasksProviderMeta,
        ),
      );
    }
    if (data.containsKey('launch_count')) {
      context.handle(
        _launchCountMeta,
        launchCount.isAcceptableOrUnknown(
          data['launch_count']!,
          _launchCountMeta,
        ),
      );
    }
    if (data.containsKey('review_requested')) {
      context.handle(
        _reviewRequestedMeta,
        reviewRequested.isAcceptableOrUnknown(
          data['review_requested']!,
          _reviewRequestedMeta,
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
      balanceExtra: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance_extra'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      )!,
      includeNextCheck: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_next_check'],
      )!,
      singleEventExpiryDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}single_event_expiry_days'],
      )!,
      tutorialStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tutorial_step'],
      )!,
      tutorialSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tutorial_seen'],
      )!,
      useCommaSeparators: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_comma_separators'],
      )!,
      appLockEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}app_lock_enabled'],
      )!,
      disclaimerAccepted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}disclaimer_accepted'],
      )!,
      lastBankSync: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_bank_sync'],
      ),
      pendingLinkedBalanceIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_linked_balance_ids'],
      )!,
      tasksSyncEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tasks_sync_enabled'],
      )!,
      tasksListId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tasks_list_id'],
      ),
      tasksAccount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tasks_account'],
      ),
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      accentColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accent_color'],
      )!,
      customAccent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}custom_accent'],
      )!,
      tasksProvider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tasks_provider'],
      )!,
      launchCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}launch_count'],
      )!,
      reviewRequested: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}review_requested'],
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
  final double balanceExtra;
  final DateTime lastUpdated;
  final bool includeNextCheck;
  final int singleEventExpiryDays;
  final int tutorialStep;
  final bool tutorialSeen;
  final bool useCommaSeparators;
  final bool appLockEnabled;
  final bool disclaimerAccepted;
  final DateTime? lastBankSync;
  final String pendingLinkedBalanceIds;
  final bool tasksSyncEnabled;
  final String? tasksListId;
  final String? tasksAccount;
  final String themeMode;
  final String accentColor;
  final int customAccent;
  final String tasksProvider;
  final int launchCount;
  final bool reviewRequested;
  const AppMetaRow({
    required this.id,
    required this.currentBalance,
    required this.balanceExtra,
    required this.lastUpdated,
    required this.includeNextCheck,
    required this.singleEventExpiryDays,
    required this.tutorialStep,
    required this.tutorialSeen,
    required this.useCommaSeparators,
    required this.appLockEnabled,
    required this.disclaimerAccepted,
    this.lastBankSync,
    required this.pendingLinkedBalanceIds,
    required this.tasksSyncEnabled,
    this.tasksListId,
    this.tasksAccount,
    required this.themeMode,
    required this.accentColor,
    required this.customAccent,
    required this.tasksProvider,
    required this.launchCount,
    required this.reviewRequested,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['current_balance'] = Variable<double>(currentBalance);
    map['balance_extra'] = Variable<double>(balanceExtra);
    map['last_updated'] = Variable<DateTime>(lastUpdated);
    map['include_next_check'] = Variable<bool>(includeNextCheck);
    map['single_event_expiry_days'] = Variable<int>(singleEventExpiryDays);
    map['tutorial_step'] = Variable<int>(tutorialStep);
    map['tutorial_seen'] = Variable<bool>(tutorialSeen);
    map['use_comma_separators'] = Variable<bool>(useCommaSeparators);
    map['app_lock_enabled'] = Variable<bool>(appLockEnabled);
    map['disclaimer_accepted'] = Variable<bool>(disclaimerAccepted);
    if (!nullToAbsent || lastBankSync != null) {
      map['last_bank_sync'] = Variable<DateTime>(lastBankSync);
    }
    map['pending_linked_balance_ids'] = Variable<String>(
      pendingLinkedBalanceIds,
    );
    map['tasks_sync_enabled'] = Variable<bool>(tasksSyncEnabled);
    if (!nullToAbsent || tasksListId != null) {
      map['tasks_list_id'] = Variable<String>(tasksListId);
    }
    if (!nullToAbsent || tasksAccount != null) {
      map['tasks_account'] = Variable<String>(tasksAccount);
    }
    map['theme_mode'] = Variable<String>(themeMode);
    map['accent_color'] = Variable<String>(accentColor);
    map['custom_accent'] = Variable<int>(customAccent);
    map['tasks_provider'] = Variable<String>(tasksProvider);
    map['launch_count'] = Variable<int>(launchCount);
    map['review_requested'] = Variable<bool>(reviewRequested);
    return map;
  }

  AppMetaRowsCompanion toCompanion(bool nullToAbsent) {
    return AppMetaRowsCompanion(
      id: Value(id),
      currentBalance: Value(currentBalance),
      balanceExtra: Value(balanceExtra),
      lastUpdated: Value(lastUpdated),
      includeNextCheck: Value(includeNextCheck),
      singleEventExpiryDays: Value(singleEventExpiryDays),
      tutorialStep: Value(tutorialStep),
      tutorialSeen: Value(tutorialSeen),
      useCommaSeparators: Value(useCommaSeparators),
      appLockEnabled: Value(appLockEnabled),
      disclaimerAccepted: Value(disclaimerAccepted),
      lastBankSync: lastBankSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBankSync),
      pendingLinkedBalanceIds: Value(pendingLinkedBalanceIds),
      tasksSyncEnabled: Value(tasksSyncEnabled),
      tasksListId: tasksListId == null && nullToAbsent
          ? const Value.absent()
          : Value(tasksListId),
      tasksAccount: tasksAccount == null && nullToAbsent
          ? const Value.absent()
          : Value(tasksAccount),
      themeMode: Value(themeMode),
      accentColor: Value(accentColor),
      customAccent: Value(customAccent),
      tasksProvider: Value(tasksProvider),
      launchCount: Value(launchCount),
      reviewRequested: Value(reviewRequested),
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
      balanceExtra: serializer.fromJson<double>(json['balanceExtra']),
      lastUpdated: serializer.fromJson<DateTime>(json['lastUpdated']),
      includeNextCheck: serializer.fromJson<bool>(json['includeNextCheck']),
      singleEventExpiryDays: serializer.fromJson<int>(
        json['singleEventExpiryDays'],
      ),
      tutorialStep: serializer.fromJson<int>(json['tutorialStep']),
      tutorialSeen: serializer.fromJson<bool>(json['tutorialSeen']),
      useCommaSeparators: serializer.fromJson<bool>(json['useCommaSeparators']),
      appLockEnabled: serializer.fromJson<bool>(json['appLockEnabled']),
      disclaimerAccepted: serializer.fromJson<bool>(json['disclaimerAccepted']),
      lastBankSync: serializer.fromJson<DateTime?>(json['lastBankSync']),
      pendingLinkedBalanceIds: serializer.fromJson<String>(
        json['pendingLinkedBalanceIds'],
      ),
      tasksSyncEnabled: serializer.fromJson<bool>(json['tasksSyncEnabled']),
      tasksListId: serializer.fromJson<String?>(json['tasksListId']),
      tasksAccount: serializer.fromJson<String?>(json['tasksAccount']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      accentColor: serializer.fromJson<String>(json['accentColor']),
      customAccent: serializer.fromJson<int>(json['customAccent']),
      tasksProvider: serializer.fromJson<String>(json['tasksProvider']),
      launchCount: serializer.fromJson<int>(json['launchCount']),
      reviewRequested: serializer.fromJson<bool>(json['reviewRequested']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currentBalance': serializer.toJson<double>(currentBalance),
      'balanceExtra': serializer.toJson<double>(balanceExtra),
      'lastUpdated': serializer.toJson<DateTime>(lastUpdated),
      'includeNextCheck': serializer.toJson<bool>(includeNextCheck),
      'singleEventExpiryDays': serializer.toJson<int>(singleEventExpiryDays),
      'tutorialStep': serializer.toJson<int>(tutorialStep),
      'tutorialSeen': serializer.toJson<bool>(tutorialSeen),
      'useCommaSeparators': serializer.toJson<bool>(useCommaSeparators),
      'appLockEnabled': serializer.toJson<bool>(appLockEnabled),
      'disclaimerAccepted': serializer.toJson<bool>(disclaimerAccepted),
      'lastBankSync': serializer.toJson<DateTime?>(lastBankSync),
      'pendingLinkedBalanceIds': serializer.toJson<String>(
        pendingLinkedBalanceIds,
      ),
      'tasksSyncEnabled': serializer.toJson<bool>(tasksSyncEnabled),
      'tasksListId': serializer.toJson<String?>(tasksListId),
      'tasksAccount': serializer.toJson<String?>(tasksAccount),
      'themeMode': serializer.toJson<String>(themeMode),
      'accentColor': serializer.toJson<String>(accentColor),
      'customAccent': serializer.toJson<int>(customAccent),
      'tasksProvider': serializer.toJson<String>(tasksProvider),
      'launchCount': serializer.toJson<int>(launchCount),
      'reviewRequested': serializer.toJson<bool>(reviewRequested),
    };
  }

  AppMetaRow copyWith({
    int? id,
    double? currentBalance,
    double? balanceExtra,
    DateTime? lastUpdated,
    bool? includeNextCheck,
    int? singleEventExpiryDays,
    int? tutorialStep,
    bool? tutorialSeen,
    bool? useCommaSeparators,
    bool? appLockEnabled,
    bool? disclaimerAccepted,
    Value<DateTime?> lastBankSync = const Value.absent(),
    String? pendingLinkedBalanceIds,
    bool? tasksSyncEnabled,
    Value<String?> tasksListId = const Value.absent(),
    Value<String?> tasksAccount = const Value.absent(),
    String? themeMode,
    String? accentColor,
    int? customAccent,
    String? tasksProvider,
    int? launchCount,
    bool? reviewRequested,
  }) => AppMetaRow(
    id: id ?? this.id,
    currentBalance: currentBalance ?? this.currentBalance,
    balanceExtra: balanceExtra ?? this.balanceExtra,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    includeNextCheck: includeNextCheck ?? this.includeNextCheck,
    singleEventExpiryDays: singleEventExpiryDays ?? this.singleEventExpiryDays,
    tutorialStep: tutorialStep ?? this.tutorialStep,
    tutorialSeen: tutorialSeen ?? this.tutorialSeen,
    useCommaSeparators: useCommaSeparators ?? this.useCommaSeparators,
    appLockEnabled: appLockEnabled ?? this.appLockEnabled,
    disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
    lastBankSync: lastBankSync.present ? lastBankSync.value : this.lastBankSync,
    pendingLinkedBalanceIds:
        pendingLinkedBalanceIds ?? this.pendingLinkedBalanceIds,
    tasksSyncEnabled: tasksSyncEnabled ?? this.tasksSyncEnabled,
    tasksListId: tasksListId.present ? tasksListId.value : this.tasksListId,
    tasksAccount: tasksAccount.present ? tasksAccount.value : this.tasksAccount,
    themeMode: themeMode ?? this.themeMode,
    accentColor: accentColor ?? this.accentColor,
    customAccent: customAccent ?? this.customAccent,
    tasksProvider: tasksProvider ?? this.tasksProvider,
    launchCount: launchCount ?? this.launchCount,
    reviewRequested: reviewRequested ?? this.reviewRequested,
  );
  AppMetaRow copyWithCompanion(AppMetaRowsCompanion data) {
    return AppMetaRow(
      id: data.id.present ? data.id.value : this.id,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      balanceExtra: data.balanceExtra.present
          ? data.balanceExtra.value
          : this.balanceExtra,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
      includeNextCheck: data.includeNextCheck.present
          ? data.includeNextCheck.value
          : this.includeNextCheck,
      singleEventExpiryDays: data.singleEventExpiryDays.present
          ? data.singleEventExpiryDays.value
          : this.singleEventExpiryDays,
      tutorialStep: data.tutorialStep.present
          ? data.tutorialStep.value
          : this.tutorialStep,
      tutorialSeen: data.tutorialSeen.present
          ? data.tutorialSeen.value
          : this.tutorialSeen,
      useCommaSeparators: data.useCommaSeparators.present
          ? data.useCommaSeparators.value
          : this.useCommaSeparators,
      appLockEnabled: data.appLockEnabled.present
          ? data.appLockEnabled.value
          : this.appLockEnabled,
      disclaimerAccepted: data.disclaimerAccepted.present
          ? data.disclaimerAccepted.value
          : this.disclaimerAccepted,
      lastBankSync: data.lastBankSync.present
          ? data.lastBankSync.value
          : this.lastBankSync,
      pendingLinkedBalanceIds: data.pendingLinkedBalanceIds.present
          ? data.pendingLinkedBalanceIds.value
          : this.pendingLinkedBalanceIds,
      tasksSyncEnabled: data.tasksSyncEnabled.present
          ? data.tasksSyncEnabled.value
          : this.tasksSyncEnabled,
      tasksListId: data.tasksListId.present
          ? data.tasksListId.value
          : this.tasksListId,
      tasksAccount: data.tasksAccount.present
          ? data.tasksAccount.value
          : this.tasksAccount,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      accentColor: data.accentColor.present
          ? data.accentColor.value
          : this.accentColor,
      customAccent: data.customAccent.present
          ? data.customAccent.value
          : this.customAccent,
      tasksProvider: data.tasksProvider.present
          ? data.tasksProvider.value
          : this.tasksProvider,
      launchCount: data.launchCount.present
          ? data.launchCount.value
          : this.launchCount,
      reviewRequested: data.reviewRequested.present
          ? data.reviewRequested.value
          : this.reviewRequested,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRow(')
          ..write('id: $id, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('balanceExtra: $balanceExtra, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('includeNextCheck: $includeNextCheck, ')
          ..write('singleEventExpiryDays: $singleEventExpiryDays, ')
          ..write('tutorialStep: $tutorialStep, ')
          ..write('tutorialSeen: $tutorialSeen, ')
          ..write('useCommaSeparators: $useCommaSeparators, ')
          ..write('appLockEnabled: $appLockEnabled, ')
          ..write('disclaimerAccepted: $disclaimerAccepted, ')
          ..write('lastBankSync: $lastBankSync, ')
          ..write('pendingLinkedBalanceIds: $pendingLinkedBalanceIds, ')
          ..write('tasksSyncEnabled: $tasksSyncEnabled, ')
          ..write('tasksListId: $tasksListId, ')
          ..write('tasksAccount: $tasksAccount, ')
          ..write('themeMode: $themeMode, ')
          ..write('accentColor: $accentColor, ')
          ..write('customAccent: $customAccent, ')
          ..write('tasksProvider: $tasksProvider, ')
          ..write('launchCount: $launchCount, ')
          ..write('reviewRequested: $reviewRequested')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    currentBalance,
    balanceExtra,
    lastUpdated,
    includeNextCheck,
    singleEventExpiryDays,
    tutorialStep,
    tutorialSeen,
    useCommaSeparators,
    appLockEnabled,
    disclaimerAccepted,
    lastBankSync,
    pendingLinkedBalanceIds,
    tasksSyncEnabled,
    tasksListId,
    tasksAccount,
    themeMode,
    accentColor,
    customAccent,
    tasksProvider,
    launchCount,
    reviewRequested,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaRow &&
          other.id == this.id &&
          other.currentBalance == this.currentBalance &&
          other.balanceExtra == this.balanceExtra &&
          other.lastUpdated == this.lastUpdated &&
          other.includeNextCheck == this.includeNextCheck &&
          other.singleEventExpiryDays == this.singleEventExpiryDays &&
          other.tutorialStep == this.tutorialStep &&
          other.tutorialSeen == this.tutorialSeen &&
          other.useCommaSeparators == this.useCommaSeparators &&
          other.appLockEnabled == this.appLockEnabled &&
          other.disclaimerAccepted == this.disclaimerAccepted &&
          other.lastBankSync == this.lastBankSync &&
          other.pendingLinkedBalanceIds == this.pendingLinkedBalanceIds &&
          other.tasksSyncEnabled == this.tasksSyncEnabled &&
          other.tasksListId == this.tasksListId &&
          other.tasksAccount == this.tasksAccount &&
          other.themeMode == this.themeMode &&
          other.accentColor == this.accentColor &&
          other.customAccent == this.customAccent &&
          other.tasksProvider == this.tasksProvider &&
          other.launchCount == this.launchCount &&
          other.reviewRequested == this.reviewRequested);
}

class AppMetaRowsCompanion extends UpdateCompanion<AppMetaRow> {
  final Value<int> id;
  final Value<double> currentBalance;
  final Value<double> balanceExtra;
  final Value<DateTime> lastUpdated;
  final Value<bool> includeNextCheck;
  final Value<int> singleEventExpiryDays;
  final Value<int> tutorialStep;
  final Value<bool> tutorialSeen;
  final Value<bool> useCommaSeparators;
  final Value<bool> appLockEnabled;
  final Value<bool> disclaimerAccepted;
  final Value<DateTime?> lastBankSync;
  final Value<String> pendingLinkedBalanceIds;
  final Value<bool> tasksSyncEnabled;
  final Value<String?> tasksListId;
  final Value<String?> tasksAccount;
  final Value<String> themeMode;
  final Value<String> accentColor;
  final Value<int> customAccent;
  final Value<String> tasksProvider;
  final Value<int> launchCount;
  final Value<bool> reviewRequested;
  const AppMetaRowsCompanion({
    this.id = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.balanceExtra = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.includeNextCheck = const Value.absent(),
    this.singleEventExpiryDays = const Value.absent(),
    this.tutorialStep = const Value.absent(),
    this.tutorialSeen = const Value.absent(),
    this.useCommaSeparators = const Value.absent(),
    this.appLockEnabled = const Value.absent(),
    this.disclaimerAccepted = const Value.absent(),
    this.lastBankSync = const Value.absent(),
    this.pendingLinkedBalanceIds = const Value.absent(),
    this.tasksSyncEnabled = const Value.absent(),
    this.tasksListId = const Value.absent(),
    this.tasksAccount = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.accentColor = const Value.absent(),
    this.customAccent = const Value.absent(),
    this.tasksProvider = const Value.absent(),
    this.launchCount = const Value.absent(),
    this.reviewRequested = const Value.absent(),
  });
  AppMetaRowsCompanion.insert({
    this.id = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.balanceExtra = const Value.absent(),
    required DateTime lastUpdated,
    this.includeNextCheck = const Value.absent(),
    this.singleEventExpiryDays = const Value.absent(),
    this.tutorialStep = const Value.absent(),
    this.tutorialSeen = const Value.absent(),
    this.useCommaSeparators = const Value.absent(),
    this.appLockEnabled = const Value.absent(),
    this.disclaimerAccepted = const Value.absent(),
    this.lastBankSync = const Value.absent(),
    this.pendingLinkedBalanceIds = const Value.absent(),
    this.tasksSyncEnabled = const Value.absent(),
    this.tasksListId = const Value.absent(),
    this.tasksAccount = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.accentColor = const Value.absent(),
    this.customAccent = const Value.absent(),
    this.tasksProvider = const Value.absent(),
    this.launchCount = const Value.absent(),
    this.reviewRequested = const Value.absent(),
  }) : lastUpdated = Value(lastUpdated);
  static Insertable<AppMetaRow> custom({
    Expression<int>? id,
    Expression<double>? currentBalance,
    Expression<double>? balanceExtra,
    Expression<DateTime>? lastUpdated,
    Expression<bool>? includeNextCheck,
    Expression<int>? singleEventExpiryDays,
    Expression<int>? tutorialStep,
    Expression<bool>? tutorialSeen,
    Expression<bool>? useCommaSeparators,
    Expression<bool>? appLockEnabled,
    Expression<bool>? disclaimerAccepted,
    Expression<DateTime>? lastBankSync,
    Expression<String>? pendingLinkedBalanceIds,
    Expression<bool>? tasksSyncEnabled,
    Expression<String>? tasksListId,
    Expression<String>? tasksAccount,
    Expression<String>? themeMode,
    Expression<String>? accentColor,
    Expression<int>? customAccent,
    Expression<String>? tasksProvider,
    Expression<int>? launchCount,
    Expression<bool>? reviewRequested,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (balanceExtra != null) 'balance_extra': balanceExtra,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (includeNextCheck != null) 'include_next_check': includeNextCheck,
      if (singleEventExpiryDays != null)
        'single_event_expiry_days': singleEventExpiryDays,
      if (tutorialStep != null) 'tutorial_step': tutorialStep,
      if (tutorialSeen != null) 'tutorial_seen': tutorialSeen,
      if (useCommaSeparators != null)
        'use_comma_separators': useCommaSeparators,
      if (appLockEnabled != null) 'app_lock_enabled': appLockEnabled,
      if (disclaimerAccepted != null) 'disclaimer_accepted': disclaimerAccepted,
      if (lastBankSync != null) 'last_bank_sync': lastBankSync,
      if (pendingLinkedBalanceIds != null)
        'pending_linked_balance_ids': pendingLinkedBalanceIds,
      if (tasksSyncEnabled != null) 'tasks_sync_enabled': tasksSyncEnabled,
      if (tasksListId != null) 'tasks_list_id': tasksListId,
      if (tasksAccount != null) 'tasks_account': tasksAccount,
      if (themeMode != null) 'theme_mode': themeMode,
      if (accentColor != null) 'accent_color': accentColor,
      if (customAccent != null) 'custom_accent': customAccent,
      if (tasksProvider != null) 'tasks_provider': tasksProvider,
      if (launchCount != null) 'launch_count': launchCount,
      if (reviewRequested != null) 'review_requested': reviewRequested,
    });
  }

  AppMetaRowsCompanion copyWith({
    Value<int>? id,
    Value<double>? currentBalance,
    Value<double>? balanceExtra,
    Value<DateTime>? lastUpdated,
    Value<bool>? includeNextCheck,
    Value<int>? singleEventExpiryDays,
    Value<int>? tutorialStep,
    Value<bool>? tutorialSeen,
    Value<bool>? useCommaSeparators,
    Value<bool>? appLockEnabled,
    Value<bool>? disclaimerAccepted,
    Value<DateTime?>? lastBankSync,
    Value<String>? pendingLinkedBalanceIds,
    Value<bool>? tasksSyncEnabled,
    Value<String?>? tasksListId,
    Value<String?>? tasksAccount,
    Value<String>? themeMode,
    Value<String>? accentColor,
    Value<int>? customAccent,
    Value<String>? tasksProvider,
    Value<int>? launchCount,
    Value<bool>? reviewRequested,
  }) {
    return AppMetaRowsCompanion(
      id: id ?? this.id,
      currentBalance: currentBalance ?? this.currentBalance,
      balanceExtra: balanceExtra ?? this.balanceExtra,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      includeNextCheck: includeNextCheck ?? this.includeNextCheck,
      singleEventExpiryDays:
          singleEventExpiryDays ?? this.singleEventExpiryDays,
      tutorialStep: tutorialStep ?? this.tutorialStep,
      tutorialSeen: tutorialSeen ?? this.tutorialSeen,
      useCommaSeparators: useCommaSeparators ?? this.useCommaSeparators,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
      lastBankSync: lastBankSync ?? this.lastBankSync,
      pendingLinkedBalanceIds:
          pendingLinkedBalanceIds ?? this.pendingLinkedBalanceIds,
      tasksSyncEnabled: tasksSyncEnabled ?? this.tasksSyncEnabled,
      tasksListId: tasksListId ?? this.tasksListId,
      tasksAccount: tasksAccount ?? this.tasksAccount,
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      customAccent: customAccent ?? this.customAccent,
      tasksProvider: tasksProvider ?? this.tasksProvider,
      launchCount: launchCount ?? this.launchCount,
      reviewRequested: reviewRequested ?? this.reviewRequested,
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
    if (balanceExtra.present) {
      map['balance_extra'] = Variable<double>(balanceExtra.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (includeNextCheck.present) {
      map['include_next_check'] = Variable<bool>(includeNextCheck.value);
    }
    if (singleEventExpiryDays.present) {
      map['single_event_expiry_days'] = Variable<int>(
        singleEventExpiryDays.value,
      );
    }
    if (tutorialStep.present) {
      map['tutorial_step'] = Variable<int>(tutorialStep.value);
    }
    if (tutorialSeen.present) {
      map['tutorial_seen'] = Variable<bool>(tutorialSeen.value);
    }
    if (useCommaSeparators.present) {
      map['use_comma_separators'] = Variable<bool>(useCommaSeparators.value);
    }
    if (appLockEnabled.present) {
      map['app_lock_enabled'] = Variable<bool>(appLockEnabled.value);
    }
    if (disclaimerAccepted.present) {
      map['disclaimer_accepted'] = Variable<bool>(disclaimerAccepted.value);
    }
    if (lastBankSync.present) {
      map['last_bank_sync'] = Variable<DateTime>(lastBankSync.value);
    }
    if (pendingLinkedBalanceIds.present) {
      map['pending_linked_balance_ids'] = Variable<String>(
        pendingLinkedBalanceIds.value,
      );
    }
    if (tasksSyncEnabled.present) {
      map['tasks_sync_enabled'] = Variable<bool>(tasksSyncEnabled.value);
    }
    if (tasksListId.present) {
      map['tasks_list_id'] = Variable<String>(tasksListId.value);
    }
    if (tasksAccount.present) {
      map['tasks_account'] = Variable<String>(tasksAccount.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (accentColor.present) {
      map['accent_color'] = Variable<String>(accentColor.value);
    }
    if (customAccent.present) {
      map['custom_accent'] = Variable<int>(customAccent.value);
    }
    if (tasksProvider.present) {
      map['tasks_provider'] = Variable<String>(tasksProvider.value);
    }
    if (launchCount.present) {
      map['launch_count'] = Variable<int>(launchCount.value);
    }
    if (reviewRequested.present) {
      map['review_requested'] = Variable<bool>(reviewRequested.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRowsCompanion(')
          ..write('id: $id, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('balanceExtra: $balanceExtra, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('includeNextCheck: $includeNextCheck, ')
          ..write('singleEventExpiryDays: $singleEventExpiryDays, ')
          ..write('tutorialStep: $tutorialStep, ')
          ..write('tutorialSeen: $tutorialSeen, ')
          ..write('useCommaSeparators: $useCommaSeparators, ')
          ..write('appLockEnabled: $appLockEnabled, ')
          ..write('disclaimerAccepted: $disclaimerAccepted, ')
          ..write('lastBankSync: $lastBankSync, ')
          ..write('pendingLinkedBalanceIds: $pendingLinkedBalanceIds, ')
          ..write('tasksSyncEnabled: $tasksSyncEnabled, ')
          ..write('tasksListId: $tasksListId, ')
          ..write('tasksAccount: $tasksAccount, ')
          ..write('themeMode: $themeMode, ')
          ..write('accentColor: $accentColor, ')
          ..write('customAccent: $customAccent, ')
          ..write('tasksProvider: $tasksProvider, ')
          ..write('launchCount: $launchCount, ')
          ..write('reviewRequested: $reviewRequested')
          ..write(')'))
        .toString();
  }
}

class $SingleEventRowsTable extends SingleEventRows
    with TableInfo<$SingleEventRowsTable, SingleEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SingleEventRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _isDebitMeta = const VerificationMeta(
    'isDebit',
  );
  @override
  late final GeneratedColumn<bool> isDebit = GeneratedColumn<bool>(
    'is_debit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_debit" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdDateMeta = const VerificationMeta(
    'createdDate',
  );
  @override
  late final GeneratedColumn<DateTime> createdDate = GeneratedColumn<DateTime>(
    'created_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _appliedAmountMeta = const VerificationMeta(
    'appliedAmount',
  );
  @override
  late final GeneratedColumn<double> appliedAmount = GeneratedColumn<double>(
    'applied_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EventTarget, String> target =
      GeneratedColumn<String>(
        'target',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EventTarget>($SingleEventRowsTable.$convertertarget);
  static const VerificationMeta _targetNameMeta = const VerificationMeta(
    'targetName',
  );
  @override
  late final GeneratedColumn<String> targetName = GeneratedColumn<String>(
    'target_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amount,
    isDebit,
    createdDate,
    lastModifiedDate,
    appliedAmount,
    target,
    targetName,
    targetId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'single_event_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SingleEventRow> instance, {
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
    if (data.containsKey('is_debit')) {
      context.handle(
        _isDebitMeta,
        isDebit.isAcceptableOrUnknown(data['is_debit']!, _isDebitMeta),
      );
    } else if (isInserting) {
      context.missing(_isDebitMeta);
    }
    if (data.containsKey('created_date')) {
      context.handle(
        _createdDateMeta,
        createdDate.isAcceptableOrUnknown(
          data['created_date']!,
          _createdDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdDateMeta);
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedDateMeta);
    }
    if (data.containsKey('applied_amount')) {
      context.handle(
        _appliedAmountMeta,
        appliedAmount.isAcceptableOrUnknown(
          data['applied_amount']!,
          _appliedAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appliedAmountMeta);
    }
    if (data.containsKey('target_name')) {
      context.handle(
        _targetNameMeta,
        targetName.isAcceptableOrUnknown(data['target_name']!, _targetNameMeta),
      );
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SingleEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SingleEventRow(
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
      isDebit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_debit'],
      )!,
      createdDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_date'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      appliedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}applied_amount'],
      )!,
      target: $SingleEventRowsTable.$convertertarget.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}target'],
        )!,
      ),
      targetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_name'],
      ),
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      ),
    );
  }

  @override
  $SingleEventRowsTable createAlias(String alias) {
    return $SingleEventRowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EventTarget, String, String> $convertertarget =
      const EnumNameConverter<EventTarget>(EventTarget.values);
}

class SingleEventRow extends DataClass implements Insertable<SingleEventRow> {
  final int id;
  final String name;
  final double amount;
  final bool isDebit;
  final DateTime createdDate;
  final DateTime lastModifiedDate;
  final double appliedAmount;
  final EventTarget target;
  final String? targetName;
  final String? targetId;
  const SingleEventRow({
    required this.id,
    required this.name,
    required this.amount,
    required this.isDebit,
    required this.createdDate,
    required this.lastModifiedDate,
    required this.appliedAmount,
    required this.target,
    this.targetName,
    this.targetId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    map['is_debit'] = Variable<bool>(isDebit);
    map['created_date'] = Variable<DateTime>(createdDate);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['applied_amount'] = Variable<double>(appliedAmount);
    {
      map['target'] = Variable<String>(
        $SingleEventRowsTable.$convertertarget.toSql(target),
      );
    }
    if (!nullToAbsent || targetName != null) {
      map['target_name'] = Variable<String>(targetName);
    }
    if (!nullToAbsent || targetId != null) {
      map['target_id'] = Variable<String>(targetId);
    }
    return map;
  }

  SingleEventRowsCompanion toCompanion(bool nullToAbsent) {
    return SingleEventRowsCompanion(
      id: Value(id),
      name: Value(name),
      amount: Value(amount),
      isDebit: Value(isDebit),
      createdDate: Value(createdDate),
      lastModifiedDate: Value(lastModifiedDate),
      appliedAmount: Value(appliedAmount),
      target: Value(target),
      targetName: targetName == null && nullToAbsent
          ? const Value.absent()
          : Value(targetName),
      targetId: targetId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetId),
    );
  }

  factory SingleEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SingleEventRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      isDebit: serializer.fromJson<bool>(json['isDebit']),
      createdDate: serializer.fromJson<DateTime>(json['createdDate']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      appliedAmount: serializer.fromJson<double>(json['appliedAmount']),
      target: $SingleEventRowsTable.$convertertarget.fromJson(
        serializer.fromJson<String>(json['target']),
      ),
      targetName: serializer.fromJson<String?>(json['targetName']),
      targetId: serializer.fromJson<String?>(json['targetId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'isDebit': serializer.toJson<bool>(isDebit),
      'createdDate': serializer.toJson<DateTime>(createdDate),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'appliedAmount': serializer.toJson<double>(appliedAmount),
      'target': serializer.toJson<String>(
        $SingleEventRowsTable.$convertertarget.toJson(target),
      ),
      'targetName': serializer.toJson<String?>(targetName),
      'targetId': serializer.toJson<String?>(targetId),
    };
  }

  SingleEventRow copyWith({
    int? id,
    String? name,
    double? amount,
    bool? isDebit,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
    double? appliedAmount,
    EventTarget? target,
    Value<String?> targetName = const Value.absent(),
    Value<String?> targetId = const Value.absent(),
  }) => SingleEventRow(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    isDebit: isDebit ?? this.isDebit,
    createdDate: createdDate ?? this.createdDate,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    appliedAmount: appliedAmount ?? this.appliedAmount,
    target: target ?? this.target,
    targetName: targetName.present ? targetName.value : this.targetName,
    targetId: targetId.present ? targetId.value : this.targetId,
  );
  SingleEventRow copyWithCompanion(SingleEventRowsCompanion data) {
    return SingleEventRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      isDebit: data.isDebit.present ? data.isDebit.value : this.isDebit,
      createdDate: data.createdDate.present
          ? data.createdDate.value
          : this.createdDate,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      appliedAmount: data.appliedAmount.present
          ? data.appliedAmount.value
          : this.appliedAmount,
      target: data.target.present ? data.target.value : this.target,
      targetName: data.targetName.present
          ? data.targetName.value
          : this.targetName,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SingleEventRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('isDebit: $isDebit, ')
          ..write('createdDate: $createdDate, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('appliedAmount: $appliedAmount, ')
          ..write('target: $target, ')
          ..write('targetName: $targetName, ')
          ..write('targetId: $targetId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    isDebit,
    createdDate,
    lastModifiedDate,
    appliedAmount,
    target,
    targetName,
    targetId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SingleEventRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.isDebit == this.isDebit &&
          other.createdDate == this.createdDate &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.appliedAmount == this.appliedAmount &&
          other.target == this.target &&
          other.targetName == this.targetName &&
          other.targetId == this.targetId);
}

class SingleEventRowsCompanion extends UpdateCompanion<SingleEventRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> amount;
  final Value<bool> isDebit;
  final Value<DateTime> createdDate;
  final Value<DateTime> lastModifiedDate;
  final Value<double> appliedAmount;
  final Value<EventTarget> target;
  final Value<String?> targetName;
  final Value<String?> targetId;
  const SingleEventRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.isDebit = const Value.absent(),
    this.createdDate = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.appliedAmount = const Value.absent(),
    this.target = const Value.absent(),
    this.targetName = const Value.absent(),
    this.targetId = const Value.absent(),
  });
  SingleEventRowsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double amount,
    required bool isDebit,
    required DateTime createdDate,
    required DateTime lastModifiedDate,
    required double appliedAmount,
    required EventTarget target,
    this.targetName = const Value.absent(),
    this.targetId = const Value.absent(),
  }) : name = Value(name),
       amount = Value(amount),
       isDebit = Value(isDebit),
       createdDate = Value(createdDate),
       lastModifiedDate = Value(lastModifiedDate),
       appliedAmount = Value(appliedAmount),
       target = Value(target);
  static Insertable<SingleEventRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<bool>? isDebit,
    Expression<DateTime>? createdDate,
    Expression<DateTime>? lastModifiedDate,
    Expression<double>? appliedAmount,
    Expression<String>? target,
    Expression<String>? targetName,
    Expression<String>? targetId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (isDebit != null) 'is_debit': isDebit,
      if (createdDate != null) 'created_date': createdDate,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (appliedAmount != null) 'applied_amount': appliedAmount,
      if (target != null) 'target': target,
      if (targetName != null) 'target_name': targetName,
      if (targetId != null) 'target_id': targetId,
    });
  }

  SingleEventRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? amount,
    Value<bool>? isDebit,
    Value<DateTime>? createdDate,
    Value<DateTime>? lastModifiedDate,
    Value<double>? appliedAmount,
    Value<EventTarget>? target,
    Value<String?>? targetName,
    Value<String?>? targetId,
  }) {
    return SingleEventRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isDebit: isDebit ?? this.isDebit,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      appliedAmount: appliedAmount ?? this.appliedAmount,
      target: target ?? this.target,
      targetName: targetName ?? this.targetName,
      targetId: targetId ?? this.targetId,
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
    if (isDebit.present) {
      map['is_debit'] = Variable<bool>(isDebit.value);
    }
    if (createdDate.present) {
      map['created_date'] = Variable<DateTime>(createdDate.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (appliedAmount.present) {
      map['applied_amount'] = Variable<double>(appliedAmount.value);
    }
    if (target.present) {
      map['target'] = Variable<String>(
        $SingleEventRowsTable.$convertertarget.toSql(target.value),
      );
    }
    if (targetName.present) {
      map['target_name'] = Variable<String>(targetName.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SingleEventRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('isDebit: $isDebit, ')
          ..write('createdDate: $createdDate, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('appliedAmount: $appliedAmount, ')
          ..write('target: $target, ')
          ..write('targetName: $targetName, ')
          ..write('targetId: $targetId')
          ..write(')'))
        .toString();
  }
}

class $PeriodSnapshotRowsTable extends PeriodSnapshotRows
    with TableInfo<$PeriodSnapshotRowsTable, PeriodSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodSnapshotRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<DateTime> start = GeneratedColumn<DateTime>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _totalIncomeMeta = const VerificationMeta(
    'totalIncome',
  );
  @override
  late final GeneratedColumn<double> totalIncome = GeneratedColumn<double>(
    'total_income',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalExpensesMeta = const VerificationMeta(
    'totalExpenses',
  );
  @override
  late final GeneratedColumn<double> totalExpenses = GeneratedColumn<double>(
    'total_expenses',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, start, totalIncome, totalExpenses];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'period_snapshot_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeriodSnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('total_income')) {
      context.handle(
        _totalIncomeMeta,
        totalIncome.isAcceptableOrUnknown(
          data['total_income']!,
          _totalIncomeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalIncomeMeta);
    }
    if (data.containsKey('total_expenses')) {
      context.handle(
        _totalExpensesMeta,
        totalExpenses.isAcceptableOrUnknown(
          data['total_expenses']!,
          _totalExpensesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalExpensesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeriodSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeriodSnapshotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start'],
      )!,
      totalIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_income'],
      )!,
      totalExpenses: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_expenses'],
      )!,
    );
  }

  @override
  $PeriodSnapshotRowsTable createAlias(String alias) {
    return $PeriodSnapshotRowsTable(attachedDatabase, alias);
  }
}

class PeriodSnapshotRow extends DataClass
    implements Insertable<PeriodSnapshotRow> {
  final int id;
  final DateTime start;
  final double totalIncome;
  final double totalExpenses;
  const PeriodSnapshotRow({
    required this.id,
    required this.start,
    required this.totalIncome,
    required this.totalExpenses,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start'] = Variable<DateTime>(start);
    map['total_income'] = Variable<double>(totalIncome);
    map['total_expenses'] = Variable<double>(totalExpenses);
    return map;
  }

  PeriodSnapshotRowsCompanion toCompanion(bool nullToAbsent) {
    return PeriodSnapshotRowsCompanion(
      id: Value(id),
      start: Value(start),
      totalIncome: Value(totalIncome),
      totalExpenses: Value(totalExpenses),
    );
  }

  factory PeriodSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodSnapshotRow(
      id: serializer.fromJson<int>(json['id']),
      start: serializer.fromJson<DateTime>(json['start']),
      totalIncome: serializer.fromJson<double>(json['totalIncome']),
      totalExpenses: serializer.fromJson<double>(json['totalExpenses']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'start': serializer.toJson<DateTime>(start),
      'totalIncome': serializer.toJson<double>(totalIncome),
      'totalExpenses': serializer.toJson<double>(totalExpenses),
    };
  }

  PeriodSnapshotRow copyWith({
    int? id,
    DateTime? start,
    double? totalIncome,
    double? totalExpenses,
  }) => PeriodSnapshotRow(
    id: id ?? this.id,
    start: start ?? this.start,
    totalIncome: totalIncome ?? this.totalIncome,
    totalExpenses: totalExpenses ?? this.totalExpenses,
  );
  PeriodSnapshotRow copyWithCompanion(PeriodSnapshotRowsCompanion data) {
    return PeriodSnapshotRow(
      id: data.id.present ? data.id.value : this.id,
      start: data.start.present ? data.start.value : this.start,
      totalIncome: data.totalIncome.present
          ? data.totalIncome.value
          : this.totalIncome,
      totalExpenses: data.totalExpenses.present
          ? data.totalExpenses.value
          : this.totalExpenses,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodSnapshotRow(')
          ..write('id: $id, ')
          ..write('start: $start, ')
          ..write('totalIncome: $totalIncome, ')
          ..write('totalExpenses: $totalExpenses')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, start, totalIncome, totalExpenses);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodSnapshotRow &&
          other.id == this.id &&
          other.start == this.start &&
          other.totalIncome == this.totalIncome &&
          other.totalExpenses == this.totalExpenses);
}

class PeriodSnapshotRowsCompanion extends UpdateCompanion<PeriodSnapshotRow> {
  final Value<int> id;
  final Value<DateTime> start;
  final Value<double> totalIncome;
  final Value<double> totalExpenses;
  const PeriodSnapshotRowsCompanion({
    this.id = const Value.absent(),
    this.start = const Value.absent(),
    this.totalIncome = const Value.absent(),
    this.totalExpenses = const Value.absent(),
  });
  PeriodSnapshotRowsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime start,
    required double totalIncome,
    required double totalExpenses,
  }) : start = Value(start),
       totalIncome = Value(totalIncome),
       totalExpenses = Value(totalExpenses);
  static Insertable<PeriodSnapshotRow> custom({
    Expression<int>? id,
    Expression<DateTime>? start,
    Expression<double>? totalIncome,
    Expression<double>? totalExpenses,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (start != null) 'start': start,
      if (totalIncome != null) 'total_income': totalIncome,
      if (totalExpenses != null) 'total_expenses': totalExpenses,
    });
  }

  PeriodSnapshotRowsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? start,
    Value<double>? totalIncome,
    Value<double>? totalExpenses,
  }) {
    return PeriodSnapshotRowsCompanion(
      id: id ?? this.id,
      start: start ?? this.start,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (start.present) {
      map['start'] = Variable<DateTime>(start.value);
    }
    if (totalIncome.present) {
      map['total_income'] = Variable<double>(totalIncome.value);
    }
    if (totalExpenses.present) {
      map['total_expenses'] = Variable<double>(totalExpenses.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodSnapshotRowsCompanion(')
          ..write('id: $id, ')
          ..write('start: $start, ')
          ..write('totalIncome: $totalIncome, ')
          ..write('totalExpenses: $totalExpenses')
          ..write(')'))
        .toString();
  }
}

class $SyncedTaskRowsTable extends SyncedTaskRows
    with TableInfo<$SyncedTaskRowsTable, SyncedTaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncedTaskRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [taskId, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'synced_task_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncedTaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId};
  @override
  SyncedTaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncedTaskRow(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  $SyncedTaskRowsTable createAlias(String alias) {
    return $SyncedTaskRowsTable(attachedDatabase, alias);
  }
}

class SyncedTaskRow extends DataClass implements Insertable<SyncedTaskRow> {
  final String taskId;
  final String body;
  const SyncedTaskRow({required this.taskId, required this.body});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['body'] = Variable<String>(body);
    return map;
  }

  SyncedTaskRowsCompanion toCompanion(bool nullToAbsent) {
    return SyncedTaskRowsCompanion(taskId: Value(taskId), body: Value(body));
  }

  factory SyncedTaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncedTaskRow(
      taskId: serializer.fromJson<String>(json['taskId']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'body': serializer.toJson<String>(body),
    };
  }

  SyncedTaskRow copyWith({String? taskId, String? body}) =>
      SyncedTaskRow(taskId: taskId ?? this.taskId, body: body ?? this.body);
  SyncedTaskRow copyWithCompanion(SyncedTaskRowsCompanion data) {
    return SyncedTaskRow(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncedTaskRow(')
          ..write('taskId: $taskId, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncedTaskRow &&
          other.taskId == this.taskId &&
          other.body == this.body);
}

class SyncedTaskRowsCompanion extends UpdateCompanion<SyncedTaskRow> {
  final Value<String> taskId;
  final Value<String> body;
  final Value<int> rowid;
  const SyncedTaskRowsCompanion({
    this.taskId = const Value.absent(),
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncedTaskRowsCompanion.insert({
    required String taskId,
    required String body,
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       body = Value(body);
  static Insertable<SyncedTaskRow> custom({
    Expression<String>? taskId,
    Expression<String>? body,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncedTaskRowsCompanion copyWith({
    Value<String>? taskId,
    Value<String>? body,
    Value<int>? rowid,
  }) {
    return SyncedTaskRowsCompanion(
      taskId: taskId ?? this.taskId,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncedTaskRowsCompanion(')
          ..write('taskId: $taskId, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ManualAccountRowsTable extends ManualAccountRows
    with TableInfo<$ManualAccountRowsTable, ManualAccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ManualAccountRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _accountTypeMeta = const VerificationMeta(
    'accountType',
  );
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
    'account_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countsTowardBalanceMeta =
      const VerificationMeta('countsTowardBalance');
  @override
  late final GeneratedColumn<bool> countsTowardBalance = GeneratedColumn<bool>(
    'counts_toward_balance',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("counts_toward_balance" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    position,
    name,
    accountType,
    balance,
    countsTowardBalance,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'manual_account_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ManualAccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('account_type')) {
      context.handle(
        _accountTypeMeta,
        accountType.isAcceptableOrUnknown(
          data['account_type']!,
          _accountTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('counts_toward_balance')) {
      context.handle(
        _countsTowardBalanceMeta,
        countsTowardBalance.isAcceptableOrUnknown(
          data['counts_toward_balance']!,
          _countsTowardBalanceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ManualAccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ManualAccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      accountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_type'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      )!,
      countsTowardBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}counts_toward_balance'],
      )!,
    );
  }

  @override
  $ManualAccountRowsTable createAlias(String alias) {
    return $ManualAccountRowsTable(attachedDatabase, alias);
  }
}

class ManualAccountRow extends DataClass
    implements Insertable<ManualAccountRow> {
  final String id;
  final int position;
  final String name;
  final String accountType;
  final double balance;
  final bool countsTowardBalance;
  const ManualAccountRow({
    required this.id,
    required this.position,
    required this.name,
    required this.accountType,
    required this.balance,
    required this.countsTowardBalance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['position'] = Variable<int>(position);
    map['name'] = Variable<String>(name);
    map['account_type'] = Variable<String>(accountType);
    map['balance'] = Variable<double>(balance);
    map['counts_toward_balance'] = Variable<bool>(countsTowardBalance);
    return map;
  }

  ManualAccountRowsCompanion toCompanion(bool nullToAbsent) {
    return ManualAccountRowsCompanion(
      id: Value(id),
      position: Value(position),
      name: Value(name),
      accountType: Value(accountType),
      balance: Value(balance),
      countsTowardBalance: Value(countsTowardBalance),
    );
  }

  factory ManualAccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ManualAccountRow(
      id: serializer.fromJson<String>(json['id']),
      position: serializer.fromJson<int>(json['position']),
      name: serializer.fromJson<String>(json['name']),
      accountType: serializer.fromJson<String>(json['accountType']),
      balance: serializer.fromJson<double>(json['balance']),
      countsTowardBalance: serializer.fromJson<bool>(
        json['countsTowardBalance'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'position': serializer.toJson<int>(position),
      'name': serializer.toJson<String>(name),
      'accountType': serializer.toJson<String>(accountType),
      'balance': serializer.toJson<double>(balance),
      'countsTowardBalance': serializer.toJson<bool>(countsTowardBalance),
    };
  }

  ManualAccountRow copyWith({
    String? id,
    int? position,
    String? name,
    String? accountType,
    double? balance,
    bool? countsTowardBalance,
  }) => ManualAccountRow(
    id: id ?? this.id,
    position: position ?? this.position,
    name: name ?? this.name,
    accountType: accountType ?? this.accountType,
    balance: balance ?? this.balance,
    countsTowardBalance: countsTowardBalance ?? this.countsTowardBalance,
  );
  ManualAccountRow copyWithCompanion(ManualAccountRowsCompanion data) {
    return ManualAccountRow(
      id: data.id.present ? data.id.value : this.id,
      position: data.position.present ? data.position.value : this.position,
      name: data.name.present ? data.name.value : this.name,
      accountType: data.accountType.present
          ? data.accountType.value
          : this.accountType,
      balance: data.balance.present ? data.balance.value : this.balance,
      countsTowardBalance: data.countsTowardBalance.present
          ? data.countsTowardBalance.value
          : this.countsTowardBalance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ManualAccountRow(')
          ..write('id: $id, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('accountType: $accountType, ')
          ..write('balance: $balance, ')
          ..write('countsTowardBalance: $countsTowardBalance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    position,
    name,
    accountType,
    balance,
    countsTowardBalance,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ManualAccountRow &&
          other.id == this.id &&
          other.position == this.position &&
          other.name == this.name &&
          other.accountType == this.accountType &&
          other.balance == this.balance &&
          other.countsTowardBalance == this.countsTowardBalance);
}

class ManualAccountRowsCompanion extends UpdateCompanion<ManualAccountRow> {
  final Value<String> id;
  final Value<int> position;
  final Value<String> name;
  final Value<String> accountType;
  final Value<double> balance;
  final Value<bool> countsTowardBalance;
  final Value<int> rowid;
  const ManualAccountRowsCompanion({
    this.id = const Value.absent(),
    this.position = const Value.absent(),
    this.name = const Value.absent(),
    this.accountType = const Value.absent(),
    this.balance = const Value.absent(),
    this.countsTowardBalance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ManualAccountRowsCompanion.insert({
    required String id,
    required int position,
    required String name,
    required String accountType,
    required double balance,
    this.countsTowardBalance = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       position = Value(position),
       name = Value(name),
       accountType = Value(accountType),
       balance = Value(balance);
  static Insertable<ManualAccountRow> custom({
    Expression<String>? id,
    Expression<int>? position,
    Expression<String>? name,
    Expression<String>? accountType,
    Expression<double>? balance,
    Expression<bool>? countsTowardBalance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (position != null) 'position': position,
      if (name != null) 'name': name,
      if (accountType != null) 'account_type': accountType,
      if (balance != null) 'balance': balance,
      if (countsTowardBalance != null)
        'counts_toward_balance': countsTowardBalance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ManualAccountRowsCompanion copyWith({
    Value<String>? id,
    Value<int>? position,
    Value<String>? name,
    Value<String>? accountType,
    Value<double>? balance,
    Value<bool>? countsTowardBalance,
    Value<int>? rowid,
  }) {
    return ManualAccountRowsCompanion(
      id: id ?? this.id,
      position: position ?? this.position,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      balance: balance ?? this.balance,
      countsTowardBalance: countsTowardBalance ?? this.countsTowardBalance,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (countsTowardBalance.present) {
      map['counts_toward_balance'] = Variable<bool>(countsTowardBalance.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ManualAccountRowsCompanion(')
          ..write('id: $id, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('accountType: $accountType, ')
          ..write('balance: $balance, ')
          ..write('countsTowardBalance: $countsTowardBalance, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LinkedItemRowsTable extends LinkedItemRows
    with TableInfo<$LinkedItemRowsTable, LinkedItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LinkedItemRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accessTokenMeta = const VerificationMeta(
    'accessToken',
  );
  @override
  late final GeneratedColumn<String> accessToken = GeneratedColumn<String>(
    'access_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _institutionMeta = const VerificationMeta(
    'institution',
  );
  @override
  late final GeneratedColumn<String> institution = GeneratedColumn<String>(
    'institution',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(""),
  );
  static const VerificationMeta _needsRelinkMeta = const VerificationMeta(
    'needsRelink',
  );
  @override
  late final GeneratedColumn<bool> needsRelink = GeneratedColumn<bool>(
    'needs_relink',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_relink" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    accessToken,
    institution,
    needsRelink,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'linked_item_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinkedItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('access_token')) {
      context.handle(
        _accessTokenMeta,
        accessToken.isAcceptableOrUnknown(
          data['access_token']!,
          _accessTokenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accessTokenMeta);
    }
    if (data.containsKey('institution')) {
      context.handle(
        _institutionMeta,
        institution.isAcceptableOrUnknown(
          data['institution']!,
          _institutionMeta,
        ),
      );
    }
    if (data.containsKey('needs_relink')) {
      context.handle(
        _needsRelinkMeta,
        needsRelink.isAcceptableOrUnknown(
          data['needs_relink']!,
          _needsRelinkMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LinkedItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinkedItemRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      accessToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_token'],
      )!,
      institution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institution'],
      )!,
      needsRelink: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_relink'],
      )!,
    );
  }

  @override
  $LinkedItemRowsTable createAlias(String alias) {
    return $LinkedItemRowsTable(attachedDatabase, alias);
  }
}

class LinkedItemRow extends DataClass implements Insertable<LinkedItemRow> {
  final String key;
  final String accessToken;
  final String institution;
  final bool needsRelink;
  const LinkedItemRow({
    required this.key,
    required this.accessToken,
    required this.institution,
    required this.needsRelink,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['access_token'] = Variable<String>(accessToken);
    map['institution'] = Variable<String>(institution);
    map['needs_relink'] = Variable<bool>(needsRelink);
    return map;
  }

  LinkedItemRowsCompanion toCompanion(bool nullToAbsent) {
    return LinkedItemRowsCompanion(
      key: Value(key),
      accessToken: Value(accessToken),
      institution: Value(institution),
      needsRelink: Value(needsRelink),
    );
  }

  factory LinkedItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinkedItemRow(
      key: serializer.fromJson<String>(json['key']),
      accessToken: serializer.fromJson<String>(json['accessToken']),
      institution: serializer.fromJson<String>(json['institution']),
      needsRelink: serializer.fromJson<bool>(json['needsRelink']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'accessToken': serializer.toJson<String>(accessToken),
      'institution': serializer.toJson<String>(institution),
      'needsRelink': serializer.toJson<bool>(needsRelink),
    };
  }

  LinkedItemRow copyWith({
    String? key,
    String? accessToken,
    String? institution,
    bool? needsRelink,
  }) => LinkedItemRow(
    key: key ?? this.key,
    accessToken: accessToken ?? this.accessToken,
    institution: institution ?? this.institution,
    needsRelink: needsRelink ?? this.needsRelink,
  );
  LinkedItemRow copyWithCompanion(LinkedItemRowsCompanion data) {
    return LinkedItemRow(
      key: data.key.present ? data.key.value : this.key,
      accessToken: data.accessToken.present
          ? data.accessToken.value
          : this.accessToken,
      institution: data.institution.present
          ? data.institution.value
          : this.institution,
      needsRelink: data.needsRelink.present
          ? data.needsRelink.value
          : this.needsRelink,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinkedItemRow(')
          ..write('key: $key, ')
          ..write('accessToken: $accessToken, ')
          ..write('institution: $institution, ')
          ..write('needsRelink: $needsRelink')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, accessToken, institution, needsRelink);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinkedItemRow &&
          other.key == this.key &&
          other.accessToken == this.accessToken &&
          other.institution == this.institution &&
          other.needsRelink == this.needsRelink);
}

class LinkedItemRowsCompanion extends UpdateCompanion<LinkedItemRow> {
  final Value<String> key;
  final Value<String> accessToken;
  final Value<String> institution;
  final Value<bool> needsRelink;
  final Value<int> rowid;
  const LinkedItemRowsCompanion({
    this.key = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.institution = const Value.absent(),
    this.needsRelink = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LinkedItemRowsCompanion.insert({
    required String key,
    required String accessToken,
    this.institution = const Value.absent(),
    this.needsRelink = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       accessToken = Value(accessToken);
  static Insertable<LinkedItemRow> custom({
    Expression<String>? key,
    Expression<String>? accessToken,
    Expression<String>? institution,
    Expression<bool>? needsRelink,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (accessToken != null) 'access_token': accessToken,
      if (institution != null) 'institution': institution,
      if (needsRelink != null) 'needs_relink': needsRelink,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LinkedItemRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? accessToken,
    Value<String>? institution,
    Value<bool>? needsRelink,
    Value<int>? rowid,
  }) {
    return LinkedItemRowsCompanion(
      key: key ?? this.key,
      accessToken: accessToken ?? this.accessToken,
      institution: institution ?? this.institution,
      needsRelink: needsRelink ?? this.needsRelink,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (accessToken.present) {
      map['access_token'] = Variable<String>(accessToken.value);
    }
    if (institution.present) {
      map['institution'] = Variable<String>(institution.value);
    }
    if (needsRelink.present) {
      map['needs_relink'] = Variable<bool>(needsRelink.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LinkedItemRowsCompanion(')
          ..write('key: $key, ')
          ..write('accessToken: $accessToken, ')
          ..write('institution: $institution, ')
          ..write('needsRelink: $needsRelink, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LinkedAccountRowsTable extends LinkedAccountRows
    with TableInfo<$LinkedAccountRowsTable, LinkedAccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LinkedAccountRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemKeyMeta = const VerificationMeta(
    'itemKey',
  );
  @override
  late final GeneratedColumn<String> itemKey = GeneratedColumn<String>(
    'item_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtypeMeta = const VerificationMeta(
    'subtype',
  );
  @override
  late final GeneratedColumn<String> subtype = GeneratedColumn<String>(
    'subtype',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maskMeta = const VerificationMeta('mask');
  @override
  late final GeneratedColumn<String> mask = GeneratedColumn<String>(
    'mask',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _institutionMeta = const VerificationMeta(
    'institution',
  );
  @override
  late final GeneratedColumn<String> institution = GeneratedColumn<String>(
    'institution',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ledgerMeta = const VerificationMeta('ledger');
  @override
  late final GeneratedColumn<double> ledger = GeneratedColumn<double>(
    'ledger',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _availableMeta = const VerificationMeta(
    'available',
  );
  @override
  late final GeneratedColumn<double> available = GeneratedColumn<double>(
    'available',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
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
  static const VerificationMeta _countsTowardBalanceMeta =
      const VerificationMeta('countsTowardBalance');
  @override
  late final GeneratedColumn<bool> countsTowardBalance = GeneratedColumn<bool>(
    'counts_toward_balance',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("counts_toward_balance" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemKey,
    position,
    name,
    type,
    subtype,
    mask,
    institution,
    ledger,
    available,
    creditLimit,
    countsTowardBalance,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'linked_account_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinkedAccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_key')) {
      context.handle(
        _itemKeyMeta,
        itemKey.isAcceptableOrUnknown(data['item_key']!, _itemKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_itemKeyMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('subtype')) {
      context.handle(
        _subtypeMeta,
        subtype.isAcceptableOrUnknown(data['subtype']!, _subtypeMeta),
      );
    } else if (isInserting) {
      context.missing(_subtypeMeta);
    }
    if (data.containsKey('mask')) {
      context.handle(
        _maskMeta,
        mask.isAcceptableOrUnknown(data['mask']!, _maskMeta),
      );
    } else if (isInserting) {
      context.missing(_maskMeta);
    }
    if (data.containsKey('institution')) {
      context.handle(
        _institutionMeta,
        institution.isAcceptableOrUnknown(
          data['institution']!,
          _institutionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_institutionMeta);
    }
    if (data.containsKey('ledger')) {
      context.handle(
        _ledgerMeta,
        ledger.isAcceptableOrUnknown(data['ledger']!, _ledgerMeta),
      );
    }
    if (data.containsKey('available')) {
      context.handle(
        _availableMeta,
        available.isAcceptableOrUnknown(data['available']!, _availableMeta),
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
    if (data.containsKey('counts_toward_balance')) {
      context.handle(
        _countsTowardBalanceMeta,
        countsTowardBalance.isAcceptableOrUnknown(
          data['counts_toward_balance']!,
          _countsTowardBalanceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LinkedAccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinkedAccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_key'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      subtype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtype'],
      )!,
      mask: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mask'],
      )!,
      institution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institution'],
      )!,
      ledger: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ledger'],
      ),
      available: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}available'],
      ),
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}credit_limit'],
      ),
      countsTowardBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}counts_toward_balance'],
      )!,
    );
  }

  @override
  $LinkedAccountRowsTable createAlias(String alias) {
    return $LinkedAccountRowsTable(attachedDatabase, alias);
  }
}

class LinkedAccountRow extends DataClass
    implements Insertable<LinkedAccountRow> {
  final String id;
  final String itemKey;
  final int position;
  final String name;
  final String type;
  final String subtype;
  final String mask;
  final String institution;
  final double? ledger;
  final double? available;
  final double? creditLimit;
  final bool countsTowardBalance;
  const LinkedAccountRow({
    required this.id,
    required this.itemKey,
    required this.position,
    required this.name,
    required this.type,
    required this.subtype,
    required this.mask,
    required this.institution,
    this.ledger,
    this.available,
    this.creditLimit,
    required this.countsTowardBalance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_key'] = Variable<String>(itemKey);
    map['position'] = Variable<int>(position);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['subtype'] = Variable<String>(subtype);
    map['mask'] = Variable<String>(mask);
    map['institution'] = Variable<String>(institution);
    if (!nullToAbsent || ledger != null) {
      map['ledger'] = Variable<double>(ledger);
    }
    if (!nullToAbsent || available != null) {
      map['available'] = Variable<double>(available);
    }
    if (!nullToAbsent || creditLimit != null) {
      map['credit_limit'] = Variable<double>(creditLimit);
    }
    map['counts_toward_balance'] = Variable<bool>(countsTowardBalance);
    return map;
  }

  LinkedAccountRowsCompanion toCompanion(bool nullToAbsent) {
    return LinkedAccountRowsCompanion(
      id: Value(id),
      itemKey: Value(itemKey),
      position: Value(position),
      name: Value(name),
      type: Value(type),
      subtype: Value(subtype),
      mask: Value(mask),
      institution: Value(institution),
      ledger: ledger == null && nullToAbsent
          ? const Value.absent()
          : Value(ledger),
      available: available == null && nullToAbsent
          ? const Value.absent()
          : Value(available),
      creditLimit: creditLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimit),
      countsTowardBalance: Value(countsTowardBalance),
    );
  }

  factory LinkedAccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinkedAccountRow(
      id: serializer.fromJson<String>(json['id']),
      itemKey: serializer.fromJson<String>(json['itemKey']),
      position: serializer.fromJson<int>(json['position']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      subtype: serializer.fromJson<String>(json['subtype']),
      mask: serializer.fromJson<String>(json['mask']),
      institution: serializer.fromJson<String>(json['institution']),
      ledger: serializer.fromJson<double?>(json['ledger']),
      available: serializer.fromJson<double?>(json['available']),
      creditLimit: serializer.fromJson<double?>(json['creditLimit']),
      countsTowardBalance: serializer.fromJson<bool>(
        json['countsTowardBalance'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemKey': serializer.toJson<String>(itemKey),
      'position': serializer.toJson<int>(position),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'subtype': serializer.toJson<String>(subtype),
      'mask': serializer.toJson<String>(mask),
      'institution': serializer.toJson<String>(institution),
      'ledger': serializer.toJson<double?>(ledger),
      'available': serializer.toJson<double?>(available),
      'creditLimit': serializer.toJson<double?>(creditLimit),
      'countsTowardBalance': serializer.toJson<bool>(countsTowardBalance),
    };
  }

  LinkedAccountRow copyWith({
    String? id,
    String? itemKey,
    int? position,
    String? name,
    String? type,
    String? subtype,
    String? mask,
    String? institution,
    Value<double?> ledger = const Value.absent(),
    Value<double?> available = const Value.absent(),
    Value<double?> creditLimit = const Value.absent(),
    bool? countsTowardBalance,
  }) => LinkedAccountRow(
    id: id ?? this.id,
    itemKey: itemKey ?? this.itemKey,
    position: position ?? this.position,
    name: name ?? this.name,
    type: type ?? this.type,
    subtype: subtype ?? this.subtype,
    mask: mask ?? this.mask,
    institution: institution ?? this.institution,
    ledger: ledger.present ? ledger.value : this.ledger,
    available: available.present ? available.value : this.available,
    creditLimit: creditLimit.present ? creditLimit.value : this.creditLimit,
    countsTowardBalance: countsTowardBalance ?? this.countsTowardBalance,
  );
  LinkedAccountRow copyWithCompanion(LinkedAccountRowsCompanion data) {
    return LinkedAccountRow(
      id: data.id.present ? data.id.value : this.id,
      itemKey: data.itemKey.present ? data.itemKey.value : this.itemKey,
      position: data.position.present ? data.position.value : this.position,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      subtype: data.subtype.present ? data.subtype.value : this.subtype,
      mask: data.mask.present ? data.mask.value : this.mask,
      institution: data.institution.present
          ? data.institution.value
          : this.institution,
      ledger: data.ledger.present ? data.ledger.value : this.ledger,
      available: data.available.present ? data.available.value : this.available,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      countsTowardBalance: data.countsTowardBalance.present
          ? data.countsTowardBalance.value
          : this.countsTowardBalance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinkedAccountRow(')
          ..write('id: $id, ')
          ..write('itemKey: $itemKey, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('subtype: $subtype, ')
          ..write('mask: $mask, ')
          ..write('institution: $institution, ')
          ..write('ledger: $ledger, ')
          ..write('available: $available, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('countsTowardBalance: $countsTowardBalance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemKey,
    position,
    name,
    type,
    subtype,
    mask,
    institution,
    ledger,
    available,
    creditLimit,
    countsTowardBalance,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinkedAccountRow &&
          other.id == this.id &&
          other.itemKey == this.itemKey &&
          other.position == this.position &&
          other.name == this.name &&
          other.type == this.type &&
          other.subtype == this.subtype &&
          other.mask == this.mask &&
          other.institution == this.institution &&
          other.ledger == this.ledger &&
          other.available == this.available &&
          other.creditLimit == this.creditLimit &&
          other.countsTowardBalance == this.countsTowardBalance);
}

class LinkedAccountRowsCompanion extends UpdateCompanion<LinkedAccountRow> {
  final Value<String> id;
  final Value<String> itemKey;
  final Value<int> position;
  final Value<String> name;
  final Value<String> type;
  final Value<String> subtype;
  final Value<String> mask;
  final Value<String> institution;
  final Value<double?> ledger;
  final Value<double?> available;
  final Value<double?> creditLimit;
  final Value<bool> countsTowardBalance;
  final Value<int> rowid;
  const LinkedAccountRowsCompanion({
    this.id = const Value.absent(),
    this.itemKey = const Value.absent(),
    this.position = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.subtype = const Value.absent(),
    this.mask = const Value.absent(),
    this.institution = const Value.absent(),
    this.ledger = const Value.absent(),
    this.available = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.countsTowardBalance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LinkedAccountRowsCompanion.insert({
    required String id,
    required String itemKey,
    required int position,
    required String name,
    required String type,
    required String subtype,
    required String mask,
    required String institution,
    this.ledger = const Value.absent(),
    this.available = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.countsTowardBalance = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemKey = Value(itemKey),
       position = Value(position),
       name = Value(name),
       type = Value(type),
       subtype = Value(subtype),
       mask = Value(mask),
       institution = Value(institution);
  static Insertable<LinkedAccountRow> custom({
    Expression<String>? id,
    Expression<String>? itemKey,
    Expression<int>? position,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? subtype,
    Expression<String>? mask,
    Expression<String>? institution,
    Expression<double>? ledger,
    Expression<double>? available,
    Expression<double>? creditLimit,
    Expression<bool>? countsTowardBalance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemKey != null) 'item_key': itemKey,
      if (position != null) 'position': position,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (subtype != null) 'subtype': subtype,
      if (mask != null) 'mask': mask,
      if (institution != null) 'institution': institution,
      if (ledger != null) 'ledger': ledger,
      if (available != null) 'available': available,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (countsTowardBalance != null)
        'counts_toward_balance': countsTowardBalance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LinkedAccountRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? itemKey,
    Value<int>? position,
    Value<String>? name,
    Value<String>? type,
    Value<String>? subtype,
    Value<String>? mask,
    Value<String>? institution,
    Value<double?>? ledger,
    Value<double?>? available,
    Value<double?>? creditLimit,
    Value<bool>? countsTowardBalance,
    Value<int>? rowid,
  }) {
    return LinkedAccountRowsCompanion(
      id: id ?? this.id,
      itemKey: itemKey ?? this.itemKey,
      position: position ?? this.position,
      name: name ?? this.name,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      mask: mask ?? this.mask,
      institution: institution ?? this.institution,
      ledger: ledger ?? this.ledger,
      available: available ?? this.available,
      creditLimit: creditLimit ?? this.creditLimit,
      countsTowardBalance: countsTowardBalance ?? this.countsTowardBalance,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemKey.present) {
      map['item_key'] = Variable<String>(itemKey.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (subtype.present) {
      map['subtype'] = Variable<String>(subtype.value);
    }
    if (mask.present) {
      map['mask'] = Variable<String>(mask.value);
    }
    if (institution.present) {
      map['institution'] = Variable<String>(institution.value);
    }
    if (ledger.present) {
      map['ledger'] = Variable<double>(ledger.value);
    }
    if (available.present) {
      map['available'] = Variable<double>(available.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<double>(creditLimit.value);
    }
    if (countsTowardBalance.present) {
      map['counts_toward_balance'] = Variable<bool>(countsTowardBalance.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LinkedAccountRowsCompanion(')
          ..write('id: $id, ')
          ..write('itemKey: $itemKey, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('subtype: $subtype, ')
          ..write('mask: $mask, ')
          ..write('institution: $institution, ')
          ..write('ledger: $ledger, ')
          ..write('available: $available, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('countsTowardBalance: $countsTowardBalance, ')
          ..write('rowid: $rowid')
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
  late final $SingleEventRowsTable singleEventRows = $SingleEventRowsTable(
    this,
  );
  late final $PeriodSnapshotRowsTable periodSnapshotRows =
      $PeriodSnapshotRowsTable(this);
  late final $SyncedTaskRowsTable syncedTaskRows = $SyncedTaskRowsTable(this);
  late final $ManualAccountRowsTable manualAccountRows =
      $ManualAccountRowsTable(this);
  late final $LinkedItemRowsTable linkedItemRows = $LinkedItemRowsTable(this);
  late final $LinkedAccountRowsTable linkedAccountRows =
      $LinkedAccountRowsTable(this);
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
    singleEventRows,
    periodSnapshotRows,
    syncedTaskRows,
    manualAccountRows,
    linkedItemRows,
    linkedAccountRows,
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
      Value<String?> googleTaskId,
      Value<bool> remindInTasks,
      Value<FundingSource> source,
      Value<String?> sourceId,
      Value<String?> linkedAccountId,
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
      Value<String?> googleTaskId,
      Value<bool> remindInTasks,
      Value<FundingSource> source,
      Value<String?> sourceId,
      Value<String?> linkedAccountId,
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

  ColumnFilters<String> get googleTaskId => $composableBuilder(
    column: $table.googleTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remindInTasks => $composableBuilder(
    column: $table.remindInTasks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FundingSource, FundingSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedAccountId => $composableBuilder(
    column: $table.linkedAccountId,
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

  ColumnOrderings<String> get googleTaskId => $composableBuilder(
    column: $table.googleTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remindInTasks => $composableBuilder(
    column: $table.remindInTasks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedAccountId => $composableBuilder(
    column: $table.linkedAccountId,
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

  GeneratedColumn<String> get googleTaskId => $composableBuilder(
    column: $table.googleTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get remindInTasks => $composableBuilder(
    column: $table.remindInTasks,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<FundingSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get linkedAccountId => $composableBuilder(
    column: $table.linkedAccountId,
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
                Value<String?> googleTaskId = const Value.absent(),
                Value<bool> remindInTasks = const Value.absent(),
                Value<FundingSource> source = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> linkedAccountId = const Value.absent(),
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
                googleTaskId: googleTaskId,
                remindInTasks: remindInTasks,
                source: source,
                sourceId: sourceId,
                linkedAccountId: linkedAccountId,
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
                Value<String?> googleTaskId = const Value.absent(),
                Value<bool> remindInTasks = const Value.absent(),
                Value<FundingSource> source = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> linkedAccountId = const Value.absent(),
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
                googleTaskId: googleTaskId,
                remindInTasks: remindInTasks,
                source: source,
                sourceId: sourceId,
                linkedAccountId: linkedAccountId,
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
      Value<String?> googleTaskId,
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
      Value<String?> googleTaskId,
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

  ColumnFilters<String> get googleTaskId => $composableBuilder(
    column: $table.googleTaskId,
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

  ColumnOrderings<String> get googleTaskId => $composableBuilder(
    column: $table.googleTaskId,
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

  GeneratedColumn<String> get googleTaskId => $composableBuilder(
    column: $table.googleTaskId,
    builder: (column) => column,
  );
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
                Value<String?> googleTaskId = const Value.absent(),
              }) => IncomeStreamModelRowsCompanion(
                id: id,
                name: name,
                amount: amount,
                startDate: startDate,
                frequency: frequency,
                frequencyUnits: frequencyUnits,
                isActive: isActive,
                googleTaskId: googleTaskId,
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
                Value<String?> googleTaskId = const Value.absent(),
              }) => IncomeStreamModelRowsCompanion.insert(
                id: id,
                name: name,
                amount: amount,
                startDate: startDate,
                frequency: frequency,
                frequencyUnits: frequencyUnits,
                isActive: isActive,
                googleTaskId: googleTaskId,
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
      Value<double> balanceExtra,
      required DateTime lastUpdated,
      Value<bool> includeNextCheck,
      Value<int> singleEventExpiryDays,
      Value<int> tutorialStep,
      Value<bool> tutorialSeen,
      Value<bool> useCommaSeparators,
      Value<bool> appLockEnabled,
      Value<bool> disclaimerAccepted,
      Value<DateTime?> lastBankSync,
      Value<String> pendingLinkedBalanceIds,
      Value<bool> tasksSyncEnabled,
      Value<String?> tasksListId,
      Value<String?> tasksAccount,
      Value<String> themeMode,
      Value<String> accentColor,
      Value<int> customAccent,
      Value<String> tasksProvider,
      Value<int> launchCount,
      Value<bool> reviewRequested,
    });
typedef $$AppMetaRowsTableUpdateCompanionBuilder =
    AppMetaRowsCompanion Function({
      Value<int> id,
      Value<double> currentBalance,
      Value<double> balanceExtra,
      Value<DateTime> lastUpdated,
      Value<bool> includeNextCheck,
      Value<int> singleEventExpiryDays,
      Value<int> tutorialStep,
      Value<bool> tutorialSeen,
      Value<bool> useCommaSeparators,
      Value<bool> appLockEnabled,
      Value<bool> disclaimerAccepted,
      Value<DateTime?> lastBankSync,
      Value<String> pendingLinkedBalanceIds,
      Value<bool> tasksSyncEnabled,
      Value<String?> tasksListId,
      Value<String?> tasksAccount,
      Value<String> themeMode,
      Value<String> accentColor,
      Value<int> customAccent,
      Value<String> tasksProvider,
      Value<int> launchCount,
      Value<bool> reviewRequested,
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

  ColumnFilters<double> get balanceExtra => $composableBuilder(
    column: $table.balanceExtra,
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

  ColumnFilters<int> get singleEventExpiryDays => $composableBuilder(
    column: $table.singleEventExpiryDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tutorialStep => $composableBuilder(
    column: $table.tutorialStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tutorialSeen => $composableBuilder(
    column: $table.tutorialSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useCommaSeparators => $composableBuilder(
    column: $table.useCommaSeparators,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get appLockEnabled => $composableBuilder(
    column: $table.appLockEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get disclaimerAccepted => $composableBuilder(
    column: $table.disclaimerAccepted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastBankSync => $composableBuilder(
    column: $table.lastBankSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pendingLinkedBalanceIds => $composableBuilder(
    column: $table.pendingLinkedBalanceIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tasksSyncEnabled => $composableBuilder(
    column: $table.tasksSyncEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tasksListId => $composableBuilder(
    column: $table.tasksListId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tasksAccount => $composableBuilder(
    column: $table.tasksAccount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accentColor => $composableBuilder(
    column: $table.accentColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get customAccent => $composableBuilder(
    column: $table.customAccent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tasksProvider => $composableBuilder(
    column: $table.tasksProvider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get launchCount => $composableBuilder(
    column: $table.launchCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reviewRequested => $composableBuilder(
    column: $table.reviewRequested,
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

  ColumnOrderings<double> get balanceExtra => $composableBuilder(
    column: $table.balanceExtra,
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

  ColumnOrderings<int> get singleEventExpiryDays => $composableBuilder(
    column: $table.singleEventExpiryDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tutorialStep => $composableBuilder(
    column: $table.tutorialStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tutorialSeen => $composableBuilder(
    column: $table.tutorialSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useCommaSeparators => $composableBuilder(
    column: $table.useCommaSeparators,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get appLockEnabled => $composableBuilder(
    column: $table.appLockEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get disclaimerAccepted => $composableBuilder(
    column: $table.disclaimerAccepted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastBankSync => $composableBuilder(
    column: $table.lastBankSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingLinkedBalanceIds => $composableBuilder(
    column: $table.pendingLinkedBalanceIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tasksSyncEnabled => $composableBuilder(
    column: $table.tasksSyncEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tasksListId => $composableBuilder(
    column: $table.tasksListId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tasksAccount => $composableBuilder(
    column: $table.tasksAccount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accentColor => $composableBuilder(
    column: $table.accentColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get customAccent => $composableBuilder(
    column: $table.customAccent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tasksProvider => $composableBuilder(
    column: $table.tasksProvider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get launchCount => $composableBuilder(
    column: $table.launchCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reviewRequested => $composableBuilder(
    column: $table.reviewRequested,
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

  GeneratedColumn<double> get balanceExtra => $composableBuilder(
    column: $table.balanceExtra,
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

  GeneratedColumn<int> get singleEventExpiryDays => $composableBuilder(
    column: $table.singleEventExpiryDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tutorialStep => $composableBuilder(
    column: $table.tutorialStep,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tutorialSeen => $composableBuilder(
    column: $table.tutorialSeen,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get useCommaSeparators => $composableBuilder(
    column: $table.useCommaSeparators,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get appLockEnabled => $composableBuilder(
    column: $table.appLockEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get disclaimerAccepted => $composableBuilder(
    column: $table.disclaimerAccepted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastBankSync => $composableBuilder(
    column: $table.lastBankSync,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pendingLinkedBalanceIds => $composableBuilder(
    column: $table.pendingLinkedBalanceIds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tasksSyncEnabled => $composableBuilder(
    column: $table.tasksSyncEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tasksListId => $composableBuilder(
    column: $table.tasksListId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tasksAccount => $composableBuilder(
    column: $table.tasksAccount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get accentColor => $composableBuilder(
    column: $table.accentColor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get customAccent => $composableBuilder(
    column: $table.customAccent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tasksProvider => $composableBuilder(
    column: $table.tasksProvider,
    builder: (column) => column,
  );

  GeneratedColumn<int> get launchCount => $composableBuilder(
    column: $table.launchCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reviewRequested => $composableBuilder(
    column: $table.reviewRequested,
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
                Value<double> balanceExtra = const Value.absent(),
                Value<DateTime> lastUpdated = const Value.absent(),
                Value<bool> includeNextCheck = const Value.absent(),
                Value<int> singleEventExpiryDays = const Value.absent(),
                Value<int> tutorialStep = const Value.absent(),
                Value<bool> tutorialSeen = const Value.absent(),
                Value<bool> useCommaSeparators = const Value.absent(),
                Value<bool> appLockEnabled = const Value.absent(),
                Value<bool> disclaimerAccepted = const Value.absent(),
                Value<DateTime?> lastBankSync = const Value.absent(),
                Value<String> pendingLinkedBalanceIds = const Value.absent(),
                Value<bool> tasksSyncEnabled = const Value.absent(),
                Value<String?> tasksListId = const Value.absent(),
                Value<String?> tasksAccount = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> accentColor = const Value.absent(),
                Value<int> customAccent = const Value.absent(),
                Value<String> tasksProvider = const Value.absent(),
                Value<int> launchCount = const Value.absent(),
                Value<bool> reviewRequested = const Value.absent(),
              }) => AppMetaRowsCompanion(
                id: id,
                currentBalance: currentBalance,
                balanceExtra: balanceExtra,
                lastUpdated: lastUpdated,
                includeNextCheck: includeNextCheck,
                singleEventExpiryDays: singleEventExpiryDays,
                tutorialStep: tutorialStep,
                tutorialSeen: tutorialSeen,
                useCommaSeparators: useCommaSeparators,
                appLockEnabled: appLockEnabled,
                disclaimerAccepted: disclaimerAccepted,
                lastBankSync: lastBankSync,
                pendingLinkedBalanceIds: pendingLinkedBalanceIds,
                tasksSyncEnabled: tasksSyncEnabled,
                tasksListId: tasksListId,
                tasksAccount: tasksAccount,
                themeMode: themeMode,
                accentColor: accentColor,
                customAccent: customAccent,
                tasksProvider: tasksProvider,
                launchCount: launchCount,
                reviewRequested: reviewRequested,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> currentBalance = const Value.absent(),
                Value<double> balanceExtra = const Value.absent(),
                required DateTime lastUpdated,
                Value<bool> includeNextCheck = const Value.absent(),
                Value<int> singleEventExpiryDays = const Value.absent(),
                Value<int> tutorialStep = const Value.absent(),
                Value<bool> tutorialSeen = const Value.absent(),
                Value<bool> useCommaSeparators = const Value.absent(),
                Value<bool> appLockEnabled = const Value.absent(),
                Value<bool> disclaimerAccepted = const Value.absent(),
                Value<DateTime?> lastBankSync = const Value.absent(),
                Value<String> pendingLinkedBalanceIds = const Value.absent(),
                Value<bool> tasksSyncEnabled = const Value.absent(),
                Value<String?> tasksListId = const Value.absent(),
                Value<String?> tasksAccount = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> accentColor = const Value.absent(),
                Value<int> customAccent = const Value.absent(),
                Value<String> tasksProvider = const Value.absent(),
                Value<int> launchCount = const Value.absent(),
                Value<bool> reviewRequested = const Value.absent(),
              }) => AppMetaRowsCompanion.insert(
                id: id,
                currentBalance: currentBalance,
                balanceExtra: balanceExtra,
                lastUpdated: lastUpdated,
                includeNextCheck: includeNextCheck,
                singleEventExpiryDays: singleEventExpiryDays,
                tutorialStep: tutorialStep,
                tutorialSeen: tutorialSeen,
                useCommaSeparators: useCommaSeparators,
                appLockEnabled: appLockEnabled,
                disclaimerAccepted: disclaimerAccepted,
                lastBankSync: lastBankSync,
                pendingLinkedBalanceIds: pendingLinkedBalanceIds,
                tasksSyncEnabled: tasksSyncEnabled,
                tasksListId: tasksListId,
                tasksAccount: tasksAccount,
                themeMode: themeMode,
                accentColor: accentColor,
                customAccent: customAccent,
                tasksProvider: tasksProvider,
                launchCount: launchCount,
                reviewRequested: reviewRequested,
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
typedef $$SingleEventRowsTableCreateCompanionBuilder =
    SingleEventRowsCompanion Function({
      Value<int> id,
      required String name,
      required double amount,
      required bool isDebit,
      required DateTime createdDate,
      required DateTime lastModifiedDate,
      required double appliedAmount,
      required EventTarget target,
      Value<String?> targetName,
      Value<String?> targetId,
    });
typedef $$SingleEventRowsTableUpdateCompanionBuilder =
    SingleEventRowsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> amount,
      Value<bool> isDebit,
      Value<DateTime> createdDate,
      Value<DateTime> lastModifiedDate,
      Value<double> appliedAmount,
      Value<EventTarget> target,
      Value<String?> targetName,
      Value<String?> targetId,
    });

class $$SingleEventRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SingleEventRowsTable> {
  $$SingleEventRowsTableFilterComposer({
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

  ColumnFilters<bool> get isDebit => $composableBuilder(
    column: $table.isDebit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get appliedAmount => $composableBuilder(
    column: $table.appliedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EventTarget, EventTarget, String> get target =>
      $composableBuilder(
        column: $table.target,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get targetName => $composableBuilder(
    column: $table.targetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SingleEventRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SingleEventRowsTable> {
  $$SingleEventRowsTableOrderingComposer({
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

  ColumnOrderings<bool> get isDebit => $composableBuilder(
    column: $table.isDebit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get appliedAmount => $composableBuilder(
    column: $table.appliedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetName => $composableBuilder(
    column: $table.targetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SingleEventRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SingleEventRowsTable> {
  $$SingleEventRowsTableAnnotationComposer({
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

  GeneratedColumn<bool> get isDebit =>
      $composableBuilder(column: $table.isDebit, builder: (column) => column);

  GeneratedColumn<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get appliedAmount => $composableBuilder(
    column: $table.appliedAmount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<EventTarget, String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<String> get targetName => $composableBuilder(
    column: $table.targetName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);
}

class $$SingleEventRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SingleEventRowsTable,
          SingleEventRow,
          $$SingleEventRowsTableFilterComposer,
          $$SingleEventRowsTableOrderingComposer,
          $$SingleEventRowsTableAnnotationComposer,
          $$SingleEventRowsTableCreateCompanionBuilder,
          $$SingleEventRowsTableUpdateCompanionBuilder,
          (
            SingleEventRow,
            BaseReferences<
              _$AppDatabase,
              $SingleEventRowsTable,
              SingleEventRow
            >,
          ),
          SingleEventRow,
          PrefetchHooks Function()
        > {
  $$SingleEventRowsTableTableManager(
    _$AppDatabase db,
    $SingleEventRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SingleEventRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SingleEventRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SingleEventRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<bool> isDebit = const Value.absent(),
                Value<DateTime> createdDate = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<double> appliedAmount = const Value.absent(),
                Value<EventTarget> target = const Value.absent(),
                Value<String?> targetName = const Value.absent(),
                Value<String?> targetId = const Value.absent(),
              }) => SingleEventRowsCompanion(
                id: id,
                name: name,
                amount: amount,
                isDebit: isDebit,
                createdDate: createdDate,
                lastModifiedDate: lastModifiedDate,
                appliedAmount: appliedAmount,
                target: target,
                targetName: targetName,
                targetId: targetId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double amount,
                required bool isDebit,
                required DateTime createdDate,
                required DateTime lastModifiedDate,
                required double appliedAmount,
                required EventTarget target,
                Value<String?> targetName = const Value.absent(),
                Value<String?> targetId = const Value.absent(),
              }) => SingleEventRowsCompanion.insert(
                id: id,
                name: name,
                amount: amount,
                isDebit: isDebit,
                createdDate: createdDate,
                lastModifiedDate: lastModifiedDate,
                appliedAmount: appliedAmount,
                target: target,
                targetName: targetName,
                targetId: targetId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SingleEventRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SingleEventRowsTable,
      SingleEventRow,
      $$SingleEventRowsTableFilterComposer,
      $$SingleEventRowsTableOrderingComposer,
      $$SingleEventRowsTableAnnotationComposer,
      $$SingleEventRowsTableCreateCompanionBuilder,
      $$SingleEventRowsTableUpdateCompanionBuilder,
      (
        SingleEventRow,
        BaseReferences<_$AppDatabase, $SingleEventRowsTable, SingleEventRow>,
      ),
      SingleEventRow,
      PrefetchHooks Function()
    >;
typedef $$PeriodSnapshotRowsTableCreateCompanionBuilder =
    PeriodSnapshotRowsCompanion Function({
      Value<int> id,
      required DateTime start,
      required double totalIncome,
      required double totalExpenses,
    });
typedef $$PeriodSnapshotRowsTableUpdateCompanionBuilder =
    PeriodSnapshotRowsCompanion Function({
      Value<int> id,
      Value<DateTime> start,
      Value<double> totalIncome,
      Value<double> totalExpenses,
    });

class $$PeriodSnapshotRowsTableFilterComposer
    extends Composer<_$AppDatabase, $PeriodSnapshotRowsTable> {
  $$PeriodSnapshotRowsTableFilterComposer({
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

  ColumnFilters<DateTime> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalIncome => $composableBuilder(
    column: $table.totalIncome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalExpenses => $composableBuilder(
    column: $table.totalExpenses,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeriodSnapshotRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $PeriodSnapshotRowsTable> {
  $$PeriodSnapshotRowsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalIncome => $composableBuilder(
    column: $table.totalIncome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalExpenses => $composableBuilder(
    column: $table.totalExpenses,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeriodSnapshotRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeriodSnapshotRowsTable> {
  $$PeriodSnapshotRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<double> get totalIncome => $composableBuilder(
    column: $table.totalIncome,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalExpenses => $composableBuilder(
    column: $table.totalExpenses,
    builder: (column) => column,
  );
}

class $$PeriodSnapshotRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeriodSnapshotRowsTable,
          PeriodSnapshotRow,
          $$PeriodSnapshotRowsTableFilterComposer,
          $$PeriodSnapshotRowsTableOrderingComposer,
          $$PeriodSnapshotRowsTableAnnotationComposer,
          $$PeriodSnapshotRowsTableCreateCompanionBuilder,
          $$PeriodSnapshotRowsTableUpdateCompanionBuilder,
          (
            PeriodSnapshotRow,
            BaseReferences<
              _$AppDatabase,
              $PeriodSnapshotRowsTable,
              PeriodSnapshotRow
            >,
          ),
          PeriodSnapshotRow,
          PrefetchHooks Function()
        > {
  $$PeriodSnapshotRowsTableTableManager(
    _$AppDatabase db,
    $PeriodSnapshotRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeriodSnapshotRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeriodSnapshotRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeriodSnapshotRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> start = const Value.absent(),
                Value<double> totalIncome = const Value.absent(),
                Value<double> totalExpenses = const Value.absent(),
              }) => PeriodSnapshotRowsCompanion(
                id: id,
                start: start,
                totalIncome: totalIncome,
                totalExpenses: totalExpenses,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime start,
                required double totalIncome,
                required double totalExpenses,
              }) => PeriodSnapshotRowsCompanion.insert(
                id: id,
                start: start,
                totalIncome: totalIncome,
                totalExpenses: totalExpenses,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeriodSnapshotRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeriodSnapshotRowsTable,
      PeriodSnapshotRow,
      $$PeriodSnapshotRowsTableFilterComposer,
      $$PeriodSnapshotRowsTableOrderingComposer,
      $$PeriodSnapshotRowsTableAnnotationComposer,
      $$PeriodSnapshotRowsTableCreateCompanionBuilder,
      $$PeriodSnapshotRowsTableUpdateCompanionBuilder,
      (
        PeriodSnapshotRow,
        BaseReferences<
          _$AppDatabase,
          $PeriodSnapshotRowsTable,
          PeriodSnapshotRow
        >,
      ),
      PeriodSnapshotRow,
      PrefetchHooks Function()
    >;
typedef $$SyncedTaskRowsTableCreateCompanionBuilder =
    SyncedTaskRowsCompanion Function({
      required String taskId,
      required String body,
      Value<int> rowid,
    });
typedef $$SyncedTaskRowsTableUpdateCompanionBuilder =
    SyncedTaskRowsCompanion Function({
      Value<String> taskId,
      Value<String> body,
      Value<int> rowid,
    });

class $$SyncedTaskRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncedTaskRowsTable> {
  $$SyncedTaskRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncedTaskRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncedTaskRowsTable> {
  $$SyncedTaskRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncedTaskRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncedTaskRowsTable> {
  $$SyncedTaskRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $$SyncedTaskRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncedTaskRowsTable,
          SyncedTaskRow,
          $$SyncedTaskRowsTableFilterComposer,
          $$SyncedTaskRowsTableOrderingComposer,
          $$SyncedTaskRowsTableAnnotationComposer,
          $$SyncedTaskRowsTableCreateCompanionBuilder,
          $$SyncedTaskRowsTableUpdateCompanionBuilder,
          (
            SyncedTaskRow,
            BaseReferences<_$AppDatabase, $SyncedTaskRowsTable, SyncedTaskRow>,
          ),
          SyncedTaskRow,
          PrefetchHooks Function()
        > {
  $$SyncedTaskRowsTableTableManager(
    _$AppDatabase db,
    $SyncedTaskRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncedTaskRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncedTaskRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncedTaskRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedTaskRowsCompanion(
                taskId: taskId,
                body: body,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required String body,
                Value<int> rowid = const Value.absent(),
              }) => SyncedTaskRowsCompanion.insert(
                taskId: taskId,
                body: body,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncedTaskRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncedTaskRowsTable,
      SyncedTaskRow,
      $$SyncedTaskRowsTableFilterComposer,
      $$SyncedTaskRowsTableOrderingComposer,
      $$SyncedTaskRowsTableAnnotationComposer,
      $$SyncedTaskRowsTableCreateCompanionBuilder,
      $$SyncedTaskRowsTableUpdateCompanionBuilder,
      (
        SyncedTaskRow,
        BaseReferences<_$AppDatabase, $SyncedTaskRowsTable, SyncedTaskRow>,
      ),
      SyncedTaskRow,
      PrefetchHooks Function()
    >;
typedef $$ManualAccountRowsTableCreateCompanionBuilder =
    ManualAccountRowsCompanion Function({
      required String id,
      required int position,
      required String name,
      required String accountType,
      required double balance,
      Value<bool> countsTowardBalance,
      Value<int> rowid,
    });
typedef $$ManualAccountRowsTableUpdateCompanionBuilder =
    ManualAccountRowsCompanion Function({
      Value<String> id,
      Value<int> position,
      Value<String> name,
      Value<String> accountType,
      Value<double> balance,
      Value<bool> countsTowardBalance,
      Value<int> rowid,
    });

class $$ManualAccountRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ManualAccountRowsTable> {
  $$ManualAccountRowsTableFilterComposer({
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

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get countsTowardBalance => $composableBuilder(
    column: $table.countsTowardBalance,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ManualAccountRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ManualAccountRowsTable> {
  $$ManualAccountRowsTableOrderingComposer({
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

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get countsTowardBalance => $composableBuilder(
    column: $table.countsTowardBalance,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ManualAccountRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ManualAccountRowsTable> {
  $$ManualAccountRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<bool> get countsTowardBalance => $composableBuilder(
    column: $table.countsTowardBalance,
    builder: (column) => column,
  );
}

class $$ManualAccountRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ManualAccountRowsTable,
          ManualAccountRow,
          $$ManualAccountRowsTableFilterComposer,
          $$ManualAccountRowsTableOrderingComposer,
          $$ManualAccountRowsTableAnnotationComposer,
          $$ManualAccountRowsTableCreateCompanionBuilder,
          $$ManualAccountRowsTableUpdateCompanionBuilder,
          (
            ManualAccountRow,
            BaseReferences<
              _$AppDatabase,
              $ManualAccountRowsTable,
              ManualAccountRow
            >,
          ),
          ManualAccountRow,
          PrefetchHooks Function()
        > {
  $$ManualAccountRowsTableTableManager(
    _$AppDatabase db,
    $ManualAccountRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ManualAccountRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ManualAccountRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ManualAccountRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> accountType = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<bool> countsTowardBalance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManualAccountRowsCompanion(
                id: id,
                position: position,
                name: name,
                accountType: accountType,
                balance: balance,
                countsTowardBalance: countsTowardBalance,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int position,
                required String name,
                required String accountType,
                required double balance,
                Value<bool> countsTowardBalance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManualAccountRowsCompanion.insert(
                id: id,
                position: position,
                name: name,
                accountType: accountType,
                balance: balance,
                countsTowardBalance: countsTowardBalance,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ManualAccountRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ManualAccountRowsTable,
      ManualAccountRow,
      $$ManualAccountRowsTableFilterComposer,
      $$ManualAccountRowsTableOrderingComposer,
      $$ManualAccountRowsTableAnnotationComposer,
      $$ManualAccountRowsTableCreateCompanionBuilder,
      $$ManualAccountRowsTableUpdateCompanionBuilder,
      (
        ManualAccountRow,
        BaseReferences<
          _$AppDatabase,
          $ManualAccountRowsTable,
          ManualAccountRow
        >,
      ),
      ManualAccountRow,
      PrefetchHooks Function()
    >;
typedef $$LinkedItemRowsTableCreateCompanionBuilder =
    LinkedItemRowsCompanion Function({
      required String key,
      required String accessToken,
      Value<String> institution,
      Value<bool> needsRelink,
      Value<int> rowid,
    });
typedef $$LinkedItemRowsTableUpdateCompanionBuilder =
    LinkedItemRowsCompanion Function({
      Value<String> key,
      Value<String> accessToken,
      Value<String> institution,
      Value<bool> needsRelink,
      Value<int> rowid,
    });

class $$LinkedItemRowsTableFilterComposer
    extends Composer<_$AppDatabase, $LinkedItemRowsTable> {
  $$LinkedItemRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsRelink => $composableBuilder(
    column: $table.needsRelink,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LinkedItemRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $LinkedItemRowsTable> {
  $$LinkedItemRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsRelink => $composableBuilder(
    column: $table.needsRelink,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LinkedItemRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LinkedItemRowsTable> {
  $$LinkedItemRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get needsRelink => $composableBuilder(
    column: $table.needsRelink,
    builder: (column) => column,
  );
}

class $$LinkedItemRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LinkedItemRowsTable,
          LinkedItemRow,
          $$LinkedItemRowsTableFilterComposer,
          $$LinkedItemRowsTableOrderingComposer,
          $$LinkedItemRowsTableAnnotationComposer,
          $$LinkedItemRowsTableCreateCompanionBuilder,
          $$LinkedItemRowsTableUpdateCompanionBuilder,
          (
            LinkedItemRow,
            BaseReferences<_$AppDatabase, $LinkedItemRowsTable, LinkedItemRow>,
          ),
          LinkedItemRow,
          PrefetchHooks Function()
        > {
  $$LinkedItemRowsTableTableManager(
    _$AppDatabase db,
    $LinkedItemRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LinkedItemRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LinkedItemRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LinkedItemRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> accessToken = const Value.absent(),
                Value<String> institution = const Value.absent(),
                Value<bool> needsRelink = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LinkedItemRowsCompanion(
                key: key,
                accessToken: accessToken,
                institution: institution,
                needsRelink: needsRelink,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String accessToken,
                Value<String> institution = const Value.absent(),
                Value<bool> needsRelink = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LinkedItemRowsCompanion.insert(
                key: key,
                accessToken: accessToken,
                institution: institution,
                needsRelink: needsRelink,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LinkedItemRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LinkedItemRowsTable,
      LinkedItemRow,
      $$LinkedItemRowsTableFilterComposer,
      $$LinkedItemRowsTableOrderingComposer,
      $$LinkedItemRowsTableAnnotationComposer,
      $$LinkedItemRowsTableCreateCompanionBuilder,
      $$LinkedItemRowsTableUpdateCompanionBuilder,
      (
        LinkedItemRow,
        BaseReferences<_$AppDatabase, $LinkedItemRowsTable, LinkedItemRow>,
      ),
      LinkedItemRow,
      PrefetchHooks Function()
    >;
typedef $$LinkedAccountRowsTableCreateCompanionBuilder =
    LinkedAccountRowsCompanion Function({
      required String id,
      required String itemKey,
      required int position,
      required String name,
      required String type,
      required String subtype,
      required String mask,
      required String institution,
      Value<double?> ledger,
      Value<double?> available,
      Value<double?> creditLimit,
      Value<bool> countsTowardBalance,
      Value<int> rowid,
    });
typedef $$LinkedAccountRowsTableUpdateCompanionBuilder =
    LinkedAccountRowsCompanion Function({
      Value<String> id,
      Value<String> itemKey,
      Value<int> position,
      Value<String> name,
      Value<String> type,
      Value<String> subtype,
      Value<String> mask,
      Value<String> institution,
      Value<double?> ledger,
      Value<double?> available,
      Value<double?> creditLimit,
      Value<bool> countsTowardBalance,
      Value<int> rowid,
    });

class $$LinkedAccountRowsTableFilterComposer
    extends Composer<_$AppDatabase, $LinkedAccountRowsTable> {
  $$LinkedAccountRowsTableFilterComposer({
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

  ColumnFilters<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtype => $composableBuilder(
    column: $table.subtype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mask => $composableBuilder(
    column: $table.mask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ledger => $composableBuilder(
    column: $table.ledger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get available => $composableBuilder(
    column: $table.available,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get countsTowardBalance => $composableBuilder(
    column: $table.countsTowardBalance,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LinkedAccountRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $LinkedAccountRowsTable> {
  $$LinkedAccountRowsTableOrderingComposer({
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

  ColumnOrderings<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtype => $composableBuilder(
    column: $table.subtype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mask => $composableBuilder(
    column: $table.mask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ledger => $composableBuilder(
    column: $table.ledger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get available => $composableBuilder(
    column: $table.available,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get countsTowardBalance => $composableBuilder(
    column: $table.countsTowardBalance,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LinkedAccountRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LinkedAccountRowsTable> {
  $$LinkedAccountRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemKey =>
      $composableBuilder(column: $table.itemKey, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get subtype =>
      $composableBuilder(column: $table.subtype, builder: (column) => column);

  GeneratedColumn<String> get mask =>
      $composableBuilder(column: $table.mask, builder: (column) => column);

  GeneratedColumn<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ledger =>
      $composableBuilder(column: $table.ledger, builder: (column) => column);

  GeneratedColumn<double> get available =>
      $composableBuilder(column: $table.available, builder: (column) => column);

  GeneratedColumn<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get countsTowardBalance => $composableBuilder(
    column: $table.countsTowardBalance,
    builder: (column) => column,
  );
}

class $$LinkedAccountRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LinkedAccountRowsTable,
          LinkedAccountRow,
          $$LinkedAccountRowsTableFilterComposer,
          $$LinkedAccountRowsTableOrderingComposer,
          $$LinkedAccountRowsTableAnnotationComposer,
          $$LinkedAccountRowsTableCreateCompanionBuilder,
          $$LinkedAccountRowsTableUpdateCompanionBuilder,
          (
            LinkedAccountRow,
            BaseReferences<
              _$AppDatabase,
              $LinkedAccountRowsTable,
              LinkedAccountRow
            >,
          ),
          LinkedAccountRow,
          PrefetchHooks Function()
        > {
  $$LinkedAccountRowsTableTableManager(
    _$AppDatabase db,
    $LinkedAccountRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LinkedAccountRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LinkedAccountRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LinkedAccountRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemKey = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> subtype = const Value.absent(),
                Value<String> mask = const Value.absent(),
                Value<String> institution = const Value.absent(),
                Value<double?> ledger = const Value.absent(),
                Value<double?> available = const Value.absent(),
                Value<double?> creditLimit = const Value.absent(),
                Value<bool> countsTowardBalance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LinkedAccountRowsCompanion(
                id: id,
                itemKey: itemKey,
                position: position,
                name: name,
                type: type,
                subtype: subtype,
                mask: mask,
                institution: institution,
                ledger: ledger,
                available: available,
                creditLimit: creditLimit,
                countsTowardBalance: countsTowardBalance,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemKey,
                required int position,
                required String name,
                required String type,
                required String subtype,
                required String mask,
                required String institution,
                Value<double?> ledger = const Value.absent(),
                Value<double?> available = const Value.absent(),
                Value<double?> creditLimit = const Value.absent(),
                Value<bool> countsTowardBalance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LinkedAccountRowsCompanion.insert(
                id: id,
                itemKey: itemKey,
                position: position,
                name: name,
                type: type,
                subtype: subtype,
                mask: mask,
                institution: institution,
                ledger: ledger,
                available: available,
                creditLimit: creditLimit,
                countsTowardBalance: countsTowardBalance,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LinkedAccountRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LinkedAccountRowsTable,
      LinkedAccountRow,
      $$LinkedAccountRowsTableFilterComposer,
      $$LinkedAccountRowsTableOrderingComposer,
      $$LinkedAccountRowsTableAnnotationComposer,
      $$LinkedAccountRowsTableCreateCompanionBuilder,
      $$LinkedAccountRowsTableUpdateCompanionBuilder,
      (
        LinkedAccountRow,
        BaseReferences<
          _$AppDatabase,
          $LinkedAccountRowsTable,
          LinkedAccountRow
        >,
      ),
      LinkedAccountRow,
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
  $$SingleEventRowsTableTableManager get singleEventRows =>
      $$SingleEventRowsTableTableManager(_db, _db.singleEventRows);
  $$PeriodSnapshotRowsTableTableManager get periodSnapshotRows =>
      $$PeriodSnapshotRowsTableTableManager(_db, _db.periodSnapshotRows);
  $$SyncedTaskRowsTableTableManager get syncedTaskRows =>
      $$SyncedTaskRowsTableTableManager(_db, _db.syncedTaskRows);
  $$ManualAccountRowsTableTableManager get manualAccountRows =>
      $$ManualAccountRowsTableTableManager(_db, _db.manualAccountRows);
  $$LinkedItemRowsTableTableManager get linkedItemRows =>
      $$LinkedItemRowsTableTableManager(_db, _db.linkedItemRows);
  $$LinkedAccountRowsTableTableManager get linkedAccountRows =>
      $$LinkedAccountRowsTableTableManager(_db, _db.linkedAccountRows);
}
