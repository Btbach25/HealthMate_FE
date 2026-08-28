import 'package:fe/core/utils/string_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getInitials', () {
    test('lấy chữ cái đầu của từ đầu và từ cuối', () {
      expect(StringHelper.getInitials('Nguyễn Văn A'), 'NA');
      expect(StringHelper.getInitials('Trần Thị B'), 'TB');
    });

    test('tên một từ thì lấy 2 ký tự đầu', () {
      expect(StringHelper.getInitials('John'), 'JO');
    });

    test('tên một ký tự thì trả đúng ký tự đó', () {
      expect(StringHelper.getInitials('A'), 'A');
    });

    test('không bao giờ trả chuỗi rỗng', () {
      expect(StringHelper.getInitials(''), 'U');
      expect(StringHelper.getInitials('   '), 'U');
    });

    test('bỏ qua khoảng trắng thừa giữa các từ', () {
      expect(StringHelper.getInitials('  Lê   Minh   Châu  '), 'LC');
    });
  });

  group('formatTimeAgo', () {
    test('null nghĩa là chưa có hoạt động nào', () {
      expect(StringHelper.formatTimeAgo(null), 'Chưa có hoạt động');
    });

    test('mốc rất gần hiện tại là "Vừa xong"', () {
      expect(StringHelper.formatTimeAgo(DateTime.now()), 'Vừa xong');
    });

    test('mốc ở tương lai cũng trả "Vừa xong" thay vì số âm', () {
      final future = DateTime.now().add(const Duration(hours: 2));
      expect(StringHelper.formatTimeAgo(future), 'Vừa xong');
    });

    test('quy đổi sang phút / giờ / ngày', () {
      final now = DateTime.now();
      expect(
        StringHelper.formatTimeAgo(now.subtract(const Duration(minutes: 5))),
        '5 phút trước',
      );
      expect(
        StringHelper.formatTimeAgo(now.subtract(const Duration(hours: 3))),
        '3 giờ trước',
      );
      expect(
        StringHelper.formatTimeAgo(now.subtract(const Duration(days: 2))),
        '2 ngày trước',
      );
    });
  });
}
