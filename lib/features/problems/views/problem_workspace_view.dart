import 'package:fawateery/core/utils/api_service.dart';
import 'package:fawateery/features/code_compiler/data/repo/code_compiler_repo_impl.dart';
import 'package:fawateery/features/code_compiler/manager/cubit/code_compiler_cubit.dart';
import 'package:fawateery/features/problems/data/models/problem_model.dart';
import 'package:fawateery/features/problems/data/repo/problems_repo.dart';
import 'package:fawateery/features/problems/data/repo/problems_repo_impl.dart';
import 'package:fawateery/features/problems/manager/cubit/statement_cubit.dart';
import 'package:fawateery/features/problems/widgets/problem_workspace_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One screen for solving a problem: the statement sits directly above the
/// code editor, with the AI checker and "mark solved" in the app bar — no
/// switching between tabs or screens while working.
class ProblemWorkspaceView extends StatelessWidget {
  const ProblemWorkspaceView({
    super.key,
    required this.problem,
    this.repo,
  });

  final ProblemRef problem;

  /// Injectable so tests can run against a fake repository.
  final ProblemsRepo? repo;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => StatementCubit(repo ?? ProblemsRepoImpl())
            ..load(problem),
        ),
        BlocProvider(
          create: (context) => CodeCompilerCubit(
            CodeCompilerRepoImpl(apiService: Api()),
          ),
        ),
      ],
      child: ProblemWorkspaceBody(problem: problem),
    );
  }
}
