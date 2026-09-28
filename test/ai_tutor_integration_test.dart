import 'dart:io' show Platform;

import 'package:fawateery/core/utils/api_service.dart';
import 'package:fawateery/features/ai_tutor/data/repo/ai_tutor_repo_impl.dart';
import 'package:flutter_test/flutter_test.dart';

// Printing the graded responses is the point of this diagnostic test.
// ignore_for_file: avoid_print

/// Hits the live Groq API — skipped unless GROQ_LIVE=1 is set, so the normal
/// test run stays hermetic:
///   GROQ_LIVE=1 flutter test test/ai_tutor_integration_test.dart
void main() {
  test('live: three trials against the real Groq API', () async {
    final repo = AiTutorRepoImpl(apiService: Api());
    const question =
        'Write a C++ program that reads an integer n and prints the sum of '
        'the first n natural numbers.';

    final first = await repo.checkAnswer(
      question: question,
      answer: 'int main() { return 0; }',
      attempt: 1,
    );
    final trial1 = first.fold((l) => throw l.errorMessage, (r) => r);
    print('TRIAL 1 -> correct=${trial1.isCorrect} '
        'hint="${trial1.hint}" solution="${trial1.solution}"');
    expect(trial1.isCorrect, isFalse);
    expect(trial1.hasHint, isTrue);
    expect(trial1.hasSolution, isFalse);

    final third = await repo.checkAnswer(
      question: question,
      answer: '#include <iostream>\nusing namespace std;\n'
          'int main(){int n;cin>>n;cout<<n*n;return 0;}',
      attempt: 3,
    );
    final trial3 = third.fold((l) => throw l.errorMessage, (r) => r);
    print('TRIAL 3 -> correct=${trial3.isCorrect} '
        'hint="${trial3.hint}"');
    print('SOLUTION -> ${trial3.solution}');
    expect(trial3.isCorrect, isFalse);
    expect(trial3.hasSolution, isTrue);

    final correct = await repo.checkAnswer(
      question: 'What is the time complexity of binary search?',
      answer: 'O(log n)',
      attempt: 1,
    );
    final ok = correct.fold((l) => throw l.errorMessage, (r) => r);
    print('CORRECT -> ${ok.feedback}');
    expect(ok.isCorrect, isTrue);
    expect(ok.hasSolution, isFalse);
  },
      timeout: const Timeout(Duration(minutes: 3)),
      skip: !Platform.environment.containsKey('GROQ_LIVE'));
}
