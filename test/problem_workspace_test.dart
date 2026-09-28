import 'package:dartz/dartz.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/core/storage/solved_store.dart';
import 'package:fawateery/features/ai_tutor/views/ai_tutor_view.dart';
import 'package:fawateery/features/code_compiler/widgets/code_compiler_view_body.dart';
import 'package:fawateery/features/problems/data/models/problem_model.dart';
import 'package:fawateery/features/problems/data/models/statement_model.dart';
import 'package:fawateery/features/problems/data/repo/problems_repo.dart';
import 'package:fawateery/features/problems/views/problem_workspace_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ProblemRef _problem = ProblemRef(
  contestId: 1850,
  index: 'C',
  name: 'Roman and Numbers',
  rating: 1500,
  tags: ['math', 'number theory'],
);

const ProblemStatement _statement = ProblemStatement(
  title: 'C. Roman and Numbers',
  timeLimit: '1 second',
  memoryLimit: '256 megabytes',
  blocks: <StatementBlock>[
    StatementParagraph('Given n, count the valid permutations.'),
    StatementSample(input: '3\n1 2 3', output: '6'),
  ],
);

class _FakeProblemsRepo implements ProblemsRepo {
  _FakeProblemsRepo({this.statementFailure});

  Failure? statementFailure;

  @override
  Future<Either<Failure, List<ProblemRef>>> fetchProblems({
    bool forceRefresh = false,
  }) async {
    return const Right(<ProblemRef>[]);
  }

  @override
  Future<Either<Failure, ProblemStatement>> fetchStatement(
    ProblemRef problem,
  ) async {
    final failure = statementFailure;
    if (failure != null) return Left(failure);
    return const Right(_statement);
  }
}

Future<void> _pumpWorkspace(
  WidgetTester tester,
  _FakeProblemsRepo repo,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProblemWorkspaceView(problem: _problem, repo: repo),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SolvedStore.debugReset();
  });

  testWidgets('keeps the statement directly above the code editor',
      (tester) async {
    await _pumpWorkspace(tester, _FakeProblemsRepo());

    // One screen: statement panel and the editor share the same scaffold.
    expect(find.byType(CodeCompilerViewBody), findsOneWidget);
    expect(find.text('Problem statement'), findsOneWidget);
    expect(find.text('Given n, count the valid permutations.'), findsOneWidget);
    expect(find.text('Roman and Numbers'), findsOneWidget);

    // Samples are rendered natively, no web view in sight.
    expect(find.text('3\n1 2 3'), findsOneWidget);
  });

  testWidgets('collapses and re-expands the statement panel', (tester) async {
    await _pumpWorkspace(tester, _FakeProblemsRepo());

    await tester.tap(find.byTooltip('Collapse statement'));
    await tester.pumpAndSettle();

    expect(find.text('Given n, count the valid permutations.'), findsNothing);
    expect(find.text('Problem statement'), findsOneWidget);

    await tester.tap(find.byTooltip('Expand statement'));
    await tester.pumpAndSettle();

    expect(find.text('Given n, count the valid permutations.'), findsOneWidget);
  });

  testWidgets('marks the problem as solved from the app bar', (tester) async {
    await _pumpWorkspace(tester, _FakeProblemsRepo());

    expect(SolvedStore.instance.isSolved('1850C'), isFalse);

    await tester.tap(find.byTooltip('Mark as solved'));
    await tester.pumpAndSettle();

    expect(SolvedStore.instance.isSolved('1850C'), isTrue);
    expect(SolvedStore.instance.all.single.name, 'Roman and Numbers');

    // Tapping again takes it back off the list.
    await tester.tap(find.byTooltip('Solved — tap to undo'));
    await tester.pumpAndSettle();

    expect(SolvedStore.instance.isSolved('1850C'), isFalse);
  });

  testWidgets('hands the statement to the AI checker as the question',
      (tester) async {
    await _pumpWorkspace(tester, _FakeProblemsRepo());

    await tester.tap(find.byTooltip('Ask the AI about this problem'));
    await tester.pumpAndSettle();

    expect(find.byType(AiTutorView), findsOneWidget);

    final questions = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller?.text ?? '')
        .toList();
    expect(
      questions.any((text) => text.contains('count the valid permutations')),
      isTrue,
      reason: 'the problem statement should be prefilled as the question',
    );
  });

  testWidgets('offers a retry when the statement cannot be read',
      (tester) async {
    await _pumpWorkspace(
      tester,
      _FakeProblemsRepo(
        statementFailure:
            ServerFailure(errorMessage: 'This page is not reachable.'),
      ),
    );

    expect(find.text('This page is not reachable.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    // The editor still works while the statement is unavailable.
    expect(find.byType(CodeCompilerViewBody), findsOneWidget);
  });
}
