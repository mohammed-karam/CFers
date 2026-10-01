import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/core/storage/app_settings.dart';
import 'package:fawateery/core/storage/solved_store.dart';
import 'package:fawateery/features/code_compiler/data/constants/supported_languages.dart';
import 'package:fawateery/features/problems/data/models/problem_model.dart';
import 'package:fawateery/features/problems/data/models/statement_model.dart';
import 'package:fawateery/features/problems/data/repo/problems_repo.dart';
import 'package:fawateery/features/problems/views/problem_workspace_view.dart';
import 'package:fawateery/features/submit/data/cf_scripts.dart';
import 'package:fawateery/features/submit/data/cf_submission.dart';
import 'package:fawateery/features/submit/data/cf_submissions_api.dart';
import 'package:fawateery/features/submit/data/cf_verdict_store.dart';
import 'package:fawateery/features/submit/manager/cubit/submit_cubit.dart';
import 'package:fawateery/features/submit/views/submit_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ProblemRef _problem = ProblemRef(
  contestId: 1850,
  index: 'C',
  name: 'Roman and Numbers',
  rating: 1500,
  tags: ['math'],
);

class _FakeProblemsRepo implements ProblemsRepo {
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
    return const Right(ProblemStatement(
      title: 'C. Roman and Numbers',
      timeLimit: '1 second',
      memoryLimit: '256 megabytes',
      blocks: <StatementBlock>[
        StatementParagraph('Given n, count the valid permutations.'),
        StatementSample(input: '3\n1 2 3', output: '6'),
      ],
    ));
  }
}

/// One row of `user.status`, shaped the way Codeforces' API sends it.
http.Response _apiResponse({
  String verdict = 'OK',
  int id = 392217392,
  int? passedTests,
  String problemCode = '1850C',
}) {
  final contestId = int.parse(
    problemCode.replaceAll(RegExp(r'[A-Za-z]+$'), ''),
  );
  final index = problemCode.substring('$contestId'.length);

  return http.Response(
    jsonEncode(<String, dynamic>{
      'status': 'OK',
      'result': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': id,
          'creationTimeSeconds':
              DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'verdict': verdict,
          'programmingLanguage': 'GNU G++17 7.3.0 (64 bit)',
          if (passedTests != null) 'passedTests': passedTests,
          'problem': <String, dynamic>{
            'contestId': contestId,
            'index': index,
            'name': 'Roman and Numbers',
          },
        },
      ],
    }),
    200,
    headers: {'content-type': 'application/json'},
  );
}

SubmitCubit _cubit({
  required MockClient client,
  String handle = 'someone',
  Duration pollEvery = const Duration(milliseconds: 1),
}) {
  return SubmitCubit(
    problemCode: '1850C',
    api: CfSubmissionsApi(client: client),
    handle: handle,
    pollEvery: pollEvery,
    giveUpAfter: const Duration(seconds: 10),
  );
}

