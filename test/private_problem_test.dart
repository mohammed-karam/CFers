import 'package:fawateery/features/private_problem/data/browse_target.dart';
import 'package:fawateery/features/private_problem/views/private_problem_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The browser's address bar — found by its hint, since the screen below it
/// holds the compiler's own text fields.
Finder addressBar() => find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Paste a link or type a name',
    );

/// Plain `Text` only — the same words sit in the address bar's field, and
/// that one is an EditableText.
Finder shownText(String value) =>
    find.byWidgetPredicate((widget) => widget is Text && widget.data == value);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('buildBrowseUri', () {
    test('an empty bar opens the search home', () {
      expect(buildBrowseUri('').toString(), 'https://www.google.com');
      expect(buildBrowseUri('   ').toString(), 'https://www.google.com');
    });

    test('a link opens as a link, with https added when missing', () {
      expect(
        buildBrowseUri('codeforces.com/blog/entry/1').toString(),
        'https://codeforces.com/blog/entry/1',
      );
      expect(
        buildBrowseUri('atcoder.jp/contests/abc300').toString(),
        'https://atcoder.jp/contests/abc300',
      );
      expect(
        buildBrowseUri('https://leetcode.com/problems/two-sum').toString(),
        'https://leetcode.com/problems/two-sum',
      );
    });

    test('a name becomes a web search, encoded', () {
      expect(
        buildBrowseUri('two sum problem').toString(),
        'https://www.google.com/search?q=two%20sum%20problem',
      );
      expect(
        buildBrowseUri('1850C roman and numbers').toString(),
        'https://www.google.com/search?q=1850C%20roman%20and%20numbers',
      );
    });

    test('a word without a dot is searched, not opened as a host', () {
      expect(
        buildBrowseUri('two-sum').toString(),
        'https://www.google.com/search?q=two-sum',
      );
    });
  });

  group('PrivateProblemView', () {
    Future<void> pumpView(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PrivateProblemView()),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('opens with a search bar over the compiler', (tester) async {
      await pumpView(tester);

      expect(find.text('Private problem'), findsWidgets);
      expect(
        addressBar(),
        findsOneWidget,
      );
      // The compiler sits under the browser panel: its language choices.
      expect(find.text('C++'), findsOneWidget);
      expect(find.text('Python 3'), findsOneWidget);
      expect(find.textContaining('Run'), findsOneWidget);
    });

    testWidgets('a typed link is resolved and offered to the browser',
        (tester) async {
      await pumpView(tester);

      await tester.enterText(
        addressBar(),
        'atcoder.jp/contests/abc300',
      );
      await tester.tap(find.byTooltip('Go'));
      await tester.pumpAndSettle();

      expect(
        shownText('https://atcoder.jp/contests/abc300'),
        findsOneWidget,
      );
      expect(find.text('Open in your browser'), findsOneWidget);
    });

    testWidgets('a typed name is resolved to a search', (tester) async {
      await pumpView(tester);

      await tester.enterText(
        addressBar(),
        'dijkstra shortest path',
      );
      await tester.tap(find.byTooltip('Go'));
      await tester.pumpAndSettle();

      expect(
        shownText('https://www.google.com/search?q=dijkstra%20shortest%20path'),
        findsOneWidget,
      );
    });

    testWidgets('the handle splits the screen between page and editor',
        (tester) async {
      await pumpView(tester);

      // The editor is the only text field that is not the address bar.
      final editor = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText != 'Paste a link or type a name',
      );
      expect(editor, findsOneWidget);

      final before = tester.getSize(editor);

      await tester.drag(
        find.byKey(const Key('private-problem-resize')),
        const Offset(0, 90),
      );
      await tester.pumpAndSettle();

      final pulledDown = tester.getSize(editor);
      expect(
        pulledDown.height,
        lessThan(before.height),
        reason: 'pulling the handle down grows the page above it',
      );

      await tester.drag(
        find.byKey(const Key('private-problem-resize')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(editor).height, greaterThan(pulledDown.height));
    });
  });
}
