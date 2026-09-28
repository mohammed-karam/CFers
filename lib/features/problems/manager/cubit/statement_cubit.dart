import 'package:bloc/bloc.dart';
import 'package:fawateery/features/problems/data/models/problem_model.dart';
import 'package:fawateery/features/problems/data/models/statement_model.dart';
import 'package:fawateery/features/problems/data/repo/problems_repo.dart';

part 'statement_state.dart';

/// Loads one problem statement, from cache when it was read before.
class StatementCubit extends Cubit<StatementState> {
  StatementCubit(this._repo) : super(StatementLoading());

  final ProblemsRepo _repo;

  ProblemRef? problem;

  Future<void> load(ProblemRef target) async {
    problem = target;
    emit(StatementLoading());

    final result = await _repo.fetchStatement(target);
    result.fold(
      (failure) => emit(StatementFailure(errorMessage: failure.errorMessage)),
      (statement) => emit(StatementSuccess(statement: statement)),
    );
  }
}
