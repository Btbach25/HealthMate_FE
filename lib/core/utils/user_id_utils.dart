/// UUID so sánh theo RFC không phân biệt hoa/thường; [String==] trong Dart thì có.
String canonicalUserId(String id) => id.trim().toLowerCase();

bool sameUserId(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  return canonicalUserId(a) == canonicalUserId(b);
}
