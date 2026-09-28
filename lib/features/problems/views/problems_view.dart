import 'package:fawateery/core/theme/app_colors.dart';
import 'package:fawateery/core/widgets/custom_app_bar.dart';
import 'package:fawateery/features/problems/data/repo/problems_repo.dart';
import 'package:fawateery/features/problems/data/repo/problems_repo_impl.dart';
import 'package:fawateery/features/problems/manager/cubit/problems_list_cubit.dart';
import 'package:fawateery/features/problems/widgets/problems_list_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProblemsView extends StatelessWidget {
  const ProblemsView({super.key, this.repo});

  /// Injectable so tests can run against a fake repository.
  final ProblemsRepo? repo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProblemsListCubit(repo ?? ProblemsRepoImpl())
        ..load(),
      child: const Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'Problems',
          subtitle: 'Open one and solve it here',
        ),
        body: ProblemsListBody(),
      ),
    );
  }
}
