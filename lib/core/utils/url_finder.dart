import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Helper to generate a random 6-digit prefix
String _getRandom6Digits() {
  final random = Random();
  final number = 100000 + random.nextInt(900000); // Generates 100000 to 999999
  return number.toString();
}

/// Helper to generate SHA-512 hex string
String _sha512(String input) {
  final bytes = utf8.encode(input);
  final digest = sha512.convert(bytes);
  return digest.toString();
}

/// Dynamic Request Generator for Codeforces API
String generateCodeforcesUrl({
  required String methodName,
  required Map<String, String> params,
  required String apiKey,
  required String apiSecret,
}) {
  // 1. Copy params and add mandatory credential & unix timestamp
  final Map<String, String> allParams = Map.from(params);
  allParams['apiKey'] = apiKey;
  
  final unixTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  allParams['time'] = unixTime;

  // 2. Sort parameters lexicographically by key
  final sortedKeys = allParams.keys.toList()..sort();
  final queryString = sortedKeys.map((k) => '$k=${allParams[k]}').join('&');

  // 3. Generate random 6-character string prefix
  final randPrefix = _getRandom6Digits();

  // 4. Form string to hash: <rand>/<methodName>?<queryString>#<secret>
  final toHash = '$randPrefix/$methodName?$queryString#$apiSecret';

  // 5. Hash string and construct apiSig
  final hashHex = _sha512(toHash);
  final apiSig = '$randPrefix$hashHex';

  // 6. Assemble and return final URL
  return 'https://codeforces.com/api/$methodName?$queryString&apiSig=$apiSig';
}
/*

void main() {
  const key = '08e5cf98ed70882c4952c74d92f0804311ca6783';
  const secret = '7db729e816adde37801dc6cb7e2a89c5efff7877';

  final signedUrl = generateCodeforcesUrl(
    methodName: 'user.friends',
    params: {'onlyOnline': 'true'},
    apiKey: key,
    apiSecret: secret,
  );

  print('Generated URL:\n$signedUrl');
}

*/