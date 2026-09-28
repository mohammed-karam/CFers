import 'package:dartz/dartz.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/features/online_friends/data/models/friend_info.dart';
import 'package:fawateery/features/online_friends/data/models/online_friends_model.dart';

abstract class OnlineFriendsRepo {
  /// Signed `user.friends?onlyOnline=true` call: the handles that are online.
  Future<Either<Failure, OnlineFriendsModel>> getOnlineFriends();

  /// Public, keyless `user.info` lookup for [handles].
  ///
  /// The returned map is keyed by the handles exactly as they were requested,
  /// so any handle returned by [getOnlineFriends] can be looked up directly.
  /// Handles Codeforces does not know about are simply missing from the map.
  Future<Either<Failure, Map<String, FriendInfo>>> getFriendsInfo(
    List<String> handles,
  );
}
