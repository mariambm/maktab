// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentTotals _$PaymentTotalsFromJson(Map<String, dynamic> json) =>
    PaymentTotals(
      students: (json['students'] as num).toInt(),
      paid: (json['paid'] as num).toInt(),
      partiallyPaid: (json['partiallyPaid'] as num).toInt(),
      outstanding: (json['outstanding'] as num).toInt(),
      expectedTotal: (json['expectedTotal'] as num).toDouble(),
      paidTotal: (json['paidTotal'] as num).toDouble(),
      outstandingTotal: (json['outstandingTotal'] as num).toDouble(),
    );

PaymentPeriod _$PaymentPeriodFromJson(Map<String, dynamic> json) =>
    PaymentPeriod(
      id: json['id'] as String,
      month: monthFromJson(json['month'] as String),
      monthlyFee: (json['monthlyFee'] as num).toDouble(),
      currency: json['currency'] as String,
      totals: PaymentTotals.fromJson(json['totals'] as Map<String, dynamic>),
    );

Payer _$PayerFromJson(Map<String, dynamic> json) => Payer(
  id: json['id'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
);

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
  id: json['id'] as String,
  periodId: json['periodId'] as String,
  month: monthFromJson(json['month'] as String),
  studentId: json['studentId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  className: json['className'] as String?,
  payer: json['payer'] == null
      ? null
      : Payer.fromJson(json['payer'] as Map<String, dynamic>),
  expectedAmount: (json['expectedAmount'] as num).toDouble(),
  amountPaid: (json['amountPaid'] as num).toDouble(),
  outstandingAmount: (json['outstandingAmount'] as num).toDouble(),
  currency: json['currency'] as String,
  status: json['status'] as String,
  paidOn: json['paidOn'] == null
      ? null
      : DateTime.parse(json['paidOn'] as String),
  method: json['method'] as String?,
  note: json['note'] as String?,
);

StudentsAdded _$StudentsAddedFromJson(Map<String, dynamic> json) =>
    StudentsAdded(
      added: (json['added'] as num).toInt(),
      period: PaymentPeriod.fromJson(json['period'] as Map<String, dynamic>),
    );
