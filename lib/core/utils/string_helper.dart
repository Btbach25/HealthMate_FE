/// Các hàm xử lý chuỗi dùng chung cho phần hiển thị.
class StringHelper {
  /// Viết tắt tên để làm avatar chữ khi người dùng chưa có ảnh.
  ///
  /// Lấy chữ cái đầu của từ đầu và từ cuối; tên một từ thì lấy 2 ký tự đầu.
  /// Không bao giờ trả chuỗi rỗng — tên trống trả `'U'` (User) để avatar
  /// không bị hụt chữ.
  ///
  /// - `"Nguyễn Văn A"` → `"NA"`
  /// - `"Trần Thị B"` → `"TB"`
  /// - `"John"` → `"JO"`
  /// - `""` → `"U"`
  static String getInitials(String name) {
    if (name.isEmpty || name.trim().isEmpty) return 'U';
    final trimmedName = name.trim();
    final parts = trimmedName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      final first = parts[0][0];
      final last = parts[parts.length - 1][0];
      return '$first$last'.toUpperCase();
    }
    return trimmedName
        .substring(0, trimmedName.length > 2 ? 2 : trimmedName.length)
        .toUpperCase();
  }

  /// Mốc thời gian tương đối bằng tiếng Việt: "3 ngày trước", "2 giờ trước",
  /// "Vừa xong"; `null` → "Chưa có hoạt động".
  ///
  /// So sánh với giờ máy hiện tại, nên [dateTime] phải đã đổi về giờ địa
  /// phương — mốc UTC thô từ backend sẽ lệch đúng bằng offset múi giờ.
  /// Với thời điểm ở tương lai, hàm trả "Vừa xong".
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
