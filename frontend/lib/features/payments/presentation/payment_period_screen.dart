import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/debounced_search.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../classes/data/classes_repository.dart';
import '../data/payment_models.dart';
import '../data/payments_repository.dart';
import 'month_fee_sheet.dart';
import 'payment_labels.dart';
import 'payment_sheet.dart';

enum _MonthAction { changeFee, addNewStudents }

/// One month: its totals, and every student's payment, filtered by status, class and name.
class PaymentPeriodScreen extends ConsumerStatefulWidget {
  const PaymentPeriodScreen({super.key, required this.periodId});

  final String periodId;

  @override
  ConsumerState<PaymentPeriodScreen> createState() => _PaymentPeriodScreenState();
}

class _PaymentPeriodScreenState extends ConsumerState<PaymentPeriodScreen> {
  String? _status;
  String? _classId;
  String _search = '';

  PaymentFilter get _filter => (periodId: widget.periodId, status: _status, classId: _classId, search: _search);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(sessionControllerProvider).value;
    final canWrite = user?.can(Permissions.paymentWrite) ?? false;
    final canManageMonth = canWrite && !(user?.isTeacherOnly ?? true);
    final period = ref.watch(paymentPeriodProvider(widget.periodId));
    final classes = ref.watch(classesProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(period.value == null ? l10n.navPayments : formatMonth(period.value!.month)),
        actions: [
          if (canManageMonth && period.hasValue)
            PopupMenuButton<_MonthAction>(
              onSelected: (action) => _onAction(action, period.value!),
              itemBuilder: (_) => [
                PopupMenuItem(value: _MonthAction.changeFee, child: Text(l10n.changeFee)),
                PopupMenuItem(value: _MonthAction.addNewStudents, child: Text(l10n.addNewStudents)),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(paymentPeriodProvider(widget.periodId));
          return ref.refresh(paymentsProvider(_filter).future);
        },
        child: AsyncView(
          value: period,
          onRetry: () => ref.invalidate(paymentPeriodProvider(widget.periodId)),
          data: (month) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Totals(period: month)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MaktabSpacing.md),
                  child: DebouncedSearch(
                    hintText: l10n.searchStudentsHint,
                    onChanged: (value) => setState(() => _search = value),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: MaktabSpacing.md, vertical: MaktabSpacing.sm),
                  child: Row(
                    children: [
                      for (final status in [null, ...PaymentStatuses.all])
                        Padding(
                          padding: const EdgeInsets.only(right: MaktabSpacing.xs),
                          child: ChoiceChip(
                            label: Text(status == null ? l10n.filterAll : paymentStatusLabel(status, l10n)),
                            selected: _status == status,
                            onSelected: (_) => setState(() => _status = status),
                          ),
                        ),
                      const SizedBox(width: MaktabSpacing.xs),
                      DropdownMenu<String?>(
                        initialSelection: _classId,
                        label: Text(l10n.classSection),
                        width: 220,
                        dropdownMenuEntries: [
                          DropdownMenuEntry(value: null, label: l10n.filterAllClasses),
                          for (final c in classes) DropdownMenuEntry(value: c.id, label: c.name),
                        ],
                        onSelected: (id) => setState(() => _classId = id),
                      ),
                    ],
                  ),
                ),
              ),
              _PaymentList(filter: _filter, month: month, canWrite: canWrite),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAction(_MonthAction action, PaymentPeriod period) async {
    switch (action) {
      case _MonthAction.changeFee:
        await showMonthFeeSheet(context, existing: period);
      case _MonthAction.addNewStudents:
        final l10n = AppLocalizations.of(context);
        final messenger = ScaffoldMessenger.of(context);
        try {
          final result = await ref.read(paymentsRepositoryProvider).addNewStudents(period.id);
          ref
            ..invalidate(paymentPeriodProvider(period.id))
            ..invalidate(paymentPeriodsProvider)
            ..invalidate(paymentsProvider);
          messenger.showSnackBar(SnackBar(content: Text(l10n.studentsAdded(result.added))));
        } catch (error) {
          messenger.showSnackBar(SnackBar(content: Text(errorMessage(error, l10n))));
        }
    }
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.period});

  final PaymentPeriod period;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final totals = period.totals;
    Widget figure(String label, double amount) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(formatMoney(amount, period.currency), style: theme.textTheme.titleMedium),
        ],
      ),
    );
    return Card(
      margin: const EdgeInsets.all(MaktabSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(MaktabSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                figure(l10n.paymentExpected, totals.expectedTotal),
                figure(l10n.paymentReceived, totals.paidTotal),
                figure(l10n.paymentStillOutstanding, totals.outstandingTotal),
              ],
            ),
            const SizedBox(height: MaktabSpacing.sm),
            Text(
              '${l10n.monthlyFee}: ${formatMoney(period.monthlyFee, period.currency)} · '
              '${l10n.paymentCounts(totals.paid, totals.partiallyPaid, totals.outstanding)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentList extends ConsumerWidget {
  const _PaymentList({required this.filter, required this.month, required this.canWrite});

  final PaymentFilter filter;
  final PaymentPeriod month;
  final bool canWrite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unfiltered = filter.status == null && filter.classId == null && filter.search.trim().isEmpty;
    return SliverToBoxAdapter(
      child: AsyncView(
        value: ref.watch(paymentsProvider(filter)),
        onRetry: () => ref.invalidate(paymentsProvider(filter)),
        isEmpty: (page) => page.items.isEmpty,
        empty: MessageView(
          icon: Icons.search_off,
          title: unfiltered ? l10n.paymentsNoStudents : l10n.paymentsNoMatch,
          message: unfiltered ? null : l10n.paymentsNoMatchHint,
        ),
        data: (page) => Padding(
          padding: const EdgeInsets.fromLTRB(MaktabSpacing.md, 0, MaktabSpacing.md, MaktabSpacing.lg),
          child: Column(
            children: [
              for (final payment in page.items)
                PaymentTile(
                  payment: payment,
                  onTap: canWrite ? () => showPaymentSheet(context, payment) : null,
                ),
              if (page.hasMore)
                Padding(
                  padding: const EdgeInsets.all(MaktabSpacing.md),
                  child: Text(l10n.showingSome(page.items.length, page.totalItems)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentTile extends StatelessWidget {
  const PaymentTile({super.key, required this.payment, this.onTap});

  final Payment payment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = payment.currency;
    final subtitle = [
      ?payment.className,
      l10n.paymentReceivedOf(formatMoney(payment.amountPaid, currency), formatMoney(payment.expectedAmount, currency)),
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: MaktabSpacing.sm),
      child: ListTile(
        minVerticalPadding: MaktabSpacing.sm,
        title: Text(payment.displayName),
        subtitle: Text(subtitle),
        trailing: PaymentStatusChip(status: payment.status),
        onTap: onTap,
      ),
    );
  }
}
