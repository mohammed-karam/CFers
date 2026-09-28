import 'package:dartz/dartz.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/core/storage/solved_store.dart';
import 'package:fawateery/features/problems/data/models/problem_model.dart';
import 'package:fawateery/features/problems/data/models/statement_model.dart';
import 'package:fawateery/features/problems/data/repo/problems_repo.dart';
import 'package:fawateery/features/problems/views/problems_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProblemsRepo implements ProblemsRepo {
  _FakeProblemsRepo({this.problems = const <ProblemRef>[], this.failure});

  List<ProblemRef> problems;
  Failure? failure;
  int calls = 0;

  @override
  Future<Either<Failure, List<ProblemRef>>> fetchProblems({
    bool forceRefresh = false,
  }) async {
    calls++;
    final failure = this.failure;
    if (failure != null) return Left(failure);
    return Right(problems);
  }

  @override
  Future<Either<Failure, ProblemStatement>> fetchStatement(
    ProblemRef problem,
  ) async {
    return Right(
      ProblemStatement(
        title: problem.name,
        blocks: const <StatementBlock>[StatementParagraph('Placeholder.')],
      ),
    );
  }
}

List<ProblemRef> _problems() => [
      const ProblemRef(
        contestId: 1,
        index: 'A',
        name: 'Theatre Square',
        rating: 900,
        tags: ['math'],
      ),
      const ProblemRef(
        contestId: 1850,
        index: 'C',
        name: 'Roman and Numbers',
        rating: 1500,
        tags: ['math', 'number theory'],
      ),
      const ProblemRef(
        contestId: 1791,
        index: 'F',
        name: 'Very Hard',
        rating: 2400,
        tags: ['dp'],
      ),
    ];

Future<void> _pumpList(WidgetTester tester, _FakeProblemsRepo repo) async {
  await tester.pumpWidget(MaterialApp(home: ProblemsView(repo: repo)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SolvedStore.debugReset();
  });

  testWidgets('lists the problems with rating badges', (tester) async {
    await _pumpList(tester, _FakeProblemsRepo(problems: _problems()));

    expect(find.text('Theatre Square'), findsOneWidget);
    expect(find.text('Roman and Numbers'), findsOneWidget);
    expect(find.text('Very Hard'), findsOneWidget);
    expect(find.text('900'), findsOneWidget);
    expect(find.text('2400'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('search narrows the list and clears again', (tester) async {
    await _pumpList(tester, _FakeProblemsRepo(problems: _problems()));

    await tester.enterText(find.byType(TextField), 'roman');
    await tester.pumpAndSettle();

    expect(find.text('Roman and Numbers'), findsOneWidget);
    expect(find.text('Theatre Square'), findsNothing);
    expect(find.text('Very Hard'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('Theatre Square'), findsOneWidget);
    expect(find.text('Very Hard'), findsOneWidget);
  });

  testWidgets('the Solved and Unsolved filters use the tracking', (tester) async {
    await SolvedStore.instance.mark(id: '1850C', name: 'Roman and Numbers');
    await _pumpList(tester, _FakeProblemsRepo(problems: _problems()));

    await tester.tap(find.text('Unsolved'));
    await tester.pumpAndSettle();

    expect(find.text('Theatre Square'), findsOneWidget);
    expect(find.text('Roman and Numbers'), findsNothing);

    await tester.tap(find.text('Solved'));
    await tester.pumpAndSettle();

    expect(find.text('Roman and Numbers'), findsOneWidget);
    expect(find.text('Theatre Square'), findsNothing);
  });

  testWidgets('difficulty chips filter by rating band', (tester) async {
    await _pumpList(tester, _FakeProblemsRepo(problems: _problems()));

    await tester.tap(find.text('Hard'));
    await tester.pumpAndSettle();

    expect(find.text('Very Hard'), findsOneWidget);
    expect(find.text('Theatre Square'), findsNothing);
    expect(find.text('Roman and Numbers'), findsNothing);
  });

  testWidgets('shows the failure card and retries when the list is empty',
      (tester) async {
    final repo = _FakeProblemsRepo(failure: ServerFailure(errorMessage: 'No connection'));
    await _pumpList(tester, repo);

    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(repo.calls, 1);

    repo.failure = null;
    repo.problems = _problems();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Theatre Square'), findsOneWidget);
    expect(repo.calls, 2);
  });

  testWidgets('shows the empty state when filters match nothing',
      (tester) async {
    await _pumpList(tester, _FakeProblemsRepo(problems: _problems()));

    await tester.enterText(find.byType(TextField), 'zzz-not-a-problem');
    await tester.pumpAndSettle();

    expect(find.text('No problems match these filters.'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(find.text('Theatre Square'), findsOneWidget);
  });
}
