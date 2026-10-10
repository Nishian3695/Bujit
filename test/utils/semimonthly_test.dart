// Twice-a-month (semimonthly) schedules and the weekend rule (a date on a
// Saturday or Sunday moves to the Friday before): the date math, the models,
// and every way they're saved and read back (database, backups, CSV).
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_item.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/navigation_items/settings/csv_import_helper.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/storage_management/backup/backup_json.dart';
import 'package:bujit/storage_management/database/app_database.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:bujit/utils/projector.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Projector _twice(DateTime base, [MonthDays days = MonthDays.standard]) =>
    Projector(baseDate: base, frequency: 1, frequencyUnits: FrequencyUnit.semimonthly, monthDays: days);

List<DateTime> _first(Projector p, int n) => [for (int k = 0; k < n; k++) p.occurrenceDate(k)];

IncomeStreamModel _stream(DateTime start, [MonthDays days = MonthDays.standard]) => IncomeStreamModel(
    name: "Job", amount: 1000.0, startDate: start, frequency: 1,
    frequencyUnits: FrequencyUnit.semimonthly, monthDays: days);

ExpenseModel _expense(DateTime start, [MonthDays days = MonthDays.standard]) => ExpenseModel(
    name: "Daycare", amount: 300.0, startDate: start, frequency: 1,
    frequencyUnits: FrequencyUnit.semimonthly, monthDays: days);

