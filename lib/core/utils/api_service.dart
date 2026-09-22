import 'dart:convert';

import 'package:fawateery/core/errors/failures.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;


class Api {
  Future<dynamic> get({
    required String url,
    // @required String? token,
    required Map<String, dynamic> body,
  }) async {
    final Map<String, String> headers = {};

    // if (token != null) {
    //   headers.addAll({'Authorization': 'Bearer $token'});
    // }
    final http.Response response =
        await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(throw ServerFailure.fromResponse(response));
    }
  }

  Future<dynamic> postFormData({
    required String url,
    required Map<String, dynamic> fields,
    required String? token,
    Map<String, String> headers = const {},
  }) async {
    // Create multipart request
    final request = http.MultipartRequest('POST', Uri.parse(url));

    // Add headers
    request.headers.addAll(headers);

    // Add authorization token if exists
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add form fields
    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    try {
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ServerFailure.fromResponse(response);
      }
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  Future<dynamic> post({
    required String url,
    @required dynamic body,
    @required String? token,
    @required Map<String, String>? headers,
    bool isFormData = false, // Add this flag
  }) async {
    if (isFormData) {
      // Handle as multipart/form-data
      return postFormData(
        url: url,
        fields: Map<String, dynamic>.from(body),
        token: token,
        headers: headers ?? const {},
      );
    } else {
      // Handle as JSON (existing code)
      headers ??= {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      // headers.addAll({
      //   'Content-Type': 'application/json',
      //   'Accept': 'application/json',
      // });

      if (token != null) {
        headers.addAll({'Authorization': 'Bearer $token'});
      }

      print(jsonEncode(body));
      final http.Response response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ServerFailure.fromResponse(response);
      }
    }
  }

  Future<dynamic> put({
    required String url,
    @required dynamic body,
    @required dynamic headerss,
    @required String? token,
  }) async {
    final Map<String, String> headers = headerss ??
        {
          // multipart/form-data

          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
    if (token != null) {
      headers.addAll({'Authorization': 'Bearer $token'});
    }

    print('url = $url body = $body token = $token ');
    final http.Response response = await http.put(
      Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      print(data);
      return data;
    } else {
      throw ServerFailure(
        errorMessage:
            'there is a problem with status code ${response.statusCode} with body ${jsonDecode(response.body)}',
      );
    }
  }

  Future<dynamic> delete({
    required String url,
    @required String? token,
    @required Map<String, String>? headers,
    required dynamic body,
  }) async {
    final Map<String, String> requestHeaders =
        headers ?? {'Content-Type': 'application/json'};
    if (token != null) {
      requestHeaders.addAll({'Authorization': 'Bearer $token'});
    }

    final http.Response response = await http.delete(Uri.parse(url),
        headers: requestHeaders, body: jsonEncode(body));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ServerFailure.fromResponse(response);
    }
  }
  /// Sends a multipart/form-data PUT request.
  /// [fields]    — plain text fields (all values as strings).
  /// [fileField] — the form field name for the binary file (e.g. 'UserImage').
  /// [filePath]  — absolute path of the file to upload (optional).
  Future<dynamic> putFormData({
    required String url,
    required Map<String, String> fields,
    String? fileField,
    String? filePath,
    @required String? token,
  }) async {
    final request = http.MultipartRequest('PUT', Uri.parse(url));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);

    if (fileField != null && filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('putFormData status: ${response.statusCode}  body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ServerFailure.fromResponse(response);
    }
  }
}

