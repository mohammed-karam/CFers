// Smoke test: the app boots straight into the phone shell, with the handle
// prompt waiting on the Profile tab for a first-time student.

import 'package:fawateery/core/storage/app_settings.dart';
import 'package:fawateery/features/shell/views/main_shell_view.dart';
import 'package:fawateery/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the app boots into the four-tab shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    AppSettings.debugReset();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(MainShellView), findsOneWidget);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      bar.destinations
          .whereType<NavigationDestination>()
          .map((destination) => destination.label)
          .toList(),
      ['Today', 'Problems', 'Learn', 'Profile'],
    );
    expect(bar.selectedIndex, 0);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profile'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Who are you?'), findsOneWidget);
  });
}
