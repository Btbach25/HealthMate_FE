import 'package:image_picker/image_picker.dart';

import 'prescription_ocr_io.dart'
    if (dart.library.html) 'prescription_ocr_web.dart' as impl;

/// Nhận dạng chữ trên ảnh đơn thuốc (triển khai theo nền tảng — không hiển thị tên engine cho người dùng).
Future<String> recognizePrescriptionImage(XFile file) =>
    impl.recognizePrescriptionImage(file);
