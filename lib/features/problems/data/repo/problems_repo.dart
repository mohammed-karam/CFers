import 'package:dartz/dartz.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/features/problems/data/models/problem_model.dart';
import 'package:fawateery/features/problems/data/models/statement_model.dart';

abstract class ProblemsRepo {
  /// Every problem in the Codeforces problemset (cache first, network to
  /// refresh).
  Future<Either<Failure, List<ProblemRef>>> fetchProblems({
    bool forceRefresh = false,
  });

  /// The statement of one problem, read from cache when possible.
  Future<Either<Failure, ProblemStatement>> fetchStatement(
    ProblemRef problem,
  );
}
