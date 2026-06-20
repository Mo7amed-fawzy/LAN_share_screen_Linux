import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../constants/environment.dart';

class JwtToken {
  JwtToken._();

  static String create({
    required String roomName,
    required String participantIdentity,
  }) {
    final header = _base64url(jsonEncode({
      'alg': 'HS256',
      'typ': 'JWT',
    }));

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final payload = _base64url(jsonEncode({
      'iss': Environment.apiKey,
      'sub': participantIdentity,
      'exp': now + 3600,
      'nbf': now,
      'video': {
        'room': roomName,
        'roomJoin': true,
        'roomCreate': true,
        'canPublish': true,
        'canSubscribe': true,
      },
    }));

    final signature = _hmacSha256('$header.$payload', Environment.apiSecret);

    return '$header.$payload.$signature';
  }

  static String _base64url(String data) {
    final bytes = utf8.encode(data);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _hmacSha256(String data, String secret) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    return base64Url.encode(hmac.convert(utf8.encode(data)).bytes).replaceAll('=', '');
  }
}
