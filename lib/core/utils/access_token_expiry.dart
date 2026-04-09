import 'dart:convert';

/// Trả về true nếu nên gọi refresh trước khi gọi API: không có token,
/// hoặc JWT có claim `exp` đã qua (kèm [clockSkew]).
/// Token không phải JWT 3 phần → false (để API + retry 401 xử lý).
bool shouldProactivelyRefreshAccessToken(
  String? accessToken, {
  Duration clockSkew = const Duration(seconds: 45),
}) {
  if (accessToken == null || accessToken.isEmpty) return true;
  final parts = accessToken.split('.');
  if (parts.length != 3) return false;
  try {
    final payload = parts[1];
    var padded = payload;
    switch (payload.length % 4) {
      case 1:
        return false;
      case 2:
        padded = '$payload==';
        break;
      case 3:
        padded = '$payload=';
        break;
      default:
        break;
    }
    final json = utf8.decode(base64Url.decode(padded));
    final map = jsonDecode(json) as Map<String, dynamic>;
    final exp = map['exp'];
    if (exp is! num) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch((exp * 1000).round(), isUtc: true);
    return DateTime.now().toUtc().isAfter(expiry.subtract(clockSkew));
  } catch (_) {
    return false;
  }
}
