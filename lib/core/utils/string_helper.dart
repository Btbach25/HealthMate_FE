/// Helper class for string manipulation utilities
/// Reusable across the application
class StringHelper {
  /// Gets initials from a name (first letter of first word and last word)
  /// Returns uppercase initials, or 'U' if name is empty
  /// 
  /// Examples:
  /// - "Nguyễn Văn A" -> "NA"
  /// - "Trần Thị B" -> "TB"
  /// - "John" -> "JO"
  /// - "" -> "U"
  static String getInitials(String name) {
    if (name.isEmpty || name.trim().isEmpty) return 'U';
    final trimmedName = name.trim();
    final parts = trimmedName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      final first = parts[0][0];
      final last = parts[parts.length - 1][0];
      return '$first$last'.toUpperCase();
    }
    return trimmedName.substring(0, trimmedName.length > 2 ? 2 : trimmedName.length).toUpperCase();
  }

  /// Formats a DateTime to a relative time string (e.g., "2 giờ trước", "3 ngày trước")
  /// Returns "Chưa có hoạt động" if dateTime is null
  static String formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Chưa có hoạt động';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}

