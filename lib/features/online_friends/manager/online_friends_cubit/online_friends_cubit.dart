import 'package:bloc/bloc.dart';
import 'package:fawateery/features/online_friends/data/models/online_friends_model.dart';
import 'package:fawateery/features/online_friends/data/repo/online_friends_repo.dart';
import 'package:meta/meta.dart';

part 'online_friends_state.dart';

class OnlineFriendsCubit extends Cubit<OnlineFriendsState> {
  OnlineFriendsCubit(this.onlineFriendsRepo) : super(OnlineFriendsInitial());
  final OnlineFriendsRepo onlineFriendsRepo ;


  Future<void> getOnlineFriends() async {
    emit(OnlineFriendsLoading());
    final result = await onlineFriendsRepo.getOnlineFriends();
    result.fold(
      (failure) => emit(OnlineFriendsFailure(errorMessage: failure.errorMessage)),
      (onlineFriendsModel) => emit(OnlineFriendsSuccess(onlineFriendsModel: onlineFriendsModel)),
    );
  }
}
