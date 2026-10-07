import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  runApp(const ProviderScope(retry: noAutomaticRetry, child: MaktabApp()));
}

/// Riverpod retries failed providers by default, which keeps screens spinning on errors such as "Student not found".
/// Maktab shows the error with a "Try again" button instead, so the user decides when to retry.
Duration? noAutomaticRetry(int retryCount, Object error) => null;
