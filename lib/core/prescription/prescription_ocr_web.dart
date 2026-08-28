import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Bản OCR cho Flutter Web — nửa "web" của conditional import khai báo trong
/// `prescription_ocr.dart`.
///
/// KHÔNG import file này trực tiếp: nó dùng `dart:js_interop` và biến toàn cục
/// JS `Tesseract` nên sẽ làm vỡ build mobile. Luôn đi qua
/// `package:fe/core/prescription/prescription_ocr.dart`.
///
/// Phụ thuộc runtime: thẻ `<script src=".../tesseract.min.js">` trong
/// `web/index.html`, phải nạp TRƯỚC Flutter. Thiếu nó thì hàm này ném lỗi JS
/// lúc chạy chứ không lỗi biên dịch.
///
/// Chạy tối đa 3 lượt nhận dạng, dừng ngay khi có text: ảnh đã xử lý với
/// `vie+eng` → ảnh gốc với `vie+eng` → ảnh gốc với `eng`. Lượt cuối là lối
/// thoát cho trường hợp CDN không phục vụ được model tiếng Việt (`vie`), khi
/// đó thà đọc mất dấu còn hơn trả về rỗng.
Future<String> recognizePrescriptionImage(XFile file) async {
  final originalBytes = await file.readAsBytes();
  final enhancedBytes = await _prepareImageBytesForOcr(file);
  final mime = file.mimeType ?? 'image/jpeg';

  final enhancedDataUrl = 'data:$mime;base64,${base64Encode(enhancedBytes)}';
  final originalDataUrl = 'data:$mime;base64,${base64Encode(originalBytes)}';

  // Lượt 1: ảnh đã tăng tương phản, model tiếng Việt + Anh
  final pass1 = await _tesseractRecognize(enhancedDataUrl, 'vie+eng');
  if (pass1.trim().isNotEmpty) return pass1;

  // Lượt 2: ảnh gốc (tiền xử lý đôi khi làm mất nét chữ mảnh)
  final pass2 = await _tesseractRecognize(originalDataUrl, 'vie+eng');
  if (pass2.trim().isNotEmpty) return pass2;

  // Lượt 3: chỉ tiếng Anh — lối thoát khi CDN không có model 'vie'
  final pass3 = await _tesseractRecognize(originalDataUrl, 'eng');
  if (pass3.trim().isNotEmpty) return pass3;

  debugPrint('[OCR_WEB] all passes returned empty text');
  return '';
}

/// Tiền xử lý ảnh giống bản `_io` (xám hoá → tương phản → làm nét) nhưng trả
/// về bytes, vì Tesseract.js nhận data URL chứ không nhận đường dẫn file.
/// Giữ hai bản đồng bộ về tham số để kết quả OCR hai nền tảng không lệch nhau.
Future<List<int>> _prepareImageBytesForOcr(XFile file) async {
  try {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    var enhanced = img.grayscale(decoded);
    enhanced = img.adjustColor(
      enhanced,
      contrast: 1.18,
      brightness: 0.02,
      gamma: 0.95,
    );
    enhanced = img.convolution(
      enhanced,
      filter: <num>[
        0,
        -1,
        0,
        -1,
        5,
        -1,
        0,
        -1,
        0,
      ],
    );
    return img.encodeJpg(enhanced, quality: 92);
  } catch (_) {
    return file.readAsBytes();
  }
}

/// Cầu nối tới biến toàn cục `window.Tesseract` do script CDN tạo ra.
/// `extension type` là cách khai báo js-interop của Dart 3: không sinh code,
/// chỉ mô tả hình dạng object JS — nếu script chưa nạp thì lỗi chỉ lộ ra lúc
/// gọi `recognize`.
extension type TesseractGlobal(JSObject _) implements JSObject {
  external JSPromise<JSObject> recognize(JSString image, JSString lang);
}

@JS('Tesseract')
external TesseractGlobal get tesseract;

extension type _TesseractResponse(JSObject _) implements JSObject {
  external _TesseractData get data;
}

extension type _TesseractData(JSObject _) implements JSObject {
  external String get text;
}

Future<String> _tesseractRecognize(String dataUrl, String lang) async {
  final result = await tesseract.recognize(dataUrl.toJS, lang.toJS).toDart;
  final resp = _TesseractResponse(result);
  debugPrint('[OCR_WEB] lang=$lang text_length=${resp.data.text.length}');
  return resp.data.text;
}
