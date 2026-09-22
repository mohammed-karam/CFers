import 'package:dartz/dartz.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/features/user_rating/data/models/user_rating_model.dart';

abstract class UserRatingRepo {
  Future<Either<Failure, List<UserRatingModel>>> getUserRating(String handle);
}
