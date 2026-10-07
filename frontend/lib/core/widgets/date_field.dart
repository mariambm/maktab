import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../formatting.dart';

/// A form field that opens a date picker. Typing is not needed, which suits phones.
class DateField extends FormField<DateTime> {
  DateField({
    super.key,
    required String label,
    required DateTime firstDate,
    required DateTime lastDate,
    super.initialValue,
    super.validator,
    ValueChanged<DateTime>? onChanged,
    DatePickerMode initialPickerMode = DatePickerMode.day,
  }) : super(
         builder: (state) {
           final l10n = AppLocalizations.of(state.context);
           final value = state.value;
           return InkWell(
             onTap: () async {
               final picked = await showDatePicker(
                 context: state.context,
                 initialDate: value ?? (lastDate.isBefore(DateTime.now()) ? lastDate : DateTime.now()),
                 firstDate: firstDate,
                 lastDate: lastDate,
                 initialDatePickerMode: initialPickerMode,
               );
               if (picked != null) {
                 state.didChange(picked);
                 onChanged?.call(picked);
               }
             },
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: label,
                 errorText: state.errorText,
                 suffixIcon: const Icon(Icons.calendar_today_outlined),
               ),
               isEmpty: false,
               child: Text(value == null ? l10n.selectDate : formatDate(value)),
             ),
           );
         },
       );
}
