/// So sánh ID người dùng (UUID) một cách an toàn.
///
/// Theo RFC 4122, UUID không phân biệt hoa/thường — nhưng `==` của Dart thì
/// có. Backend và cache cục bộ có thể trả cùng một ID với cách viết hoa khác
/// nhau, so thẳng bằng `==` sẽ ra `false` và app tưởng nhầm là hai người khác
/// nhau (mất quyền chủ nhóm, ẩn nhầm nút…). Luôn dùng [sameUserId] thay cho
/// `a == b` khi so ID người dùng.
library;

/// Đưa ID về dạng chuẩn để so sánh: bỏ khoảng trắng thừa và về chữ thường.
String canonicalUserId(String id) => id.trim().toLowerCase();

/// `true` nếu [a] và [b] là cùng một người dùng.
///
/// Chuỗi rỗng luôn trả `false` — ID trống nghĩa là "chưa biết", không được
/// coi hai cái "chưa biết" là cùng một người.
bool sameUserId(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  return canonicalUserId(a) == canonicalUserId(b);
}
