import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/payment_models.dart';

final _month = DateFormat('MMMM yyyy', 'en');

/// A month as shown in Maktab, for example "October 2026".
String formatMonth(DateTime month) => _month.format(month);

/// An amount in the organisation's currency, for example "£25.00".
String formatMoney(double amount, String currency) =>
    NumberFormat.simpleCurrency(name: currency, locale: 'en_GB').format(amount);

String paymentStatusLabel(String status, AppLocalizations l10n) => switch (status) {
  PaymentStatuses.paid => l10n.paymentStatusPAID,
  PaymentStatuses.partiallyPaid => l10n.paymentStatusPARTIALLY_PAID,
  _ => l10n.paymentStatusOUTSTANDING,
};

IconData paymentStatusIcon(String status) => switch (status) {
  PaymentStatuses.paid => Icons.check_circle_outline,
  PaymentStatuses.partiallyPaid => Icons.timelapse,
  _ => Icons.error_outline,
};

String paymentMethodLabel(String method, AppLocalizations l10n) => switch (method) {
  PaymentMethods.cash => l10n.paymentMethodCASH,
  PaymentMethods.bankTransfer => l10n.paymentMethodBANK_TRANSFER,
  PaymentMethods.card => l10n.paymentMethodCARD,
  _ => l10n.paymentMethodOTHER,
};

/// The status as text and icon together, never colour alone.
class PaymentStatusChip extends StatelessWidget {
  const PaymentStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      PaymentStatuses.paid => (scheme.primaryContainer, scheme.onPrimaryContainer),
      PaymentStatuses.partiallyPaid => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      _ => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(paymentStatusIcon(status), size: 16, color: foreground),
          const SizedBox(width: 4),
          Text(paymentStatusLabel(status, l10n), style: TextStyle(color: foreground, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Parses an amount typed as pounds and pence ("25", "25.5", "£25.00"); null when it is not one.
double? parseAmount(String text) {
  final cleaned = text.trim().replaceAll('£', '').replaceAll(',', '');
  if (!RegExp(r'^\d{1,6}(\.\d{1,2})?$').hasMatch(cleaned)) {
    return null;
  }
  return double.parse(cleaned);
}

/// An amount as the form shows it for editing: "25.00".
String editableAmount(double amount) => amount.toStringAsFixed(2);
