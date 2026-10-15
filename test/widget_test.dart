import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aadi/core/constants/app_constants.dart';
import 'package:aadi/main.dart';
import 'package:aadi/shared/providers.dart';

void main() {
  testWidgets('App launches to splash, then the welcome screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const AadiApp(),
      ),
    );
    await tester.pump();

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
