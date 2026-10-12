import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/recent_list.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/payment_models.dart';
import '../data/payments_repository.dart';
import 'payment_labels.dart';
import 'payment_sheet.dart';

/// A student's fees per month, the latest first. Shown only to someone allowed to see payments.
class StudentPaymentsCard extends ConsumerWidget {
  const StudentPaymentsCard({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canWrite = ref.watch(sessionControllerProvider).value?.can(Permissions.paymentWrite) ?? false;
    return SectionCard(
      title: l10n.studentPaymentsTitle,
      children: [
        AsyncView(
          value: ref.watch(studentPaymentsProvider(studentId)),
          onRetry: () => ref.invalidate(studentPaymentsProvider(studentId)),
          isEmpty: (page) => page.items.isEmpty,
          empty: Padding(
            padding: const EdgeInsets.only(bottom: MaktabSpacing.sm),
            child: Text(
              l10n.studentNoPayments,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          data: (page) => RecentList<Payment>(
            items: page.items,
            visible: 3,
            showAllLabel: l10n.showAll,
            showLessLabel: l10n.showLess,
            itemBuilder: (payment) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(formatMonth(payment.month)),
              subtitle: Text(_details(payment, l10n)),
              trailing: PaymentStatusChip(status: payment.status),
              onTap: canWrite ? () => showPaymentSheet(context, payment) : null,
            ),
          ),
        ),
      ],
    );
  }

  /// "£10.00 of £25.00 received · Paid 3 Oct 2026 · Cash", leaving out what is not known.
  static String _details(Payment payment, AppLocalizations l10n) {
    final currency = payment.currency;
    return [
      payment.status == PaymentStatuses.outstanding
          ? l10n.paymentOutstandingAmount(formatMoney(payment.outstandingAmount, currency))
          : l10n.paymentReceivedOf(
              formatMoney(payment.amountPaid, currency),
              formatMoney(payment.expectedAmount, currency),
            ),
      if (payment.paidOn != null) l10n.paymentPaidOn(formatDate(payment.paidOn!)),
      if (payment.method != null) paymentMethodLabel(payment.method!, l10n),
    ].join(' · ');
  }
}
