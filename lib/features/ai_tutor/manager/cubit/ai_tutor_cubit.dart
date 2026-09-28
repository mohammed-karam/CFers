import 'package:bloc/bloc.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/core/utils/constants.dart';
import 'package:fawateery/features/ai_tutor/data/models/ai_feedback_model.dart';
import 'package:fawateery/features/ai_tutor/data/repo/ai_tutor_repo.dart';

part 'ai_tutor_state.dart';

class AiTutorCubit extends Cubit<AiTutorState> {
  AiTutorCubit(this.aiTutorRepo) : super(AiTutorInitial());

  final AiTutorRepo aiTutorRepo;

  /// How many trials the student has used for the current question.
  int attemptsUsed = 0;

  /// Once the trials ended the answer field locks and the solution is shown.
  bool get trialsEnded => attemptsUsed >= kMaxAnswerTrials;

  Future<void> checkAnswer({
    required String question,
    required String answer,
  }) async {
    if (trialsEnded || state is AiTutorLoading) return;

    emit(AiTutorLoading());

    // A failed request must not burn a trial, so the attempt number is only
    // committed once the AI actually answers. The guard also makes sure the
    // spinner can never get stuck on an unexpected error.
    final attempt = attemptsUsed + 1;
    try {
      final result = await aiTutorRepo.checkAnswer(
        question: question,
        answer: answer,
        attempt: attempt,
      );

      result.fold(
        (failure) => emit(
          AiTutorFailure(
            errorMessage: failure.errorMessage,
            needsApiKey: failure is MissingApiKeyFailure,
          ),
        ),
        (feedback) {
          attemptsUsed = feedback.isCorrect ? 0 : attempt;
          emit(
            AiTutorFeedback(
              feedback: feedback,
              attempt: attempt,
              attemptsUsed: attemptsUsed,
            ),
          );
        },
      );
    } catch (_) {
      emit(
        AiTutorFailure(
          errorMessage: 'Something went wrong while contacting the AI, '
              'please try again.',
        ),
      );
    }
  }

  void reset() {
    attemptsUsed = 0;
    emit(AiTutorInitial());
  }
}