/// This Flutter version builds `.icon` buttons as private subclasses
/// (`_OutlinedButtonWithIcon`), so `find.byType(OutlinedButton)` never matches
/// them — the button is reached through its label instead.
Finder submitButton() => find.ancestor(
      of: find.text('Submit to Codeforces'),
      matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSettings.debugReset();
    SolvedStore.debugReset();
    CfVerdictStore.debugReset();
  });

  // ── The scripts that run inside Codeforces' own page ─────────────────────

  group('handing the form over to the page', () {
    test('the prefill script carries the problem, the code and the language',
        () {
      final script = cfPrefillScript(
        problemCode: '1850C',
        source: 'int main() { return 0; }',
        language: 'cpp',
      );

      expect(script, contains('CfSubmit.postMessage'));
      expect(script, contains('"1850C"'));
      expect(script, contains('"int main() { return 0; }"'));
      expect(script, contains('"cpp"'));
      expect(script, contains('programTypeId'));
      expect(script, contains('submittedProblemCode'));
    });

    test('the click script presses the page\'s own Submit button', () {
      final script = cfClickSubmitScript();

      expect(script, contains('CfSubmit.postMessage'));
      expect(script, contains('input.submit'));
      // A refusal is always reported back, never swallowed.
      expect(script, contains('ok: false'));
      expect(script, contains('ok: true'));
    });

    test('every language the editor offers has a hint on the page', () {
      expect(cfLanguageHint('C++'), 'cpp');
      expect(cfLanguageHint('C'), 'c');
      expect(cfLanguageHint('Python 3'), 'python3');
      expect(cfLanguageHint('Java'), 'java');
      expect(cfLanguageHint('Rust'), 'rust');
      expect(cfLanguageHint('Go'), 'go');
      expect(cfLanguageHint('C#'), 'csharp');
      // Unknown languages leave the page's own choice alone.
      expect(cfLanguageHint('Kotlin'), '');
    });
  });

  // ── Reading the verdict back ─────────────────────────────────────────────

  group('reading the verdict', () {
    test('parses the newest submission of the public API', () async {
      final api = CfSubmissionsApi(
        client: MockClient((request) async {
          expect(request.url.host, 'codeforces.com');
          expect(request.url.path, '/api/user.status');
          expect(request.url.queryParameters['handle'], 'someone');
          return _apiResponse(verdict: 'OK', passedTests: 12);
        }),
      );

      final result = await api.latestFor('someone');
      final submission = result.fold<CfSubmission?>((_) => null, (s) => s);

      expect(submission, isNotNull);
      expect(submission!.problemCode, '1850C');
      expect(submission.friendlyVerdict, 'Accepted');
      expect(submission.isAccepted, isTrue);
    });

    test('turns a rejection into a failure instead of an exception', () async {
      final api = CfSubmissionsApi(
        client: MockClient((_) async => http.Response(
              jsonEncode(<String, dynamic>{
                'status': 'FAILED',
                'comment': 'handle: Field must be a valid handle.',
              }),
              200,
            )),
      );

      final result = await api.latestFor('someone');

      expect(result.isLeft(), isTrue);
      final failure = result.fold<Failure>((f) => f, (_) => throw 'ok');
      expect(failure.errorMessage, contains('valid handle'));
    });

    test('an unreachable API reads as "cannot reach Codeforces"', () async {
      final api = CfSubmissionsApi(
        client: MockClient((_) async =>
            throw http.ClientException('connection refused')),
      );

      final result = await api.latestFor('someone');

      expect(result.isLeft(), isTrue);
      final failure = result.fold<Failure>((f) => f, (_) => throw 'ok');
      expect(failure.errorMessage, contains('reach Codeforces'));
    });

    test('names the verdict the way the website does', () {
      CfSubmission make(String verdict, {int? passedTests}) => CfSubmission(
            id: 1,
            creationTimeSeconds: 0,
            verdict: verdict,
            problemCode: '1850C',
            language: 'GNU G++17',
            passedTests: passedTests,
          );

      expect(make('TESTING').friendlyVerdict, 'Running…');
      expect(make('OK').friendlyVerdict, 'Accepted');
      expect(make('WRONG_ANSWER', passedTests: 3).friendlyVerdict,
          'Wrong answer on test 4');
      expect(
        make('TIME_LIMIT_EXCEEDED', passedTests: 0).friendlyVerdict,
        'Time limit exceeded on test 1',
      );
      expect(
        make('COMPILATION_ERROR').friendlyVerdict,
        'Compilation error',
      );
    });
  });

  // ── The hand-over, state by state ────────────────────────────────────────

  group('the hand-over states', () {
    test('waits for the verdict and keeps it for the workspace', () async {
      var calls = 0;
      final cubit = _cubit(
        client: MockClient((_) async {
          calls++;
          return _apiResponse(verdict: calls < 2 ? 'TESTING' : 'OK');
        }),
      );
      addTearDown(cubit.close);

      cubit.jsMessage(jsonEncode(<String, dynamic>{
        'step': 'prefill',
        'problem': true,
        'source': true,
        'chosen': 'GNU G++17 7.3.0 (64 bit)',
      }));
      expect(cubit.state, isA<SubmitReady>());
      expect((cubit.state as SubmitReady).language, 'GNU G++17 7.3.0 (64 bit)');

      cubit.submit();
      expect(cubit.state, isA<SubmitClicking>());

      cubit.jsMessage(jsonEncode(<String, dynamic>{
        'step': 'click',
        'ok': true,
      }));
      expect(cubit.state, isA<SubmitWaiting>());

      await expectLater(cubit.stream, emitsThrough(isA<SubmitDone>()));

      expect(calls, greaterThanOrEqualTo(2),
          reason: 'it should watch past the running stage');
      expect(CfVerdictStore.instance.read()?.verdict, 'OK');
      expect(CfVerdictStore.instance.read()?.problemCode, '1850C');
    });

    test('asks for a handle before it can promise a verdict', () async {
      final cubit = _cubit(
        client: MockClient((_) async => _apiResponse()),
        handle: '',
      );
      addTearDown(cubit.close);

      cubit.jsMessage(jsonEncode(<String, dynamic>{
        'step': 'prefill',
        'problem': true,
        'source': true,
        'chosen': '',
      }));
      expect(cubit.state, isA<SubmitNeedsHandle>());

      // Nothing is sent while the verdict could not be watched.
      cubit.submit();
      expect(cubit.state, isA<SubmitNeedsHandle>());

      await cubit.saveHandle('  someone  ');
      expect(cubit.state, isA<SubmitReady>());
      expect(cubit.hasHandle, isTrue);
      expect(AppSettings.instance.codeforcesHandle, 'someone');
    });

    test('reports a form that would not fill itself in', () {
      final cubit = _cubit(client: MockClient((_) async => _apiResponse()));
      addTearDown(cubit.close);

      cubit.jsMessage(jsonEncode(<String, dynamic>{
        'step': 'prefill',
        'problem': false,
        'source': true,
        'chosen': '',
      }));

      expect(cubit.state, isA<SubmitFailed>());
      expect((cubit.state as SubmitFailed).message, contains('Reload'));
    });

    test('reads a sign-in page and a page that is not the form', () {
      final cubit = _cubit(client: MockClient((_) async => _apiResponse()));
      addTearDown(cubit.close);

      cubit.pageFinished('https://codeforces.com/blog/entry/1');
      expect(cubit.state, isA<SubmitFailed>());

      cubit.pageFinished('https://codeforces.com/enter');
      expect(cubit.state, isA<SubmitNeedsLogin>());
    });

    test('says so plainly when the device has no in-app page', () {
      final cubit = _cubit(client: MockClient((_) async => _apiResponse()));
      addTearDown(cubit.close);

      cubit.pageUnavailable();

      expect(cubit.state, isA<SubmitFailed>());
      expect((cubit.state as SubmitFailed).message, contains('browser'));
    });

    test('a reload after sending leaves the wait on screen', () async {
      final cubit = _cubit(
        client: MockClient((_) async => _apiResponse(verdict: 'TESTING')),
      );
      addTearDown(cubit.close);

      cubit.jsMessage(jsonEncode(<String, dynamic>{
        'step': 'prefill',
        'problem': true,
        'source': true,
        'chosen': 'GNU G++17',
      }));
      cubit.submit();
      cubit.jsMessage(jsonEncode(<String, dynamic>{'step': 'click', 'ok': true}));
      expect(cubit.state, isA<SubmitWaiting>());

      // The page fills its form again (a reload, a second look) — the wait
      // for the verdict must not be pushed off the screen by it.
      cubit.jsMessage(jsonEncode(<String, dynamic>{
        'step': 'prefill',
        'problem': true,
        'source': true,
        'chosen': '',
      }));

      expect(cubit.state, isA<SubmitWaiting>());
    });
  });

  // ── The screens ──────────────────────────────────────────────────────────

  group('the screens', () {
    testWidgets('opens the submit screen with the code from the editor',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProblemWorkspaceView(
            problem: _problem,
            repo: _FakeProblemsRepo(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The button sits directly under Run.
      expect(submitButton(), findsOneWidget);
      expect(find.byType(SubmitView), findsNothing);

      await tester.tap(submitButton());
      await tester.pumpAndSettle();

      expect(find.byType(SubmitView), findsOneWidget);
      final view = tester.widget<SubmitView>(find.byType(SubmitView));
      expect(view.problem.id, '1850C');
      expect(view.code, contains('Hello, World!'),
          reason: 'the editor contents are what gets handed over');
      expect(view.language.displayName, 'C++');
    });

    testWidgets('falls back to a browser link where there is no web view',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SubmitView(
            problem: _problem,
            code: 'int main() {}',
            language: kSupportedLanguages.first,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The problem shows up in the app bar and again in the card.
      expect(find.textContaining('1850 C'), findsAtLeastNWidgets(1),
          reason: 'the app bar says which problem');
      expect(find.text('Open on Codeforces'), findsOneWidget);
      expect(
        find.textContaining('cannot open here'),
        findsOneWidget,
        reason: 'the strip explains why nothing can be prefilled',
      );
      // Without a page there is nothing to send, so no send button (the app
      // bar's title carries the same words, hence going through the button).
      expect(submitButton(), findsNothing);
    });

    testWidgets('shows the verdict above Run once the student comes back',
        (tester) async {
      await CfVerdictStore.instance.write(
        const CfSubmission(
          id: 42,
          creationTimeSeconds: 1,
          verdict: 'OK',
          problemCode: '1850C',
          language: 'GNU G++17 7.3.0 (64 bit)',
          passedTests: 12,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProblemWorkspaceView(
            problem: _problem,
            repo: _FakeProblemsRepo(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accepted'), findsOneWidget);
      expect(
        find.text('1850C · GNU G++17 7.3.0 (64 bit)'),
        findsOneWidget,
      );
    });

    testWidgets('says nothing when the last submission was another problem',
        (tester) async {
      await CfVerdictStore.instance.write(
        const CfSubmission(
          id: 43,
          creationTimeSeconds: 1,
          verdict: 'WRONG_ANSWER',
          problemCode: '1901A',
          language: 'Python 3.9.5',
          passedTests: 2,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProblemWorkspaceView(
            problem: _problem,
            repo: _FakeProblemsRepo(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Wrong answer on test 3'), findsNothing);
      expect(submitButton(), findsOneWidget);
    });
  });
}
