import 'package:fawateery/core/utils/api_service.dart';
import 'package:fawateery/features/ai_tutor/data/repo/ai_tutor_repo_impl.dart';
import 'package:fawateery/features/ai_tutor/manager/cubit/ai_tutor_cubit.dart';
import 'package:fawateery/features/ai_tutor/widgets/ai_tutor_view_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiTutorView extends StatelessWidget {
  const AiTutorView({super.key, this.initialQuestion});

  /// Prefills the question box, e.g. with the statement of the problem the
  /// student is already working on.
  final String? initialQuestion;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AiTutorCubit(
        AiTutorRepoImpl(
          apiService: Api(),
        ),
      ),
      child: AiTutorViewBody(initialQuestion: initialQuestion),
    );
  }
}
