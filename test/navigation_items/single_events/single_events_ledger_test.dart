// Single events, matching the Java app's SingleEventsActivity: applied
// immediately, edits reverse then reapply, removal undoes, expiry keeps the effect.
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/navigation_items/single_events/single_event_model.dart';
import 'package:bujit/navigation_items/single_events/single_events_ledger.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime today = DateTime(2026, 10, 1);
DateTime day(int offset) => addDays(today, offset);

SingleEventsLedger _ledger({double balance = 1000.0}) {
    final model = BalanceModel(currentBalance: balance, lastUpdated: today);
    model.expenses.add(CreditModel(
        name: "Card", amount: 300.0, startDate: day(10), frequency: 1,
        frequencyUnits: FrequencyUnit.monthly, creditLimit: 2000.0,
    ));
    return SingleEventsLedger(model, []);
}

CreditModel _card(SingleEventsLedger ledger) => ledger.balance.creditCards.first;

void main() {
    group("the balance", () {
        test("a debit reduces it and a credit adds to it, immediately", () {
            final ledger = _ledger();
            ledger.add(SingleEventModel(name: "Tickets", amount: 85.0, isDebit: true));
            ledger.add(SingleEventModel(name: "Trivia win", amount: 50.0, isDebit: false));

            expect(ledger.balance.currentBalance, closeTo(965.0, 1e-9));
            expect(ledger.events.map((e) => e.name), ["Trivia win", "Tickets"]); // newest first
        });

        test("editing reverses the old effect and applies the new one", () {
            final ledger = _ledger();
            final event = SingleEventModel(name: "Tickets", amount: 85.0, isDebit: true);
            ledger.add(event);

            ledger.update(event, name: "Refund", amount: 30.0, isDebit: false, target: EventTarget.balance);

            expect(ledger.balance.currentBalance, closeTo(1030.0, 1e-9));
            expect(event.appliedAmount, 30.0);
        });

        test("removing undoes the effect", () {
            final ledger = _ledger();
            final event = SingleEventModel(name: "Tickets", amount: 85.0, isDebit: true);
            ledger.add(event);
            ledger.remove(event);

            expect(ledger.balance.currentBalance, closeTo(1000.0, 1e-9));
            expect(ledger.events, isEmpty);
        });
    });

    group("a credit card", () {
        test("a debit adds to what's owed and a credit pays it down", () {
            final ledger = _ledger();
            ledger.add(SingleEventModel(name: "Dinner", amount: 60.0, isDebit: true,
                target: EventTarget.creditCard, targetName: "Card"));
            expect(_card(ledger).amount, closeTo(360.0, 1e-9));

            ledger.add(SingleEventModel(name: "Payment", amount: 100.0, isDebit: false,
                target: EventTarget.creditCard, targetName: "Card"));
            expect(_card(ledger).amount, closeTo(260.0, 1e-9));
            expect(ledger.balance.currentBalance, 1000.0); // the balance isn't touched
        });

        test("a payment can't take a card below zero", () {
            final ledger = _ledger();
            ledger.add(SingleEventModel(name: "Payment", amount: 500.0, isDebit: false,
                target: EventTarget.creditCard, targetName: "Card"));

            expect(_card(ledger).amount, 0.0);
        });

        test("moving an event from the card to the balance moves its effect", () {
            final ledger = _ledger();
            final event = SingleEventModel(name: "Dinner", amount: 60.0, isDebit: true,
                target: EventTarget.creditCard, targetName: "Card");
            ledger.add(event);

            ledger.update(event, name: "Dinner", amount: 60.0, isDebit: true, target: EventTarget.balance);

            expect(_card(ledger).amount, closeTo(300.0, 1e-9));
            expect(ledger.balance.currentBalance, closeTo(940.0, 1e-9));
        });
    });

    group("expiry", () {
        test("an event clears after the expiry period, keeping its effect", () {
            final ledger = _ledger();
            ledger.add(SingleEventModel(name: "Tickets", amount: 85.0, isDebit: true, createdDate: today));

            expect(ledger.clearExpired(30, today: day(29)), 0);
            expect(ledger.clearExpired(30, today: day(30)), 1);
            expect(ledger.events, isEmpty);
            expect(ledger.balance.currentBalance, closeTo(915.0, 1e-9));
        });

        test("editing restarts the expiry period", () {
            final ledger = _ledger();
            final event = SingleEventModel(name: "Tickets", amount: 85.0, isDebit: true, createdDate: today);
            ledger.add(event);
            ledger.update(event, name: "Tickets", amount: 90.0, isDebit: true,
                target: EventTarget.balance, today: day(20));

            expect(event.daysUntilExpiry(30, today: day(30)), 20);
            expect(ledger.clearExpired(30, today: day(30)), 0);
        });
    });
}
