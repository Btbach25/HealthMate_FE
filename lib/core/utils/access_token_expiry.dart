import 'dart:convert';

/// `true` nếu nên gọi refresh token TRƯỚC khi gọi API.
///
/// Dùng để tránh cú 401 đầu tiên rồi mới thử lại (`AuthHttpHelper` vẫn giữ
/// đường lùi đó): đoán trước token sắp hết hạn thì đổi token luôn, người dùng
/// không phải chờ hai vòng mạng.
///
/// Trả `true` khi: không có token, hoặc claim `exp` trong JWT đã qua — tính
/// sớm hơn [clockSkew] để trừ hao lệch đồng hồ giữa máy và server.
///
/// Cố ý trả `false` (tức "cứ gọi API đi") cho MỌI trường hợp không đọc được:
/// token không phải JWT ba phần, payload hỏng, thiếu `exp`. Hàm này chỉ tối
/// ưu tốc độ, không phải cổng kiểm tra bảo mật — quyền quyết định token hợp lệ
/// hay không thuộc về server, nên khi nghi ngờ thì để API trả 401 và đi theo
/// luồng retry sẵn có.
///
/// Hàm KHÔNG xác thực chữ ký JWT, chỉ đọc phần payload.
bool shouldProactivelyRefreshAccessToken(
  String? accessToken, {
  Duration clockSkew = const Duration(seconds: 45),
}) {
  if (accessToken == null || accessToken.isEmpty) return true;
  final parts = accessToken.split('.');
  if (parts.length != 3) return false;
  try {
    final payload = parts[1];
    // JWT dùng base64url KHÔNG có dấu '=' đệm, nhưng base64Url.decode của Dart
    // đòi độ dài chia hết cho 4 — phải tự đệm lại.
    var padded = payload;
    switch (payload.length % 4) {
      // Dư 1 ký tự là chuỗi base64 không hợp lệ (không đệm được), bỏ qua.
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
