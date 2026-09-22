import 'package:fawateery/features/online_friends/manager/online_friends_cubit/online_friends_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnlineFriendsViewBody extends StatefulWidget {
  const OnlineFriendsViewBody({super.key});

  @override
  State<OnlineFriendsViewBody> createState() => _OnlineFriendsViewBodyState();
}

class _OnlineFriendsViewBodyState extends State<OnlineFriendsViewBody> {
  @override
  void initState() {
    BlocProvider.of<OnlineFriendsCubit>(
      context,
      listen: false,
    ).getOnlineFriends();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnlineFriendsCubit, OnlineFriendsState>(
      builder: (context, state) {
        if (state is OnlineFriendsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is OnlineFriendsSuccess) {
          final onlineFriendsModel = state.onlineFriendsModel;
          return ListView.builder(
            itemCount: onlineFriendsModel.result.length,
            itemBuilder: (context, index) {
              final friend = onlineFriendsModel.result[index];
              return Text(friend);
            },
          );
        } else if (state is OnlineFriendsFailure) {
          return Center(child: Text(state.errorMessage));
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
