
import 'package:dartz/dartz.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/features/online_friends/data/models/online_friends_model.dart';

abstract class OnlineFriendsRepo {
  Future<Either<Failure,OnlineFriendsModel>> getOnlineFriends();
}