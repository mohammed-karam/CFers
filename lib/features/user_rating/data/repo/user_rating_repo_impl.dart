import 'package:dartz/dartz.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/core/utils/api_service.dart';
import 'package:fawateery/features/user_rating/data/models/user_rating_model.dart';
import 'package:fawateery/features/user_rating/data/repo/user_rating_repo.dart';

class UserRatingRepoImpl extends UserRatingRepo {
  final Api apiService;

  UserRatingRepoImpl({required this.apiService});

  @override
  Future<Either<Failure, List<UserRatingModel>>> getUserRating(
    String handle,
  ) async {
    try {
      final data = await apiService.get(
        url: 'https://codeforces.com/api/user.rating?handle=$handle',
        body: {},
      );
      final List<dynamic> resultList = data['result'] as List<dynamic>;
      final ratings = resultList
          .map((item) => UserRatingModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return Right(ratings);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Exception catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }
}
