import 'dart:convert';

/// Feedback returned by the AI for a single answer trial.
class AiFeedbackModel {
  const AiFeedbackModel({
    required this.isCorrect,
    required this.feedback,
    this.hint = '',
    this.solution = '',
  });

  final bool isCorrect;

  /// Short explanation of why the answer is right or wrong.
  final String feedback;

  /// Guidance for the next trial — empty when the answer is correct.
  final String hint;

  /// Full step-by-step solution — only filled once the trials ended.
  final String solution;

  bool get hasHint => hint.trim().isNotEmpty;
  bool get hasSolution => solution.trim().isNotEmpty;

  /// Parses the model output leniently: tolerates markdown code fences,
  /// stray prose around the object, and missing keys.
  factory AiFeedbackModel.fromRawResponse(String raw) {
    final json = _extractJson(raw);
    if (json == null) {
      // The model broke the format — fall back to showing it as feedback so
      // the student still gets something useful.
      return AiFeedbackModel(isCorrect: false, feedback: raw.trim());
    }

    String read(String key) {
      final value = json[key];
      if (value == null) return '';
      return value.toString().trim();
    }

    final verdict = read('verdict').toLowerCase();
    return AiFeedbackModel(
      isCorrect: verdict == 'correct' || verdict == 'true' || verdict == 'yes',
      feedback: read('feedback'),
      hint: read('hint'),
      solution: read('solution'),
    );
  }

  static Map<String, dynamic>? _extractJson(String raw) {
    var text = raw.trim();

    // Strip ```json ... ``` fences when present.
    final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$');
    final fenceMatch = fence.firstMatch(text);
    if (fenceMatch != null) text = fenceMatch.group(1)!.trim();

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) return null;

    try {
      final decoded = jsonDecode(text.substring(start, end + 1));
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      return null;
    }
    return null;
  }
}
