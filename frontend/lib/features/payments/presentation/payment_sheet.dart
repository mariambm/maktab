import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/maktab_spacing.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../students/data/student_models.dart';
import '../../students/data/students_repository.dart';
import '../data/payment_models.dart';
import '../data/payments_repository.dart';
import 'payment_labels.dart';

/// Opens the form for one student's month. Returns true when the payment was saved or removed.
Future<bool?> showPaymentSheet(BuildContext context, Payment payment) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => PaymentSheet(payment: payment),
);

class PaymentSheet extends ConsumerStatefulWidget {
  const PaymentSheet({super.key, required this.payment});

  final Payment payment;

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _expected = TextEditingController(text: editableAmount(widget.payment.expectedAmount));
  late final _paid = TextEditingController(text: editableAmount(widget.payment.amountPaid));
  late final _note = TextEditingController(text: widget.payment.note);
  late DateTime _paidOn = widget.payment.paidOn ?? dateOnly(DateTime.now());
  late String? _method = widget.payment.method;
  late String? _payerId = widget.payment.payer?.id;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _paid.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _expected.dispose();
    _paid.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _received => (parseAmount(_paid.text) ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final payment = widget.payment;
    final parents = ref.watch(studentProvider(payment.studentId)).value?.parents ?? const <StudentParent>[];
    final today = dateOnly(DateTime.now());
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MaktabSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payment.displayName, style: theme.textTheme.titleLarge),
                  Text(
                    formatMonth(payment.month),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(MaktabSpacing.lg, MaktabSpacing.md, MaktabSpacing.lg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height: MaktabSpacing.sm),
                    ],
                    TextFormField(
                      key: const Key('payment.expected'),
                      controller: _expected,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l10n.amountExpected, prefixText: '£ '),
                      validator: (v) {
                        final amount = parseAmount(v ?? '');
                        if (amount == null) {
                          return l10n.amountInvalid;
                        }
                        return amount <= 0 ? l10n.amountRequired : null;
                      },
                    ),
                    const SizedBox(height: MaktabSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const Key('payment.paid'),
                            controller: _paid,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: l10n.amountPaid, prefixText: '£ '),
                            validator: (v) {
                              final paid = parseAmount(v ?? '');
                              if (paid == null) {
                                return l10n.amountInvalid;
                              }
                              final expected = parseAmount(_expected.text);
                              return expected != null && paid > expected ? l10n.amountPaidTooMuch : null;
                            },
                          ),
                        ),
                        const SizedBox(width: MaktabSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.only(top: MaktabSpacing.xs),
                          child: OutlinedButton(
                            onPressed: () => _paid.text = _expected.text,
                            child: Text(l10n.paidInFull),
                          ),
                        ),
                      ],
                    ),
                    if (_received) ...[
                      const SizedBox(height: MaktabSpacing.md),
                      DateField(
                        label: l10n.paidOnLabel,
                        firstDate: DateTime(today.year - 2),
                        lastDate: today,
                        initialValue: _paidOn,
                        onChanged: (date) => _paidOn = date,
                      ),
                      const SizedBox(height: MaktabSpacing.md),
                      Text(l10n.paymentMethodLabel, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: MaktabSpacing.xs),
                      FormField<String>(
                        initialValue: _method,
                        validator: (_) => _method == null ? l10n.paymentMethodRequired : null,
                        builder: (field) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: MaktabSpacing.xs,
                              runSpacing: MaktabSpacing.xs,
                              children: [
                                for (final method in PaymentMethods.all)
                                  ChoiceChip(
                                    label: Text(paymentMethodLabel(method, l10n)),
                                    selected: _method == method,
                                    onSelected: (_) {
                                      setState(() => _method = method);
                                      field.didChange(method);
                                    },
                                  ),
                              ],
                            ),
                            if (field.hasError)
                              Padding(
                                padding: const EdgeInsets.only(top: MaktabSpacing.xs),
                                child: Text(
                                  field.errorText!,
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: MaktabSpacing.md),
                    DropdownButtonFormField<String?>(
                      key: ValueKey(parents.length),
                      initialValue: parents.any((p) => p.parentId == _payerId) ? _payerId : null,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l10n.paidByLabel),
                      items: [
                        DropdownMenuItem(child: Text(l10n.paidByNotRecorded)),
                        for (final parent in parents)
                          DropdownMenuItem(value: parent.parentId, child: Text(parent.displayName)),
                      ],
                      onChanged: (id) => setState(() => _payerId = id),
                    ),
                    const SizedBox(height: MaktabSpacing.md),
                    TextField(
                      controller: _note,
                      maxLength: 500,
                      maxLines: 2,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(labelText: l10n.paymentNote, counterText: ''),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(MaktabSpacing.lg, MaktabSpacing.sm, MaktabSpacing.lg, MaktabSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: payment.amountPaid == 0
                          ? TextButton(onPressed: _saving ? null : _remove, child: Text(l10n.removeFromMonth))
                          : null,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: Text(l10n.save),
                  ),
                ],
              ),
            ),
          ],
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
    final draft = PaymentDraft(
      expectedAmount: parseAmount(_expected.text)!,
      amountPaid: parseAmount(_paid.text)!,
      paidOn: _paidOn,
      method: _method,
      parentGuardianId: _payerId,
      note: _note.text,
    );
    await _run(() => ref.read(paymentsRepositoryProvider).update(widget.payment.id, draft), () {
      messenger.showSnackBar(SnackBar(content: Text(l10n.paymentSaved)));
      navigator.pop(true);
    });
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final payment = widget.payment;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeFromMonth),
        content: Text(l10n.removeFromMonthConfirm(payment.displayName, formatMonth(payment.month))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.remove)),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await _run(() => ref.read(paymentsRepositoryProvider).remove(payment.id), () {
      messenger.showSnackBar(SnackBar(content: Text(l10n.removedFromMonth)));
      navigator.pop(true);
    });
  }

  Future<void> _run(Future<Object?> Function() call, VoidCallback onDone) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await call();
      ref
        ..invalidate(paymentsProvider)
        ..invalidate(paymentPeriodsProvider)
        ..invalidate(paymentPeriodProvider(widget.payment.periodId))
        ..invalidate(studentPaymentsProvider(widget.payment.studentId));
      onDone();
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
