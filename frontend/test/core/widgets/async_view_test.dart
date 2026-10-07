import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/errors/api_exception.dart';
import 'package:maktab/core/widgets/async_view.dart';

import '../../helpers.dart';

void main() {
  Widget view(AsyncValue<List<String>> value, {VoidCallback? onRetry}) => localized(
        Scaffold(
          body: AsyncView<List<String>>(
            value: value,
            isEmpty: (list) => list.isEmpty,
            empty: const Text('Nothing here'),
            onRetry: onRetry,
            data: (list) => Text(list.join(',')),
          ),
        ),
      );

  testWidgets('shows a spinner while loading', (tester) async {
    await tester.pumpWidget(view(const AsyncLoading()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the empty state for empty data', (tester) async {
    await tester.pumpWidget(view(const AsyncData([])));
    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('shows data', (tester) async {
    await tester.pumpWidget(view(const AsyncData(['a', 'b'])));
    expect(find.text('a,b'), findsOneWidget);
  });

  testWidgets('shows a friendly error with a working retry button', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      view(
        const AsyncError(ApiException(code: ApiException.networkError), StackTrace.empty),
        onRetry: () => retried++,
      ),
    );

    expect(find.text('Cannot reach the server. Check your connection and try again.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, 1);
  });
}