void main() {
    group("MonthDays", () {
        test("valid pairs: the first day 1-27, the second later", () {
            expect(const MonthDays(15, MonthDays.lastDay).isValid, isTrue);
            expect(const MonthDays(1, 15).isValid, isTrue);
            expect(const MonthDays(27, 28).isValid, isTrue);
            expect(const MonthDays(28, MonthDays.lastDay).isValid, isFalse); // Same day every February
            expect(const MonthDays(15, 15).isValid, isFalse);
            expect(const MonthDays(20, 10).isValid, isFalse);
            expect(const MonthDays(0, 15).isValid, isFalse);
        });

        test("describes the days", () {
            expect(MonthDays.standard.describe(), "15th and last day");
            expect(const MonthDays(1, 15).describe(), "1st and 15th");
            expect(const MonthDays(2, 23).describe(), "2nd and 23rd");
            expect(describeFrequency(1, FrequencyUnit.semimonthly, days: const MonthDays(5, 20)),
                "Twice a month (5th and 20th)");
            expect(ordinalDay(11), "11th");
            expect(ordinalDay(12), "12th");
            expect(ordinalDay(13), "13th");
            expect(ordinalDay(21), "21st");
        });
    });

    group("Projector, twice a month", () {
        test("the 15th and the last day, through short months and a leap year", () {
            expect(_first(_twice(DateTime(2027, 12, 15)), 8), [
                DateTime(2027, 12, 15), DateTime(2027, 12, 31),
                DateTime(2028, 1, 15), DateTime(2028, 1, 31),
                DateTime(2028, 2, 15), DateTime(2028, 2, 29), // Leap year
                DateTime(2028, 3, 15), DateTime(2028, 3, 31),
            ]);
            expect(_first(_twice(DateTime(2026, 2, 1)), 4), [
                DateTime(2026, 2, 15), DateTime(2026, 2, 28),
                DateTime(2026, 3, 15), DateTime(2026, 3, 31),
            ]);
        });

        test("the 1st and the 15th", () {
            expect(_first(_twice(DateTime(2026, 1, 1), const MonthDays(1, 15)), 4), [
                DateTime(2026, 1, 1), DateTime(2026, 1, 15), DateTime(2026, 2, 1), DateTime(2026, 2, 15),
            ]);
        });

        test("a day past a month's end lands on its last day, then returns", () {
            final Projector p = _twice(DateTime(2026, 1, 1), const MonthDays(10, 30));
            expect(_first(p, 6), [
                DateTime(2026, 1, 10), DateTime(2026, 1, 30),
                DateTime(2026, 2, 10), DateTime(2026, 2, 28),
                DateTime(2026, 3, 10), DateTime(2026, 3, 30),
            ]);
        });

        test("the schedule starts at the first payday on or after the base date", () {
            expect(_twice(DateTime(2026, 10, 9)).occurrenceDate(0), DateTime(2026, 10, 15));
            expect(_twice(DateTime(2026, 10, 15)).occurrenceDate(0), DateTime(2026, 10, 15));
            expect(_twice(DateTime(2026, 10, 16)).occurrenceDate(0), DateTime(2026, 10, 31));
            expect(_twice(DateTime(2026, 11, 1)).occurrenceDate(0), DateTime(2026, 11, 15));
        });

        test("counts and lookups agree with the dates, over years", () {
            final Projector p = _twice(DateTime(2026, 1, 15));
            final List<DateTime> dates = _first(p, 120); // 5 years
            for (int k = 1; k < dates.length; k++) {
                expect(dates[k].isAfter(dates[k - 1]), isTrue, reason: "${dates[k]} after ${dates[k - 1]}");
                expect(daysBetween(dates[k - 1], dates[k]), inInclusiveRange(13, 17));
            }
            for (int k = 0; k < dates.length; k++) {
                expect(p.countBetween(dates[0], dates[k]), k + 1);
                expect(p.firstOnOrAfter(dates[k]), dates[k]);
                expect(p.firstOnOrAfter(addDays(dates[k], -1)), dates[k]);
                expect(p.lastOnOrBefore(addDays(dates[k], 1)), dates[k]);
            }
            expect(p.countBetween(DateTime(2026, 1, 1), DateTime(2026, 12, 31)), 24);
            expect(p.lastOnOrBefore(DateTime(2026, 1, 14)), isNull); // Before the schedule starts
        });

        test("invalid days fall back to the 15th and the last day", () {
            expect(_twice(DateTime(2026, 2, 1), const MonthDays(28, 31)).occurrenceDate(1), DateTime(2026, 2, 28));
            expect(_twice(DateTime(2026, 2, 1), const MonthDays(28, 31)).occurrenceDate(0), DateTime(2026, 2, 15));
        });
    });

    group("income streams", () {
        test("the start moves to the first payday on or after it", () {
            expect(_stream(DateTime(2026, 10, 9)).startDate, DateTime(2026, 10, 15));
            expect(_stream(DateTime(2026, 10, 31)).startDate, DateTime(2026, 10, 31));
        });

        test("paydays, counts and amounts", () {
            final IncomeStreamModel s = _stream(DateTime(2026, 10, 15));
            expect(s.paydayAfter(DateTime(2026, 10, 15)), DateTime(2026, 10, 31));
            expect(s.paydayAfter(DateTime(2026, 11, 20)), DateTime(2026, 11, 30));
            expect(s.paydayOnOrBefore(DateTime(2026, 11, 14)), DateTime(2026, 10, 31));
            expect(s.occurrencesBetween(DateTime(2026, 10, 1), DateTime(2026, 12, 31)), 6);
            expect(s.amountBetween(DateTime(2026, 11, 1), DateTime(2026, 11, 30)), 2000.0);
            expect(s.displayString(), "Twice a month (15th and last day)");
        });

        test("as the active stream, checks open on the two days and paychecks are credited", () {
            final BalanceModel balance = BalanceModel(currentBalance: 0.0, lastUpdated: DateTime(2026, 10, 1));
            final IncomeStreamModel s = _stream(DateTime(2026, 9, 30));
            balance.incomeStreams.add(s);
            balance.activeIncome = s;
            final DateTime today = DateTime(2026, 11, 20);
            expect(balance.payday(0, today: today), DateTime(2026, 11, 15));
            expect(balance.payday(1, today: today), DateTime(2026, 11, 30));
            expect(balance.payday(2, today: today), DateTime(2026, 12, 15));
            // Oct 15, Oct 31 and Nov 15 arrived since Oct 1
            balance.makeRecent(today: today);
            expect(balance.currentBalance, 3000.0);
        });
    });

    group("expenses", () {
        test("the next due date is a payday, and catching up pays each one", () {
            final ExpenseModel e = _expense(DateTime(2026, 10, 2), const MonthDays(1, 15));
            expect(e.startDate, DateTime(2026, 10, 15));
            expect(e.currentDueDate, DateTime(2026, 10, 15));
            // Oct 15, Nov 1 and Nov 15 are before Nov 20
            expect(e.makeRecent(today: DateTime(2026, 11, 20)), 900.0);
            expect(e.currentDueDate, DateTime(2026, 12, 1));
            expect(e.occurrenceDatesBetween(DateTime(2026, 12, 1), DateTime(2027, 1, 31)),
                [DateTime(2026, 12, 1), DateTime(2026, 12, 15), DateTime(2027, 1, 1), DateTime(2027, 1, 15)]);
        });

        test("an end date stops it", () {
            final ExpenseItem e = ExpenseModel(
                name: "Daycare", amount: 300.0, startDate: DateTime(2026, 10, 15), frequency: 1,
                frequencyUnits: FrequencyUnit.semimonthly, monthDays: MonthDays.standard,
                endDate: DateTime(2026, 11, 20));
            expect(e.occurrencesBetween(DateTime(2026, 10, 1), DateTime(2027, 6, 1)), 3); // Oct 15, 31, Nov 15
        });
    });

    group("saving and reading back", () {
        AppData data() {
            final AppData d = AppData(balance: BalanceModel(currentBalance: 0.0, lastUpdated: DateTime(2026, 10, 1)));
            final IncomeStreamModel s = _stream(DateTime(2026, 10, 15), const MonthDays(5, 20));
            d.balance.incomeStreams.add(s);
            d.balance.activeIncome = s;
            d.balance.expenses.add(_expense(DateTime(2026, 10, 1), const MonthDays(1, 15)));
            return d;
        }

        void expectDays(AppData d) {
            final IncomeStreamModel s = d.balance.incomeStreams.single;
            expect(s.frequencyUnits, FrequencyUnit.semimonthly);
            expect(s.monthDays, const MonthDays(5, 20));
            final ExpenseItem e = d.balance.expenses.single;
            expect(e.frequencyUnits, FrequencyUnit.semimonthly);
            expect(e.monthDays, const MonthDays(1, 15));
        }

        test("the database", () async {
            final AppDataStore store = AppDataStore(AppDatabase(NativeDatabase.memory()));
            await store.save(data());
            expectDays((await store.load())!);
        });

        test("backups", () {
            expectDays(BackupJson.decode(BackupJson.encode(data()), today: DateTime(2026, 10, 1)));
        });

        test("other units save no days", () async {
            final AppDataStore store = AppDataStore(AppDatabase(NativeDatabase.memory()));
            final AppData d = AppData(balance: BalanceModel(currentBalance: 0.0));
            d.balance.incomeStreams.add(IncomeStreamModel(name: "Job", amount: 1.0, startDate: DateTime(2026, 10, 1),
                frequency: 2, frequencyUnits: FrequencyUnit.weekly));
            await store.save(d);
            expect((await store.load())!.balance.incomeStreams.single.monthDays, isNull);
        });
    });

    group("CSV import", () {
        AppData import(String csv) {
            final AppData d = AppData(balance: BalanceModel(currentBalance: 0.0, lastUpdated: DateTime(2026, 10, 1)));
            final CsvImportResult r = CsvImportHelper.importInto(d, csv, today: DateTime(2026, 10, 1));
            expect(r.errors, isEmpty);
            return d;
        }

        test("the two days go where the count does", () {
            final AppData d = import("income_stream,Job,1800,2026-10-15,15/last,semimonthly\n"
                "expense,Daycare,300,2026-10-01,1/15,twice-monthly\n"
                "expense,Gym,20,2026-10-01,,Semi-Monthly\n");
            expect(d.balance.incomeStreams.single.monthDays, MonthDays.standard);
            expect(d.balance.expenses[0].monthDays, const MonthDays(1, 15));
            expect(d.balance.expenses[1].monthDays, MonthDays.standard); // Blank: the 15th and last day
        });

        test("bad days and the ambiguous 'bimonthly' are skipped with a reason", () {
            final AppData d = AppData(balance: BalanceModel(currentBalance: 0.0));
            final CsvImportResult r = CsvImportHelper.importInto(d,
                "expense,A,1,2026-10-01,2,semimonthly\n"
                "expense,B,1,2026-10-01,28/last,semimonthly\n"
                "expense,C,1,2026-10-01,1,bimonthly\n", today: DateTime(2026, 10, 1));
            expect(r.skipped, 3);
            expect(r.errors[0], contains("15/last"));
            expect(r.errors[1], contains("1-27"));
            expect(r.errors[2], contains("ambiguous"));
        });
    });

    group("the weekend rule", () {
        Projector monthly(DateTime base, {bool rule = true}) => Projector(
            baseDate: base, frequency: 1, frequencyUnits: FrequencyUnit.monthly, weekendToFriday: rule);

        test("a Saturday or Sunday date moves to the Friday before", () {
            // Oct 31 2026 is a Saturday, Nov 30 a Monday, Jan 31 2027 a Sunday
            expect(_first(monthly(DateTime(2026, 10, 31)), 4), [
                DateTime(2026, 10, 30), DateTime(2026, 11, 30), DateTime(2026, 12, 31), DateTime(2027, 1, 29),
            ]);
            expect(monthly(DateTime(2026, 10, 31), rule: false).occurrenceDate(0), DateTime(2026, 10, 31));
        });

        test("twice a month", () {
            final Projector p = Projector(baseDate: DateTime(2026, 11, 1), frequency: 1,
                frequencyUnits: FrequencyUnit.semimonthly, weekendToFriday: true);
            expect(_first(p, 2), [DateTime(2026, 11, 13), DateTime(2026, 11, 30)]); // Nov 15 is a Sunday
        });

        test("day counts keep their weekday", () {
            final Projector weekly = Projector(baseDate: DateTime(2026, 10, 31), frequency: 1,
                frequencyUnits: FrequencyUnit.weekly, weekendToFriday: true);
            expect(weekly.occurrenceDate(1), DateTime(2026, 11, 7));
        });

        test("two dates on one weekend share the Friday, and both count", () {
            // Feb 27 and 28 2027 are a Saturday and Sunday
            final Projector p = Projector(baseDate: DateTime(2027, 2, 1), frequency: 1,
                frequencyUnits: FrequencyUnit.semimonthly, monthDays: const MonthDays(27, 28), weekendToFriday: true);
            expect(_first(p, 2), [DateTime(2027, 2, 26), DateTime(2027, 2, 26)]);
            expect(p.countBetween(DateTime(2027, 2, 26), DateTime(2027, 2, 26)), 2);
        });

        test("counts and lookups agree with the dates, over years", () {
            final Projector p = Projector(baseDate: DateTime(2026, 1, 15), frequency: 1,
                frequencyUnits: FrequencyUnit.semimonthly, weekendToFriday: true);
            final List<DateTime> dates = _first(p, 120);
            for (int k = 0; k < dates.length; k++) {
                expect(dates[k].weekday, lessThanOrEqualTo(DateTime.friday));
                if (k > 0) expect(dates[k].isAfter(dates[k - 1]), isTrue);
                expect(p.countBetween(dates[0], dates[k]), k + 1);
                expect(p.firstOnOrAfter(dates[k]), dates[k]);
                expect(p.lastOnOrBefore(dates[k]), dates[k]);
            }
        });

        test("a stream starting on a Saturday is first paid the Friday before", () {
            final IncomeStreamModel s = IncomeStreamModel(name: "Job", amount: 1000.0,
                startDate: DateTime(2026, 10, 31), frequency: 1, frequencyUnits: FrequencyUnit.monthly,
                weekendToFriday: true);
            expect(s.firstPayday, DateTime(2026, 10, 30));
            expect(s.occurrencesBetween(DateTime(2026, 10, 30), DateTime(2026, 10, 30)), 1);
            expect(s.paydayAfter(DateTime(2026, 10, 30)), DateTime(2026, 11, 30));
            expect(s.displayString(), "Every 1 month, Friday if on a weekend");

            final BalanceModel balance = BalanceModel(currentBalance: 0.0, lastUpdated: DateTime(2026, 10, 29));
            balance.incomeStreams.add(s);
            balance.activeIncome = s;
            balance.makeRecent(today: DateTime(2026, 10, 31));
            expect(balance.currentBalance, 1000.0); // Paid Friday the 30th
        });

        test("an expense due on a Saturday is due, and paid, the Friday before", () {
            final ExpenseModel e = ExpenseModel(name: "Rent", amount: 900.0, startDate: DateTime(2026, 10, 31),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly, weekendToFriday: true);
            expect(e.currentDueDate, DateTime(2026, 10, 30));
            expect(e.makeRecent(today: DateTime(2026, 11, 2)), 900.0);
            expect(e.currentDueDate, DateTime(2026, 11, 30));
        });

        test("turning it on for a next due date on a weekend moves it to the Friday", () {
            final ExpenseModel e = ExpenseModel(name: "Rent", amount: 900.0, startDate: DateTime(2026, 8, 31),
                currentDueDate: DateTime(2026, 10, 31), // As scheduled: Saturday the 31st
                frequency: 1, frequencyUnits: FrequencyUnit.monthly, weekendToFriday: true);
            expect(e.currentDueDate, DateTime(2026, 10, 30));
        });

        test("it's saved and read back", () async {
            AppData data() {
                final AppData d = AppData(balance: BalanceModel(currentBalance: 0.0, lastUpdated: DateTime(2026, 10, 1)));
                d.balance.incomeStreams.add(IncomeStreamModel(name: "Job", amount: 1.0, startDate: DateTime(2026, 10, 15),
                    frequency: 1, frequencyUnits: FrequencyUnit.semimonthly, monthDays: MonthDays.standard,
                    weekendToFriday: true));
                d.balance.expenses.add(ExpenseModel(name: "Rent", amount: 1.0, startDate: DateTime(2026, 11, 1),
                    frequency: 1, frequencyUnits: FrequencyUnit.monthly, weekendToFriday: true));
                return d;
            }
            void expectRule(AppData d) {
                expect(d.balance.incomeStreams.single.weekendToFriday, isTrue);
                expect(d.balance.expenses.single.weekendToFriday, isTrue);
            }
            final AppDataStore store = AppDataStore(AppDatabase(NativeDatabase.memory()));
            await store.save(data());
            expectRule((await store.load())!);
            expectRule(BackupJson.decode(BackupJson.encode(data()), today: DateTime(2026, 10, 1)));
        });
    });
}
