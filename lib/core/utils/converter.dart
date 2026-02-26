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

/// Safely parses nested object from JSON, with fallback to flat structure
/// Returns null if neither nested nor flat data is available
T? cvToNestedObject<T>(
  Map<String, dynamic> json,
  String nestedKey,
  T Function(Map<String, dynamic>) nestedParser,
  T? Function(Map<String, dynamic>) flatParser,
) {
  // Try nested structure first
  final nested = json[nestedKey];
  if (nested is Map<String, dynamic>) {
    return nestedParser(nested);
  }

  // Fallback to flat structure
  return flatParser(json);
}