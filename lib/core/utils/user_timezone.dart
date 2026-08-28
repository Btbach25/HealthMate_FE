/// Đoán múi giờ IANA của thiết bị để gửi kèm lên backend.
///
/// Service Go phía sau cần tên IANA (`Asia/Ho_Chi_Minh`) để tính giờ nhắc uống
/// thuốc. Nhưng `DateTime.timeZoneName` của Dart trả về tên do HỆ ĐIỀU HÀNH
/// đặt, mỗi nền tảng một kiểu: Android/iOS thường ra `ICT` hoặc `+07`, web ra
/// tên dài của trình duyệt, một số máy ra thẳng `Asia/Ho_Chi_Minh`.
///
/// Hàm này quy các cách viết đó về IANA theo ba bước, ưu tiên giảm dần:
/// 1. Khớp các tên quen thuộc của giờ Việt Nam.
/// 2. Tên đã có dấu `/` thì coi như đã đúng IANA, dùng luôn.
/// 3. Không khớp thì suy từ offset — đúng +07:00 chẵn coi là giờ Việt Nam.
///
/// Vẫn không ra thì trả tên thô, cuối cùng là `'UTC'`: luôn có một giá trị để
/// gửi đi, còn hơn để trống làm hỏng request.
///
/// Đây là phỏng đoán có chủ đích, chỉ chính xác cho người dùng Việt Nam —
/// muốn đúng cho mọi múi giờ thì cần package đọc IANA thật (vd. `flutter_timezone`).
String resolveUserTimezone() {
  final now = DateTime.now();
  final name = now.timeZoneName.trim();

  const vnNames = {'ICT', 'Indochina Time', 'GMT+07:00', '+07', '+07:00'};
  if (vnNames.contains(name)) {
    return 'Asia/Ho_Chi_Minh';
  }

  if (name.isNotEmpty && name.contains('/')) {
    return name;
  }

  final offset = now.timeZoneOffset;
  if (offset.inHours == 7 && offset.inMinutes.remainder(60) == 0) {
    return 'Asia/Ho_Chi_Minh';
  }

  return name.isNotEmpty ? name : 'UTC';
}
