import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/api/api_providers.dart';
import 'package:maktab/core/organisation/organisation_name.dart';

import '../helpers.dart';

void main() {
  test('the sign-in screen gets the mosque name without a token', () async {
    final api = FakeApi((request) => (200, {'name': 'Jamiyat Tabligh UL Islam'}));
    final container = ProviderContainer(overrides: [publicDioProvider.overrideWithValue(api.dio)]);
    addTearDown(container.dispose);

    expect(await container.read(organisationNameProvider.future), 'Jamiyat Tabligh UL Islam');
    expect(api.requests.single.path, '/api/public/organisation');
    expect(api.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('without the server the sign-in screen simply shows no name', () async {
    final api = FakeApi((request) => (503, null));
    final container = ProviderContainer(overrides: [publicDioProvider.overrideWithValue(api.dio)]);
    addTearDown(container.dispose);

    expect(await container.read(organisationNameProvider.future), isNull);
  });
}
