import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sri_sai_ro_water/app.dart';

void main() {
  test('App widget can be created', () {
    expect(const SriSaiRoWaterApp(), isA<SriSaiRoWaterApp>());
  });

  test(
    'Legacy mock-data widget tests removed — use API integration tests',
    () {},
    skip: 'Backend-only app — add integration tests against running API',
  );
}
