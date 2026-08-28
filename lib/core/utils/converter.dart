/// Bộ ép kiểu "không bao giờ ném lỗi" cho dữ liệu JSON từ backend.
///
/// Dùng trong `fromJson` của các model thay vì cast thẳng (`json['x'] as int`):
/// backend Go có thể trả số dưới dạng chuỗi, trả `null` cho trường mới thêm,
/// hoặc đổi kiểu giữa các phiên bản API — cast thẳng sẽ làm vỡ cả màn hình,
/// còn các hàm ở đây rơi về giá trị mặc định.
///
/// Quy ước tên:
/// * `cvToX(...)`        → luôn trả giá trị, dùng `defaultValue` khi hỏng.
/// * `cvToXOrNull(...)`  → trả `null` khi thiếu/hỏng (cho trường nullable).
/// * `cvToXRequired(...)`→ NÉM lỗi khi thiếu/hỏng (cho trường bắt buộc mà
///   thiếu nó thì bản ghi vô nghĩa, ví dụ mốc thời gian đo).
///
/// ```dart
/// Medication.fromJson(Map<String, dynamic> json) => Medication(
///       id: cvToString(json['id']),
///       dosage: cvToDoubleOrNull(json['dosage']),
///       createdAt: cvToDateRequired(json['created_at']),
///     );
/// ```
library;

import 'dart:convert';

String cvToString(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  return value.toString();
}

String? cvToStringOrNull(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  return str.isEmpty ? null : str;
}

int cvToInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

int? cvToIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double cvToDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

double? cvToDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool cvToBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  return defaultValue;
}

DateTime cvToDate(dynamic value, {DateTime? defaultValue}) {
  final defaultVal = defaultValue ?? DateTime.now();
  if (value == null) return defaultVal;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? defaultVal;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return defaultVal;
}

DateTime? cvToDateOrNull(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

DateTime cvToDateRequired(dynamic value) {
  if (value == null) {
    throw ArgumentError('Value cannot be null for cvToDateRequired');
  }
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ??
        (throw FormatException('Invalid date format: $value'));
  }
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  throw ArgumentError('Unsupported type for date conversion: ${value.runtimeType}');
}

List<T> cvToList<T>(dynamic value, T Function(dynamic) converter, {List<T> defaultValue = const []}) {
  if (value == null) return defaultValue;
  if (value is List) {
    try {
      return value.map((e) => converter(e)).toList();
    } catch (e) {
      return defaultValue;
    }
  }
  return defaultValue;
}

List<T>? cvToListOrNull<T>(dynamic value, T Function(dynamic) converter) {
  if (value == null) return null;
  if (value is List) {
    try {
      return value.map((e) => converter(e)).toList();
    } catch (e) {
      return null;
    }
  }
  return null;
}

Map<String, dynamic> cvStringToJson(String? value, {Map<String, dynamic> defaultValue = const {}}) {
  if (value == null || value.isEmpty) return defaultValue;
  try {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return defaultValue;
  } catch (e) {
    return defaultValue;
  }
}

Map<String, dynamic>? cvStringToJsonOrNull(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return null;
  } catch (e) {
    return null;
  }
}

String cvJsonToString(Map<String, dynamic>? json, {String defaultValue = '{}'}) {
  if (json == null) return defaultValue;
  try {
    return jsonEncode(json);
  } catch (e) {
    return defaultValue;
  }
}

String? cvJsonToStringOrNull(Map<String, dynamic>? json) {
  if (json == null) return null;
  try {
    return jsonEncode(json);
  } catch (e) {
    return null;
  }
}

/// Đọc một object con nằm dưới [nestedKey], tự lùi về đọc phẳng nếu không có.
///
/// Có để đỡ hai dạng response cùng tồn tại của backend: bản mới lồng object
/// (`{"user": {...}}`), bản cũ trải phẳng các trường ra ngoài. Trả `null` khi
/// cả hai cách đều không ra dữ liệu.
T? cvToNestedObject<T>(
  Map<String, dynamic> json,
  String nestedKey,
  T Function(Map<String, dynamic>) nestedParser,
  T? Function(Map<String, dynamic>) flatParser,
) {
  final nested = json[nestedKey];
  if (nested is Map<String, dynamic>) {
    return nestedParser(nested);
  }
  return flatParser(json);
}