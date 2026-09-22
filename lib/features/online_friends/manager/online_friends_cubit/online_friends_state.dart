part of 'online_friends_cubit.dart';

@immutable
sealed class OnlineFriendsState {}

final class OnlineFriendsInitial extends OnlineFriendsState {}

class OnlineFriendsLoading extends OnlineFriendsState {}
class OnlineFriendsSuccess extends OnlineFriendsState {
  final OnlineFriendsModel onlineFriendsModel;
  OnlineFriendsSuccess({required this.onlineFriendsModel});
}
class OnlineFriendsFailure extends OnlineFriendsState {
  final String errorMessage;
  OnlineFriendsFailure({required this.errorMessage});
}