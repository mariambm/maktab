import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/uniform_models.dart';

String uniformStatusLabel(String status, AppLocalizations l10n) => switch (status) {
  UniformStatuses.inOrder => l10n.uniformIN_ORDER,
  UniformStatuses.partiallyInOrder => l10n.uniformPARTIALLY_IN_ORDER,
  _ => l10n.uniformNOT_IN_ORDER,
};

IconData uniformStatusIcon(String status) => switch (status) {
  UniformStatuses.inOrder => Icons.check_circle_outline,
  UniformStatuses.partiallyInOrder => Icons.remove_circle_outline,
  _ => Icons.cancel_outlined,
};

String uniformReasonLabel(String reason, AppLocalizations l10n) => switch (reason) {
  UniformReasons.hijabMissing => l10n.uniformHIJAB_MISSING,
  UniformReasons.shirt => l10n.uniformSHIRT_NOT_ACCORDING_TO_UNIFORM,
  _ => l10n.uniformOTHER,
};
