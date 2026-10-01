/// One submission, exactly as Codeforces' public API reports it.
///
/// The app never posts code itself — it hands the code to Codeforces' own
/// submit page in a web view — but reading the verdict back goes through the
/// public API, which is the only part of Codeforces that answers without a
/// browser check.
class CfSubmission {
  const CfSubmission({
    required this.id,
    required this.creationTimeSeconds,
    required this.verdict,
    required this.problemCode,
    required this.language,
    this.passedTests,
  });

  /// Numeric id of the submission, e.g. `392217392`.
  final int id;

  /// Seconds since epoch, on Codeforces' clock.
  final int creationTimeSeconds;

  /// The verdict as the API spells it: `TESTING`, `OK`, `WRONG_ANSWER`, …
  final String verdict;

  /// Contest + index, e.g. `1850C` — the same shape as the problem ids the
  /// app already uses for progress tracking.
  final String problemCode;

  /// The judge's name for the language, e.g. `GNU G++17 7.3.0 (64 bit)`.
  final String language;

  /// Tests that passed before the failure, when the API reports it.
  final int? passedTests;

  /// Still in the queue or being judged.
  bool get isJudging => verdict.isEmpty || verdict == 'TESTING';

  bool get isAccepted => verdict == 'OK';

  /// Age against the device clock; negative when the clocks disagree, which
  /// still counts as "just submitted".
  int get ageInSeconds =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 - creationTimeSeconds;

  /// Fresh enough to still be the verdict worth refreshing.
  bool get isRecent => ageInSeconds.abs() < 180;

  /// What the student reads on the website: `Accepted`, `Wrong answer on
  /// test 4`, `Running…`.
  String get friendlyVerdict {
    if (isJudging) return 'Running…';

    final name = switch (verdict) {
      'OK' => 'Accepted',
      'PARTIAL' => 'Partial answer',
      'COMPILATION_ERROR' => 'Compilation error',
      'WRONG_ANSWER' => 'Wrong answer',
      'RUNTIME_ERROR' => 'Runtime error',
      'TIME_LIMIT_EXCEEDED' => 'Time limit exceeded',
      'MEMORY_LIMIT_EXCEEDED' => 'Memory limit exceeded',
      'IDLENESS_LIMIT_EXCEEDED' => 'Idleness limit exceeded',
      'SECURITY_VIOLATED' => 'Security violation',
      'CHALLENGED' => 'Hacked',
      'SKIPPED' => 'Skipped',
      'DENIED' => 'Denied',
      'CRASHED' => 'Crashed',
      _ => verdict.isEmpty ? 'Unknown' : verdict,
    };

    // Failures that happen on a specific test carry the number of the test
    // that broke it: the API counts the tests that passed, so the culprit is
    // the next one.
    final counted = const <String>{
      'WRONG_ANSWER',
      'RUNTIME_ERROR',
      'TIME_LIMIT_EXCEEDED',
      'MEMORY_LIMIT_EXCEEDED',
      'IDLENESS_LIMIT_EXCEEDED',
      'CRASHED',
    };
    final passed = passedTests;
    if (passed != null && counted.contains(verdict)) {
      return '$name on test ${passed + 1}';
    }
    return name;
  }

  /// A coloured dot for the verdict, matching how the app tints results.
  bool get looksGood => isAccepted;

  factory CfSubmission.fromApiJson(Map<String, dynamic> json) {
    final problem = json['problem'];
    var code = '';
    if (problem is Map<String, dynamic>) {
      final contestId = problem['contestId'];
      final index = problem['index'];
      if (contestId != null && index != null) code = '$contestId$index';
    }

    final passed = json['passedTests'];

    return CfSubmission(
      id: json['id'] is int ? json['id'] as int : 0,
      creationTimeSeconds:
          json['creationTimeSeconds'] is int ? json['creationTimeSeconds'] as int : 0,
      verdict: json['verdict']?.toString() ?? '',
      problemCode: code,
      language: json['programmingLanguage']?.toString() ?? '',
      passedTests: passed is int ? passed : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'creationTimeSeconds': creationTimeSeconds,
        'verdict': verdict,
        'problemCode': problemCode,
        'language': language,
        'passedTests': passedTests,
      };

  factory CfSubmission.fromJson(Map<String, dynamic> json) => CfSubmission(
        id: json['id'] as int? ?? 0,
        creationTimeSeconds: json['creationTimeSeconds'] as int? ?? 0,
        verdict: json['verdict'] as String? ?? '',
        problemCode: json['problemCode'] as String? ?? '',
        language: json['language'] as String? ?? '',
        passedTests: json['passedTests'] is int ? json['passedTests'] as int : null,
      );
}
