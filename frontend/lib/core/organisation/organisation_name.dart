import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';

/// The mosque's name for the sign-in screen, or null when the server cannot be reached; the screen works without it.
final organisationNameProvider = FutureProvider<String?>((ref) async {
  try {
    final response = await ref.watch(publicDioProvider).get<Map<String, dynamic>>('/api/public/organisation');
    final name = response.data?['name'];
    return name is String && name.trim().isNotEmpty ? name.trim() : null;
  } catch (_) {
    return null;
  }
});
