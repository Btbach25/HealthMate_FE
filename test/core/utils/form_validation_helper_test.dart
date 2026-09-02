import 'package:fe/core/utils/form_validation_helper.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mẫu để viết test cho các helper thuần trong `lib/core/utils/`.
///
/// Chúng không phụ thuộc Flutter binding hay network nên test chạy rất nhanh —
/// đây là chỗ nên bắt đầu khi muốn tăng độ phủ test cho repo.
void main() {
  group('validateEmail', () {
    test('trả null khi email hợp lệ', () {
      expect(FormValidationHelper.validateEmail('a@b.co'), isNull);
      expect(
        FormValidationHelper.validateEmail('nguyen.van.a@gmail.com'),
        isNull,
      );
    });

    test('bỏ khoảng trắng thừa trước khi kiểm tra', () {
      expect(FormValidationHelper.validateEmail('  a@b.co  '), isNull);
    });

    test('báo lỗi khi bỏ trống', () {
      expect(FormValidationHelper.validateEmail(null), 'Vui lòng nhập email');
      expect(FormValidationHelper.validateEmail('   '), 'Vui lòng nhập email');
    });

    test('báo lỗi khi sai định dạng', () {
      expect(FormValidationHelper.validateEmail('abc'), 'Email không hợp lệ');
      expect(FormValidationHelper.validateEmail('a@b'), 'Email không hợp lệ');
      expect(
        FormValidationHelper.validateEmail('a b@c.co'),
        'Email không hợp lệ',
      );
    });
  });

  group('validateRequired', () {
    test('chuỗi chỉ toàn khoảng trắng bị coi là bỏ trống', () {
      expect(
        FormValidationHelper.validateRequired('   ', fieldName: 'họ tên'),
        'Vui lòng nhập họ tên',
      );
    });

    test('trả null khi có nội dung', () {
      expect(FormValidationHelper.validateRequired('An'), isNull);
    });
  });

  group('validateMinLength', () {
    test('đếm độ dài sau khi trim', () {
      expect(
        FormValidationHelper.validateMinLength(
          '  ab  ',
          3,
          fieldName: 'Mật khẩu',
        ),
        'Mật khẩu phải có ít nhất 3 ký tự',
      );
      expect(FormValidationHelper.validateMinLength('abc', 3), isNull);
    });
  });

  group('validateMaxLength', () {
    test('KHÔNG bắt buộc nhập — bỏ trống vẫn hợp lệ', () {
      expect(FormValidationHelper.validateMaxLength(null, 5), isNull);
      expect(FormValidationHelper.validateMaxLength('', 5), isNull);
    });

    test('báo lỗi khi vượt quá giới hạn', () {
      expect(
        FormValidationHelper.validateMaxLength(
          'abcdef',
          5,
          fieldName: 'Ghi chú',
        ),
        'Ghi chú không được vượt quá 5 ký tự',
      );
    });
  });

  group('validateDateNotFuture', () {
    test('trả null với null và với ngày trong quá khứ', () {
      expect(FormValidationHelper.validateDateNotFuture(null), isNull);
      expect(
        FormValidationHelper.validateDateNotFuture(DateTime(1995, 6, 15)),
        isNull,
      );
    });

    test('báo lỗi với ngày ở tương lai', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(
        FormValidationHelper.validateDateNotFuture(
          tomorrow,
          fieldName: 'Ngày sinh',
        ),
        'Ngày sinh không thể lớn hơn ngày hiện tại',
      );
    });
  });

  group('validatePhoneNumber', () {
    test('chấp nhận số Việt Nam có khoảng trắng hoặc gạch nối', () {
      expect(FormValidationHelper.validatePhoneNumber('0901234567'), isNull);
      expect(FormValidationHelper.validatePhoneNumber('090 123 4567'), isNull);
      expect(FormValidationHelper.validatePhoneNumber('090-123-4567'), isNull);
      expect(FormValidationHelper.validatePhoneNumber('+84901234567'), isNull);
    });

    test('báo lỗi khi bỏ trống', () {
      expect(
        FormValidationHelper.validatePhoneNumber(''),
        'Vui lòng nhập số điện thoại',
      );
    });

    test('báo lỗi khi sai đầu số hoặc sai độ dài', () {
      expect(
        FormValidationHelper.validatePhoneNumber('1234567890'),
        'Số điện thoại không hợp lệ',
      );
      expect(
        FormValidationHelper.validatePhoneNumber('0123'),
        'Số điện thoại không hợp lệ',
      );
    });
  });
}
