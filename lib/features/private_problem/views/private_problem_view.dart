import 'package:fawateery/core/utils/api_service.dart';
import 'package:fawateery/core/widgets/custom_app_bar.dart';
import 'package:fawateery/features/code_compiler/data/repo/code_compiler_repo_impl.dart';
import 'package:fawateery/features/code_compiler/manager/cubit/code_compiler_cubit.dart';
import 'package:fawateery/features/code_compiler/widgets/code_compiler_view_body.dart';
import 'package:fawateery/features/private_problem/widgets/private_problem_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The "not on Codeforces" route: a browser on top for a private problem or
/// any other judge, and the code compiler directly underneath it, so the
/// student reads and codes on one screen.
class PrivateProblemView extends StatelessWidget {
  const PrivateProblemView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CodeCompilerCubit(
        CodeCompilerRepoImpl(apiService: Api()),
      ),
      child: CodeCompilerViewBody(
        appBar: const CustomAppBar(
          title: 'Private problem',
          subtitle: 'Browse it, then code right below',
        ),
        // The browser claims its share against a weighted editor, so the
        // handle can move the split in fine steps instead of coarse halves.
        editorFlex: 100,
        header: const PrivateProblemBody(),
      ),
    );
  }
}
