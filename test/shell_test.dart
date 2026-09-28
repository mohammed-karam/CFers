import 'package:fawateery/features/problems/views/problems_view.dart';
import 'package:fawateery/features/shell/views/main_shell_view.dart';
import 'package:fawateery/features/shell/views/today_view.dart';
import 'package:fawateery/features/shell/widgets/today_view_body.dart';
import 'package:fawateery/features/timer/views/timer_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The problem list and the profile both reach for SharedPreferences, which
  // never resolves in the fake-async test zone unless it is mocked.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('MainShellView', () {
    testWidgets('starts on the Today tab with four destinations',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainShellView()));

      expect(find.byType(TodayViewBody), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(4));

      final navigationBar =
          tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navigationBar.selectedIndex, 0);
    });

    testWidgets('"Start with a topic" jumps to the Learn tab', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainShellView()));

      await tester.tap(find.text('Start with a topic'));
      await tester.pumpAndSettle();

      final navigationBar =
          tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navigationBar.selectedIndex, 2);
    });

    testWidgets('every tab label is reachable from the bar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainShellView()));

      // Profile is left out on purpose: it fires a Codeforces request in
      // initState, which does not belong in a navigation test.
      for (final (label, expectedIndex) in [
        ('Problems', 1),
        ('Learn', 2),
        ('Today', 0),
      ]) {
        await tester.tap(find.text(label));
        await tester.pump();

        final navigationBar =
            tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navigationBar.selectedIndex, expectedIndex, reason: label);
      }
    });

    testWidgets('the Problems tab hosts the in-app problem list',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainShellView()));

      await tester.tap(find.text('Problems'));
      await tester.pumpAndSettle();

      expect(find.byType(ProblemsView), findsOneWidget);
    });
  });

  group('TodayView', () {
    testWidgets('opens the timer screen from a quick action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TodayView(onOpenTab: (_) {}),
        ),
      );

      expect(find.byType(TodayViewBody), findsOneWidget);

      final tile = find.text('Timed practice');
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.byType(TimerView), findsOneWidget);
      expect(find.text('Enter problem rating'), findsOneWidget);
    });

    testWidgets('reports the Learn tab to its host shell', (tester) async {
      var openedTab = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: TodayView(onOpenTab: (index) => openedTab = index),
        ),
      );

      await tester.tap(find.text('Start with a topic'));
      await tester.pumpAndSettle();

      expect(openedTab, 2);
    });
  });
}
