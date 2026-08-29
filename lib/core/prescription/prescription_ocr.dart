import 'package:fe/core/prescription/prescription_ocr_io.dart'
    if (dart.library.html) 'package:fe/core/prescription/prescription_ocr_web.dart'
    as impl;
import 'package:image_picker/image_picker.dart';

/// OCR đơn thuốc — điểm vào DUY NHẤT của tính năng quét đơn.
///
/// ## Vì sao file này chỉ có đúng một dòng gọi hàm?
///
/// Đây là pattern **conditional import** của Dart. Thư mục
/// `lib/core/prescription/` có ba file chia nhau một vai trò:
///
/// * `prescription_ocr.dart` — file bạn đang đọc: mặt tiền (facade) chung.
///   Mọi nơi trong app CHỈ được import file này.
/// * `prescription_ocr_io.dart` — bản cho Android / iOS / desktop, dùng
///   `google_mlkit_text_recognition` (ML Kit, nhận dạng ngay trên máy).
/// * `prescription_ocr_web.dart` — bản cho Flutter Web, gọi **Tesseract.js**
///   qua `dart:js_interop`.
///
/// Chọn bản nào là do dòng `if (dart.library.html)` ở đầu file: build web thì
/// lấy `_web`, còn lại lấy `_io`. Nhờ vậy `dart:io` không bao giờ lọt vào
/// bundle web và `dart:js_interop` không lọt vào build mobile — cả hai đều
/// làm vỡ biên dịch nếu sang nhầm nền tảng.
///
/// ## Cạm bẫy (contributor mới hay vấp ở đây)
///
/// * **Đừng import thẳng `_io` / `_web`.** Chỉ cần một chỗ làm vậy là build
///   nền tảng còn lại vỡ.
/// * Hai bản `_io` / `_web` phải luôn giữ **cùng chữ ký**
///   `Future<String> recognizePrescriptionImage(XFile)`. Sửa tham số một bên
///   mà quên bên kia thì chỉ lỗi khi build đúng nền tảng đó — chạy trên máy
///   dev thường không phát hiện ra.
/// * Bản web phụ thuộc thẻ `<script>` Tesseract.js (CDN) khai báo trong
///   `web/index.html` và **phải nạp trước Flutter**. Xoá thẻ đó thì OCR web
///   chết lặng lẽ lúc chạy (`Tesseract` undefined), không có lỗi biên dịch.
/// * Điều kiện đang dùng là `dart.library.html`. Nó chỉ đúng cho build web
///   bằng JS; nếu sau này bật `--wasm` thì phải đổi sang
///   `dart.library.js_interop`, vì `dart.library.html` sai ở wasm và trình
///   biên dịch sẽ chọn nhầm bản `_io` (kéo theo `dart:io`).
///
/// ## Hợp đồng
///
/// Nhận ảnh đơn thuốc, trả về **văn bản thô** — có thể là chuỗi rỗng khi
/// không đọc được gì (ảnh mờ, thiếu sáng), đây là kết quả hợp lệ chứ không
/// phải lỗi. Việc tách văn bản thành từng dòng thuốc do
/// `parsePrescriptionPlan()` trong `prescription_plan_parser.dart` đảm nhiệm.
///
/// Lưu ý sản phẩm: không nêu tên engine (ML Kit / Tesseract) trong thông báo
/// hiển thị cho người dùng.
Future<String> recognizePrescriptionImage(XFile file) =>
    impl.recognizePrescriptionImage(file);
