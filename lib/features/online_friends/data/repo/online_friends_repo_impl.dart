
import 'package:dartz/dartz.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/features/online_friends/data/models/online_friends_model.dart';
import 'package:fawateery/features/online_friends/data/repo/online_friends_repo.dart';
import 'package:fawateery/core/utils/api_service.dart';
import 'package:fawateery/core/utils/constants.dart';
import 'package:fawateery/core/utils/url_finder.dart';

class OnlineFriendsRepoImpl extends OnlineFriendsRepo{
  final Api apiService;
  OnlineFriendsRepoImpl({required this.apiService});
  @override
  Future<Either<Failure, OnlineFriendsModel>> getOnlineFriends() async{
    try{
      final url = generateCodeforcesUrl(
        methodName: 'user.friends',
        params: {'onlyOnline': 'true'},
        apiKey: userApiKey,
        apiSecret: userApiSecret,
      );
      final data = await apiService.get(url: url, body: {});
      return Right(OnlineFriendsModel.fromJson(data));
    } on ServerFailure catch (e) {
      return left(e);
    } on Exception catch (e) {
      return left(ServerFailure.fromException(e));
    }
  }
}