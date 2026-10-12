import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/payment_models.dart';
import '../data/payments_repository.dart';
import 'payment_labels.dart';

/// Adds a month (choose the month and its fee), or changes the fee of [existing].
Future<PaymentPeriod?> showMonthFeeSheet(
  BuildContext context, {
  PaymentPeriod? existing,
  List<DateTime> months = const [],
  double? suggestedFee,
}) => showModalBottomSheet<PaymentPeriod>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => MonthFeeSheet(existing: existing, months: months, suggestedFee: suggestedFee),
);

/// The months a new one can be added for: from two months ago to two months ahead, minus those already added.
List<DateTime> monthsToAdd(List<PaymentPeriod> existing, DateTime today) {
  final taken = {for (final period in existing) monthToJson(period.month)};
  return [
    for (var offset = 2; offset >= -2; offset--) DateTime(today.year, today.month + offset),
  ].where((month) => !taken.contains(monthToJson(month))).toList();
}

class MonthFeeSheet extends ConsumerStatefulWidget {
  const MonthFeeSheet({super.key, this.existing, this.months = const [], this.suggestedFee});

  final PaymentPeriod? existing;
  final List<DateTime> months;
  final double? suggestedFee;

  @override
  ConsumerState<MonthFeeSheet> createState() => _MonthFeeSheetState();
}

class _MonthFeeSheetState extends ConsumerState<MonthFeeSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime? _month = _defaultMonth();
  late final _fee = TextEditingController(
    text: switch (widget.existing?.monthlyFee ?? widget.suggestedFee) {
      final double fee => editableAmount(fee),
      null => '',
    },
  );
  bool _saving = false;
  String? _error;

  /// This month when it can still be added, otherwise the first one offered.
  DateTime? _defaultMonth() {
    final now = DateTime.now();
    return widget.months.where((m) => m.year == now.year && m.month == now.month).firstOrNull ??
        widget.months.firstOrNull;
  }

  @override
  void dispose() {
    _fee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final existing = widget.existing;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MaktabSpacing.lg, 0, MaktabSpacing.lg, MaktabSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(existing == null ? l10n.addMonth : l10n.changeFee, style: theme.textTheme.titleLarge),
              const SizedBox(height: MaktabSpacing.md),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: MaktabSpacing.sm),
              ],
              if (existing == null)
                DropdownButtonFormField<DateTime>(
                  initialValue: _month,
                  decoration: InputDecoration(labelText: l10n.paymentMonth),
                  items: [
                    for (final month in widget.months) DropdownMenuItem(value: month, child: Text(formatMonth(month))),
                  ],
                  onChanged: (month) => setState(() => _month = month),
                  validator: (v) => v == null ? l10n.paymentMonth : null,
                )
              else
                InputDecorator(
                  decoration: InputDecoration(labelText: l10n.paymentMonth),
                  child: Text(formatMonth(existing.month)),
                ),
              const SizedBox(height: MaktabSpacing.md),
              TextFormField(
                key: const Key('month.fee'),
                controller: _fee,
                autofocus: existing != null,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.monthlyFee,
                  prefixText: '£ ',
                  helperText: existing == null ? l10n.monthAddFeeHint : l10n.changeFeeHint,
                  helperMaxLines: 3,
                ),
                validator: (v) {
                  final amount = parseAmount(v ?? '');
                  if (amount == null) {
                    return l10n.amountInvalid;
                  }
                  return amount <= 0 ? l10n.amountRequired : null;
                },
              ),
              const SizedBox(height: MaktabSpacing.lg),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(existing == null ? Icons.add : Icons.save_outlined),
                label: Text(existing == null ? l10n.addMonth : l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final fee = parseAmount(_fee.text)!;
    final existing = widget.existing;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = ref.read(paymentsRepositoryProvider);
      final saved = existing == null
          ? await repository.createPeriod(_month!, fee)
          : await repository.changeFee(existing.id, fee);
      ref
        ..invalidate(paymentPeriodsProvider)
        ..invalidate(paymentPeriodProvider(saved.id))
        ..invalidate(paymentsProvider);
      messenger.showSnackBar(SnackBar(content: Text(existing == null ? l10n.monthAdded : l10n.feeChanged)));
      navigator.pop(saved);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.fieldErrors.isEmpty ? errorMessage(e, l10n) : e.fieldErrors.values.first;
        });
      }
    }
  }
}
