import 'package:dartz/dartz.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/features/ai_tutor/data/models/ai_feedback_model.dart';

abstract class AiTutorRepo {
  /// Sends the student's answer to the AI for correction.
  ///
  /// [attempt] is 1-based: 1..2 ask for a hint only, 3 is the final trial and
  /// also asks for the complete solution.
  Future<Either<Failure, AiFeedbackModel>> checkAnswer({
    required String question,
    required String answer,
    required int attempt,
  });
}
