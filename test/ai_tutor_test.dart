import 'package:dartz/dartz.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/core/storage/app_settings.dart';
import 'package:fawateery/features/ai_tutor/data/models/ai_feedback_model.dart';
import 'package:fawateery/features/ai_tutor/data/repo/ai_tutor_repo.dart';
import 'package:fawateery/features/ai_tutor/manager/cubit/ai_tutor_cubit.dart';
import 'package:fawateery/features/ai_tutor/widgets/ai_tutor_view_body.dart';
import 'package:fawateery/features/materials/views/resources_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements AiTutorRepo {
  _FakeRepo({this.failNext = false});

  /// Answers given by the fake AI, consumed one per call.
  final List<AiFeedbackModel> answers = [
    const AiFeedbackModel(
      isCorrect: false,
      feedback: 'Not quite.',
      hint: 'Try reading the input first.',
    ),
    const AiFeedbackModel(
      isCorrect: false,
      feedback: 'Still wrong.',
      hint: 'Use the formula n*(n+1)/2.',
    ),
    const AiFeedbackModel(
      isCorrect: false,
      feedback: 'Wrong again.',
      hint: 'Fix the printed expression.',
      solution: 'Sum = n*(n+1)/2',
    ),
    const AiFeedbackModel(isCorrect: true, feedback: 'Exactly right.'),
  ];

  final List<int> requestedAttempts = [];
  bool failNext;

  @override
  Future<Either<Failure, AiFeedbackModel>> checkAnswer({
    required String question,
    required String answer,
    required int attempt,
  }) async {
    requestedAttempts.add(attempt);

    if (failNext) {
      failNext = false;
      return Left(ServerFailure(errorMessage: 'The AI is unavailable'));
    }

    // Attempt numbers stay 1-based even after the counter resets.
    final index = (attempt - 1).clamp(0, answers.length - 1);
    return Right(answers[index]);
  }
}

class _ThrowingRepo implements AiTutorRepo {
  @override
  Future<Either<Failure, AiFeedbackModel>> checkAnswer({
    required String question,
    required String answer,
    required int attempt,
  }) async {
    // An Error (not an Exception) — the spinner must still recover.
    throw StateError('boom');
  }
}

