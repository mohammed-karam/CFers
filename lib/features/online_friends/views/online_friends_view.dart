import 'package:fawateery/features/online_friends/data/repo/online_friends_repo_impl.dart';
import 'package:fawateery/features/online_friends/manager/online_friends_cubit/online_friends_cubit.dart';
import 'package:fawateery/features/online_friends/widgets/online_friends_view_body.dart';
import 'package:fawateery/core/utils/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnlineFriendsView extends StatelessWidget {
  const OnlineFriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) =>
            OnlineFriendsCubit(OnlineFriendsRepoImpl(apiService: Api())),
        child: OnlineFriendsViewBody(),
      ),
    );
  }
}
