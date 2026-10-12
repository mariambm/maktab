import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/payment_models.dart';
import '../data/payments_repository.dart';
import 'month_fee_sheet.dart';
import 'payment_labels.dart';

/// Payments: every month of fees, the latest first, with what has come in and what is still outstanding.
class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(sessionControllerProvider).value;
    // Adding a month charges every student, so it is for those who see every class.
    final canAdd = (user?.can(Permissions.paymentWrite) ?? false) && !(user?.isTeacherOnly ?? true);
    final periods = ref.watch(paymentPeriodsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navPayments)),
      floatingActionButton: canAdd && periods.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => _addMonth(context, periods.value!),
              icon: const Icon(Icons.add),
              label: Text(l10n.addMonth),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(paymentPeriodsProvider.future),
        child: AsyncView(
          value: periods,
          onRetry: () => ref.invalidate(paymentPeriodsProvider),
          isEmpty: (list) => list.isEmpty,
          empty: MessageView(
            icon: Icons.payments_outlined,
            title: l10n.paymentsEmpty,
            message: canAdd ? l10n.paymentsEmptyHint : l10n.paymentsEmptyReadOnly,
          ),
          data: (list) => ListView(
            padding: const EdgeInsets.fromLTRB(MaktabSpacing.md, MaktabSpacing.md, MaktabSpacing.md, 88),
            children: [for (final period in list) PaymentPeriodCard(period: period)],
          ),
        ),
      ),
    );
  }

  Future<void> _addMonth(BuildContext context, List<PaymentPeriod> existing) async {
    final added = await showMonthFeeSheet(
      context,
      months: monthsToAdd(existing, DateTime.now()),
      suggestedFee: existing.firstOrNull?.monthlyFee,
    );
    if (added != null && context.mounted) {
      context.push('/payments/${added.id}');
    }
  }
}

class PaymentPeriodCard extends StatelessWidget {
  const PaymentPeriodCard({super.key, required this.period});

  final PaymentPeriod period;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final totals = period.totals;
    final share = totals.expectedTotal == 0 ? 0.0 : (totals.paidTotal / totals.expectedTotal).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.only(bottom: MaktabSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/payments/${period.id}'),
        child: Padding(
          padding: const EdgeInsets.all(MaktabSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(formatMonth(period.month), style: theme.textTheme.titleMedium)),
                  Text(formatMoney(period.monthlyFee, period.currency), style: theme.textTheme.bodyMedium),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: MaktabSpacing.sm),
              Text(
                l10n.paymentReceivedOf(
                  formatMoney(totals.paidTotal, period.currency),
                  formatMoney(totals.expectedTotal, period.currency),
                ),
              ),
              const SizedBox(height: MaktabSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: share, minHeight: 8),
              ),
              const SizedBox(height: MaktabSpacing.sm),
              Text(
                l10n.paymentCounts(totals.paid, totals.partiallyPaid, totals.outstanding),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
