import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/features/submit/data/cf_submission.dart';
import 'package:http/http.dart' as http;

/// Reads the student's own submissions back from Codeforces.
///
/// This is the only part of the feature that talks to Codeforces with a plain
/// HTTP client: the public API sits outside the website's browser check, so
/// verdicts arrive even on networks where the site itself would challenge a
/// script. Sending the code never goes through here — that happens on
/// Codeforces' own submit page, inside the app's web view.
class CfSubmissionsApi {
  CfSubmissionsApi({http.Client? client}) : _client = client ?? http.Client();

  /// Codeforces rejects default library user agents.
  static const String _userAgent =
      'fawateery/1.0 (+https://codeforces.com); submission tracker';

  final http.Client _client;

  /// The student's newest submission, or null when they have none yet.
  ///
  /// A failure to reach the API is returned as a [Failure] rather than
  /// thrown, so the watcher can retry quietly instead of showing an error
  /// for every poll.
  Future<Either<Failure, CfSubmission?>> latestFor(String handle) async {
    final trimmed = handle.trim();
    if (trimmed.isEmpty) {
      return Left(
        ServerFailure(errorMessage: 'Add your Codeforces handle to watch it.'),
      );
    }

    try {
      final response = await _client.get(
        Uri.https('codeforces.com', '/api/user.status', <String, String>{
          'handle': trimmed,
          'from': '1',
          'count': '1',
        }),
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode != 200) {
        return Left(ServerFailure.fromResponse(response));
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return Left(ServerFailure(errorMessage: 'Unexpected answer from Codeforces.'));
      }
      if (decoded['status'] != 'OK') {
        return Left(
          ServerFailure(
            errorMessage: (decoded['comment'] ?? 'Codeforces rejected the request.')
                .toString(),
          ),
        );
      }

      final result = decoded['result'];
      if (result is! List || result.isEmpty) return const Right(null);

      final newest = result.first;
      if (newest is! Map<String, dynamic>) return const Right(null);

      return Right(CfSubmission.fromApiJson(newest));
    } on Exception catch (error) {
      return Left(ServerFailure.fromException(error));
    }
  }
}
