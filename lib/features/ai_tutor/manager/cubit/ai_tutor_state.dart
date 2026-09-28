part of 'ai_tutor_cubit.dart';

sealed class AiTutorState {}

final class AiTutorInitial extends AiTutorState {}

final class AiTutorLoading extends AiTutorState {}

final class AiTutorFeedback extends AiTutorState {
  final AiFeedbackModel feedback;

  /// The trial that produced this feedback (1-based).
  final int attempt;

  /// Trials consumed after this feedback (reset to 0 on a correct answer).
  final int attemptsUsed;

  AiTutorFeedback({
    required this.feedback,
    required this.attempt,
    required this.attemptsUsed,
  });
}

final class AiTutorFailure extends AiTutorState {
  final String errorMessage;

  /// True when the student simply has no API key yet — the fix is pasting
  /// one, not retrying.
  final bool needsApiKey;

  AiTutorFailure({required this.errorMessage, this.needsApiKey = false});
}
