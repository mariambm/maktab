import 'package:json_annotation/json_annotation.dart';

part 'payment_models.g.dart';

/// Payment statuses as sent by the API. The server works them out from the amounts.
abstract final class PaymentStatuses {
  static const paid = 'PAID';
  static const partiallyPaid = 'PARTIALLY_PAID';
  static const outstanding = 'OUTSTANDING';

  static const all = [outstanding, partiallyPaid, paid];
}

/// How a payment was made, as sent by the API.
abstract final class PaymentMethods {
  static const cash = 'CASH';
  static const bankTransfer = 'BANK_TRANSFER';
  static const card = 'CARD';
  static const other = 'OTHER';

  static const all = [cash, bankTransfer, card, other];
}

/// The API's `yyyy-MM` month as the first day of that month.
DateTime monthFromJson(String value) {
  final parts = value.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]));
}

/// The API's `yyyy-MM` spelling of a month.
String monthToJson(DateTime month) => '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

/// What a month adds up to, over the students the user may see.
@JsonSerializable(createToJson: false)
class PaymentTotals {
  const PaymentTotals({
    required this.students,
    required this.paid,
    required this.partiallyPaid,
    required this.outstanding,
    required this.expectedTotal,
    required this.paidTotal,
    required this.outstandingTotal,
  });

  factory PaymentTotals.fromJson(Map<String, dynamic> json) => _$PaymentTotalsFromJson(json);

  final int students;
  final int paid;
  final int partiallyPaid;
  final int outstanding;
  final double expectedTotal;
  final double paidTotal;
  final double outstandingTotal;
}

/// One month of fees.
@JsonSerializable(createToJson: false)
class PaymentPeriod {
  const PaymentPeriod({
    required this.id,
    required this.month,
    required this.monthlyFee,
    required this.currency,
    required this.totals,
  });

  factory PaymentPeriod.fromJson(Map<String, dynamic> json) => _$PaymentPeriodFromJson(json);

  final String id;
  @JsonKey(fromJson: monthFromJson)
  final DateTime month;
  final double monthlyFee;
  final String currency;
  final PaymentTotals totals;
}

@JsonSerializable(createToJson: false)
class Payer {
  const Payer({required this.id, required this.firstName, required this.lastName});

  factory Payer.fromJson(Map<String, dynamic> json) => _$PayerFromJson(json);

  final String id;
  final String firstName;
  final String lastName;

  String get displayName => '$firstName $lastName';
}

/// What one student owes for one month and what has been received.
@JsonSerializable(createToJson: false)
class Payment {
  const Payment({
    required this.id,
    required this.periodId,
    required this.month,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.className,
    this.payer,
    required this.expectedAmount,
    required this.amountPaid,
    required this.outstandingAmount,
    required this.currency,
    required this.status,
    this.paidOn,
    this.method,
    this.note,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);

  final String id;
  final String periodId;
  @JsonKey(fromJson: monthFromJson)
  final DateTime month;
  final String studentId;
  final String firstName;
  final String lastName;
  final String? className;
  final Payer? payer;
  final double expectedAmount;
  final double amountPaid;
  final double outstandingAmount;
  final String currency;
  final String status;
  final DateTime? paidOn;
  final String? method;
  final String? note;

  String get displayName => '$firstName $lastName';
}

/// A payment as the form sends it. With nothing paid, the date and method are left out.
class PaymentDraft {
  const PaymentDraft({
    required this.expectedAmount,
    required this.amountPaid,
    this.paidOn,
    this.method,
    this.parentGuardianId,
    this.note,
  });

  final double expectedAmount;
  final double amountPaid;
  final DateTime? paidOn;
  final String? method;
  final String? parentGuardianId;
  final String? note;

  Map<String, dynamic> toJson() {
    final received = amountPaid > 0;
    final day = paidOn;
    return {
      'expectedAmount': expectedAmount,
      'amountPaid': amountPaid,
      if (received && day != null)
        'paidOn':
            '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}',
      if (received) 'method': ?method,
      'parentGuardianId': ?parentGuardianId,
      'note': ?(note == null || note!.trim().isEmpty ? null : note!.trim()),
    };
  }
}

/// How many students were added to a month, and its totals afterwards.
@JsonSerializable(createToJson: false)
class StudentsAdded {
  const StudentsAdded({required this.added, required this.period});

  factory StudentsAdded.fromJson(Map<String, dynamic> json) => _$StudentsAddedFromJson(json);

  final int added;
  final PaymentPeriod period;
}