void main() {
  setUp(() async {
    // The checker runs on each student's own Groq key now, so the suite has
    // to provide one before anything can be submitted. Tests that cover the
    // missing-key prompt clear it themselves.
    AppSettings.debugReset();
    await AppSettings.instance.setGroqApiKey('gsk_test_key');
  });

  group('AiFeedbackModel.fromRawResponse', () {
    test('parses a plain JSON object', () {
      final model = AiFeedbackModel.fromRawResponse(
        '{"verdict":"incorrect","feedback":"nope","hint":"try again","solution":""}',
      );

      expect(model.isCorrect, isFalse);
      expect(model.feedback, 'nope');
      expect(model.hint, 'try again');
      expect(model.hasSolution, isFalse);
    });

    test('parses JSON wrapped in markdown fences with surrounding prose', () {
      final model = AiFeedbackModel.fromRawResponse(
        'Sure! Here is the grading:\n```json\n'
        '{"verdict":"correct","feedback":"well done","hint":"","solution":""}\n'
        '```',
      );

      expect(model.isCorrect, isTrue);
      expect(model.feedback, 'well done');
      expect(model.hasHint, isFalse);
    });

    test('falls back to raw text when the model breaks the format', () {
      final model = AiFeedbackModel.fromRawResponse('I cannot grade that.');

      expect(model.isCorrect, isFalse);
      expect(model.feedback, 'I cannot grade that.');
    });

    test('treats a solution as present only when it has content', () {
      final model = AiFeedbackModel.fromRawResponse(
        '{"verdict":"incorrect","feedback":"wrong","hint":"hint",'
        '"solution":"  step 1 ...  "}',
      );

      expect(model.hasSolution, isTrue);
      expect(model.solution, 'step 1 ...');
    });
  });

  group('AiTutorCubit', () {
    test('walks the three trials and reveals the solution on the third', () async {
      final repo = _FakeRepo();
      final cubit = AiTutorCubit(repo);

      await cubit.checkAnswer(question: 'Q', answer: 'A');
      expect(cubit.attemptsUsed, 1);
      expect(cubit.trialsEnded, isFalse);
      expect(
        (cubit.state as AiTutorFeedback).feedback.hasHint,
        isTrue,
      );

      await cubit.checkAnswer(question: 'Q', answer: 'A');
      expect(cubit.attemptsUsed, 2);
      expect(cubit.trialsEnded, isFalse);

      await cubit.checkAnswer(question: 'Q', answer: 'A');
      expect(cubit.attemptsUsed, 3);
      expect(cubit.trialsEnded, isTrue);

      final state = cubit.state as AiTutorFeedback;
      expect(state.feedback.hasSolution, isTrue);
      expect(state.feedback.solution, 'Sum = n*(n+1)/2');

      // No further calls once the trials ended.
      await cubit.checkAnswer(question: 'Q', answer: 'A');
      expect(repo.requestedAttempts, [1, 2, 3]);

      cubit.close();
    });

    test('resets the trials when the answer is correct', () async {
      final repo = _FakeRepo();
      final cubit = AiTutorCubit(repo);

      await cubit.checkAnswer(question: 'Q', answer: 'A');
      await cubit.checkAnswer(question: 'Q', answer: 'A');
      expect(cubit.attemptsUsed, 2);

      // Third answer happens to be the correct one in this fake.
      repo.answers[2] = const AiFeedbackModel(
        isCorrect: true,
        feedback: 'Spot on.',
      );
      await cubit.checkAnswer(question: 'Q', answer: 'A');

      expect(cubit.attemptsUsed, 0);
      expect(cubit.trialsEnded, isFalse);
      expect((cubit.state as AiTutorFeedback).feedback.isCorrect, isTrue);

      // The counter restarted, so the next trial is #1 again.
      await cubit.checkAnswer(question: 'Q', answer: 'A');
      expect(repo.requestedAttempts, [1, 2, 3, 1]);

      cubit.close();
    });

    test('a failed request does not consume a trial', () async {
      final repo = _FakeRepo(failNext: true);
      final cubit = AiTutorCubit(repo);

      await cubit.checkAnswer(question: 'Q', answer: 'A');

      expect(cubit.state, isA<AiTutorFailure>());
      expect(cubit.attemptsUsed, 0);

      await cubit.checkAnswer(question: 'Q', answer: 'A');
      expect(cubit.attemptsUsed, 1);
      expect(repo.requestedAttempts, [1, 1]);

      cubit.close();
    });

    test('reset clears the trials and returns to the initial state', () async {
      final cubit = AiTutorCubit(_FakeRepo());

      await cubit.checkAnswer(question: 'Q', answer: 'A');
      cubit.reset();

      expect(cubit.state, isA<AiTutorInitial>());
      expect(cubit.attemptsUsed, 0);
      expect(cubit.trialsEnded, isFalse);

      cubit.close();
    });

    test('an unexpected error surfaces as a failure instead of hanging',
        () async {
      final cubit = AiTutorCubit(_ThrowingRepo());

      await cubit.checkAnswer(question: 'Q', answer: 'A');

      expect(cubit.state, isA<AiTutorFailure>());
      expect(cubit.attemptsUsed, 0);

      cubit.close();
    });
  });

  group('AiTutorViewBody', () {
    Future<void> pumpView(WidgetTester tester, AiTutorCubit cubit) async {
      // A phone-sized screen so the whole form fits without scrolling.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AiTutorCubit>.value(
            value: cubit,
            child: const AiTutorViewBody(),
          ),
        ),
      );
    }

    Future<void> submitAnswer(WidgetTester tester) async {
      final finder = find.textContaining('Check my answer');
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('hints on each trial and reveals the solution on the third',
        (tester) async {
      final cubit = AiTutorCubit(_FakeRepo());
      await pumpView(tester, cubit);

      expect(find.text('Check your answer'), findsOneWidget);
      expect(find.textContaining('Trial 1 of 3'), findsOneWidget);
      expect(find.textContaining('Your correction will appear here'),
          findsOneWidget);
      expect(find.text('0 of 3 used'), findsOneWidget);

      // Both fields are required.
      await submitAnswer(tester);
      expect(
        find.text(
          'Please fill in both the question and your answer.',
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.enterText(find.byType(TextField).at(0), 'What is 2 + 2?');
      await tester.enterText(find.byType(TextField).at(1), '5');

      // Trial 1 → incorrect + hint.
      await submitAnswer(tester);
      expect(find.text('Incorrect'), findsOneWidget);
      expect(find.text('Hint'), findsOneWidget);
      expect(find.textContaining('Used 1 of 3 trials'), findsOneWidget);
      expect(find.text('Solution'), findsNothing);

      // Trial 2 → stronger hint, still no solution.
      await submitAnswer(tester);
      expect(find.textContaining('Used 2 of 3 trials'), findsOneWidget);
      expect(find.text('Solution'), findsNothing);

      // Trial 3 → trials ended, full solution revealed.
      await submitAnswer(tester);
      expect(find.text('Solution'), findsOneWidget);
      expect(
        find.textContaining('All 3 trials ended'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Trials ended — solution revealed'),
        findsOneWidget,
      );
      expect(find.text('Solution revealed'), findsOneWidget);

      // The submit button is locked, but "Start over" is available.
      final submitButton =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(submitButton.onPressed, isNull);

      await tester.tap(find.text('Start over'));
      await tester.pumpAndSettle();
      expect(find.text('0 of 3 used'), findsOneWidget);
      expect(
        find.textContaining('Your correction will appear here'),
        findsOneWidget,
      );
      expect(cubit.trialsEnded, isFalse);

      cubit.close();
    });
  });

  group('entry point', () {
    testWidgets('Resources screen opens the AI Answer Checker', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: ResourcesView()));
      await tester.pumpAndSettle();

      expect(find.text('AI ANSWER CHECKER'), findsOneWidget);

      await tester.tap(find.text('AI ANSWER CHECKER'));
      await tester.pumpAndSettle();

      expect(find.text('Check your answer'), findsOneWidget);
      expect(find.textContaining('Trial 1 of 3'), findsOneWidget);
    });
  });
}
