import 'package:fawateery/features/code_compiler/data/models/language_model.dart';
import 'package:fawateery/features/problems/data/models/problem_model.dart';
import 'package:fawateery/features/submit/manager/cubit/submit_cubit.dart';
import 'package:fawateery/features/submit/widgets/submit_view_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Hands the student's solution to Codeforces and waits for the verdict.
///
/// The screen opens Codeforces' own submit page in a web view and fills the
/// form in there, so nothing about the account is handled by the app: no
/// password is stored and no code is posted from anywhere but the page the
/// student can see.
class SubmitView extends StatelessWidget {
  const SubmitView({
    super.key,
    required this.problem,
    required this.code,
    required this.language,
  });

  final ProblemRef problem;

  /// The code exactly as it sits in the editor right now.
  final String code;

  /// The language it was written in, so the page is set to the same compiler.
  final LanguageModel language;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubmitCubit(problemCode: problem.id),
      child: SubmitViewBody(
        problem: problem,
        code: code,
        language: language,
      ),
    );
  }
}
