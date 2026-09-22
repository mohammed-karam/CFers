import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

abstract class Failure {
  final String errorMessage;

  Failure({required this.errorMessage});
}

class ServerFailure extends Failure {
  ServerFailure({required super.errorMessage});

  factory ServerFailure.fromException(Exception exception) {
    if (exception is SocketException) {
      return ServerFailure(
        errorMessage: "No internet connection",
      );
    } else if (exception is TimeoutException) {
      return ServerFailure(errorMessage: "Connection timed out");
    } else if (exception is FormatException) {
      return ServerFailure(errorMessage: "Bad response format from server");
    } else if (exception is HttpException) {
      return ServerFailure(errorMessage: "Couldn't connect to the server");
    } else {
      return ServerFailure(errorMessage: "Unexpected error, please try again");
    }
  }

  factory ServerFailure.fromResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode == 400 ||
        statusCode == 401 ||
        statusCode == 403 ||
        statusCode == 422) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        return ServerFailure(
          errorMessage: decoded['errors'] != null
              ? decoded['errors'][0]?.toString() ?? 'Unknown error'
              : decoded['message']?.toString() ??
                  decoded['Message']?.toString() ??
                  decoded['detail']?.toString() ??
                  'Request failed with status $statusCode',
        );
      } catch (_) {
        return ServerFailure(
          errorMessage: 'Request failed with status $statusCode',
        );
      }
    } else if (statusCode == 404) {
      return ServerFailure(
        errorMessage: 'Your request was not found, please try later!',
      );
    } else if (statusCode == 500) {
      return ServerFailure(
        errorMessage: 'Internal server error, please try later!',
      );
    } else {
      try {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        return ServerFailure(
          errorMessage: decoded['errors'] != null
              ? decoded['errors'][0]?.toString() ?? 'Unknown error'
              : decoded['message']?.toString() ??
                  decoded['detail']?.toString() ??
                  'Request failed with status $statusCode',
        );
      } catch (_) {
        return ServerFailure(
          errorMessage: 'Request failed with status $statusCode',
        );
      }

    }
  }
}
