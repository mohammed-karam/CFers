part of 'online_friends_cubit.dart';

@immutable
sealed class OnlineFriendsState {}

final class OnlineFriendsInitial extends OnlineFriendsState {}

class OnlineFriendsLoading extends OnlineFriendsState {}

class OnlineFriendsSuccess extends OnlineFriendsState {
  OnlineFriendsSuccess({required this.onlineFriendsModel, this.friendInfo});

  final OnlineFriendsModel onlineFriendsModel;

  /// Public `user.info` details keyed by handle.
  ///
  /// `null` while the ratings are still being fetched, then a map that may be
  /// empty (lookup failed) or missing individual handles (unknown handle).
  final Map<String, FriendInfo>? friendInfo;
}

class OnlineFriendsFailure extends OnlineFriendsState {
  OnlineFriendsFailure({required this.errorMessage});

  final String errorMessage;
}
