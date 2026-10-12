import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:maktab/core/api/api_providers.dart';
import 'package:maktab/core/auth/auth_models.dart';
import 'package:maktab/core/auth/session_controller.dart';
import 'package:maktab/features/payments/data/payment_models.dart';
import 'package:maktab/features/payments/data/payments_repository.dart';
import 'package:maktab/features/payments/presentation/month_fee_sheet.dart';
import 'package:maktab/features/payments/presentation/payment_labels.dart';
import 'package:maktab/features/payments/presentation/payment_sheet.dart';
import 'package:maktab/features/payments/presentation/payments_screen.dart';

import '../../helpers.dart';

Map<String, Object?> periodJson({String id = 'pp1', String month = '2026-10'}) => {
  'id': id,
  'month': month,
  'monthlyFee': 25.0,
  'currency': 'GBP',
  'totals': {
    'students': 3,
    'paid': 1,
    'partiallyPaid': 1,
    'outstanding': 1,
    'expectedTotal': 75.0,
    'paidTotal': 35.0,
    'outstandingTotal': 40.0,
  },
};

Map<String, Object?> paymentJson({double paid = 0, String status = 'OUTSTANDING'}) => {
  'id': 'pay1',
  'periodId': 'pp1',
  'month': '2026-10',
  'studentId': 's1',
  'firstName': 'Amina',
  'lastName': 'Rahman',
  'className': 'Saturday Beginners A',
  'payer': {'id': 'pg1', 'firstName': 'Fatima', 'lastName': 'Rahman'},
  'expectedAmount': 25.0,
  'amountPaid': paid,
  'outstandingAmount': 25.0 - paid,
  'currency': 'GBP',
  'status': status,
  'paidOn': null,
  'method': null,
  'note': null,
};

const studentJson = {
  'id': 's1',
  'firstName': 'Amina',
  'lastName': 'Rahman',
  'dateOfBirth': '2017-03-14',
  'gender': null,
  'status': 'ACTIVE',
  'joinedOn': '2026-09-01',
  'currentClass': null,
  'parents': [
    {
      'parentId': 'pg1',
      'firstName': 'Fatima',
      'lastName': 'Rahman',
      'phone': '+44 7700 900123',
      'email': null,
      'relationship': 'MOTHER',
      'primaryContact': true,
    },
  ],
};

Widget app(FakeApi api, Widget child, {AuthUser? user}) => ProviderScope(
  overrides: [
    apiDioProvider.overrideWithValue(api.dio),
    sessionControllerProvider.overrideWith(() => SignedInSession(user ?? adminUser())),
  ],
  child: localized(child),
);

void main() {
  test('nothing paid sends no date or method; money received sends both', () {
    final nothing = PaymentDraft(
      expectedAmount: 25,
      amountPaid: 0,
      paidOn: DateTime(2026, 10, 3),
      method: PaymentMethods.cash,
      parentGuardianId: 'pg1',
      note: ' ',
    );
    expect(nothing.toJson(), {'expectedAmount': 25, 'amountPaid': 0, 'parentGuardianId': 'pg1'});

    final received = PaymentDraft(
      expectedAmount: 25,
      amountPaid: 10.5,
      paidOn: DateTime(2026, 10, 3),
      method: PaymentMethods.bankTransfer,
      note: ' Rest next week ',
    );
    expect(received.toJson(), {
      'expectedAmount': 25,
      'amountPaid': 10.5,
      'paidOn': '2026-10-03',
      'method': 'BANK_TRANSFER',
      'note': 'Rest next week',
    });
  });

  test('amounts are read as pounds and pence and shown in the mosque\'s currency', () async {
    await initializeDateFormatting('en');
    expect(parseAmount('25'), 25);
    expect(parseAmount(' £12.50 '), 12.5);
    expect(parseAmount('12.505'), isNull);
    expect(parseAmount('ten'), isNull);
    expect(formatMoney(1250, 'GBP'), '£1,250.00');
    expect(formatMonth(monthFromJson('2026-10')), 'October 2026');
  });

  test('a month can be added from two months back to two ahead, unless it already exists', () {
    final existing = [PaymentPeriod.fromJson(periodJson(month: '2026-10'))];

    final months = monthsToAdd(existing, DateTime(2026, 10, 12));

    expect(months.map(monthToJson), ['2026-12', '2026-11', '2026-09', '2026-08']);
  });

  test('a month\'s payments are filtered on the server by status, class and name', () async {
    final api = FakeApi((_) => (200, {'items': <Object>[], 'page': 0, 'size': 200, 'totalItems': 0}));

    await PaymentsRepository(api.dio).list((periodId: 'pp1', status: 'OUTSTANDING', classId: null, search: ' ami '));

    final query = api.requests.single.queryParameters;
    expect(api.requests.single.path, '/api/payments');
    expect(query['periodId'], 'pp1');
    expect(query['status'], 'OUTSTANDING');
    expect(query['search'], 'ami');
    expect(query.containsKey('classId'), isFalse);
  });

  testWidgets('the months list shows what came in for each month', (tester) async {
    final api = FakeApi((_) => (200, [periodJson()]));
    await tester.pumpWidget(app(api, const PaymentsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('October 2026'), findsOne);
    expect(find.text('£35.00 of £75.00 received'), findsOne);
    expect(find.text('1 paid · 1 partly paid · 1 outstanding'), findsOne);
    expect(find.text('Add month'), findsOne);
  });

  testWidgets('a teacher allowed to record payments still cannot add a month', (tester) async {
    final api = FakeApi((_) => (200, [periodJson()]));
    final teacher = testUser(permissions: const {Permissions.paymentRead, Permissions.paymentWrite});
    await tester.pumpWidget(app(api, const PaymentsScreen(), user: teacher));
    await tester.pumpAndSettle();

    expect(find.text('October 2026'), findsOne);
    expect(find.text('Add month'), findsNothing);
  });

  testWidgets('recording a payment asks how it was paid, and Paid in full fills in the amount', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final api = FakeApi(
      (request) => request.path == '/api/students/s1'
          ? (200, studentJson)
          : (200, paymentJson(paid: 25, status: 'PAID')),
    );
    final payment = Payment.fromJson(paymentJson());
    await tester.pumpWidget(
      app(
        api,
        Scaffold(
          body: Builder(
            builder: (context) =>
                TextButton(onPressed: () => showPaymentSheet(context, payment), child: const Text('open')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Cash'), findsNothing, reason: 'nothing paid, so no method to choose');

    await tester.tap(find.text('Paid in full'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Choose how it was paid'), findsOne);
    expect(api.requests.where((r) => r.method == 'PUT'), isEmpty);

    await tester.tap(find.text('Cash'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final put = api.requests.singleWhere((r) => r.method == 'PUT');
    expect(put.path, '/api/payments/pay1');
    final body = put.data as Map<String, dynamic>;
    expect(body['amountPaid'], 25);
    expect(body['method'], 'CASH');
    expect(body['parentGuardianId'], 'pg1');
    expect(body['paidOn'], isNotNull);
    expect(find.text('Payment saved'), findsOne);
  });
}
