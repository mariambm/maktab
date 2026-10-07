import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../curriculum/presentation/subject_labels.dart';
import '../data/progress_models.dart';
import '../data/target_models.dart';

/// One target: what it is, the percentages and score where set, and the teacher's note.
class TargetTile extends StatelessWidget {
  const TargetTile({super.key, required this.target, this.onTap});

  final StudentTarget target;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = [
      if (target.subject != null) subjectLabel(target.subject!, l10n),
      if (target.targetPercentage != null || target.currentPercentage != null)
        l10n.targetPercentages(target.targetPercentage?.toString() ?? '–', target.currentPercentage?.toString() ?? '–'),
      if (target.progressScore != null) [formatScore(target.progressScore!), ?target.progressLabel].join(' '),
    ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.flag_outlined),
      title: Text(target.description),
      subtitle: Text([if (details.isNotEmpty) details, ?target.teacherNote].join('\n')),
      isThreeLine: details.isNotEmpty && target.teacherNote != null,
      trailing: onTap == null ? null : const Icon(Icons.edit_outlined),
      onTap: onTap,
    );
  }
}
