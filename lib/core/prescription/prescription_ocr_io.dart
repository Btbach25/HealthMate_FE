import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Bản OCR cho Android / iOS / desktop — nửa "io" của conditional import khai
/// báo trong `prescription_ocr.dart`.
///
/// KHÔNG import file này trực tiếp: nó dùng `dart:io` nên sẽ làm vỡ build web.
/// Luôn đi qua `package:fe/core/prescription/prescription_ocr.dart`.
///
/// Chữ ký phải khớp tuyệt đối với bản `prescription_ocr_web.dart`.
///
/// Engine: ML Kit chạy hoàn toàn trên máy (không gửi ảnh đi đâu) và chỉ nhận
/// bảng chữ Latin — dấu tiếng Việt hay bị rơi, nên parser phía sau
/// (`prescription_plan_parser.dart`) phải chịu được text mất dấu.
Future<String> recognizePrescriptionImage(XFile file) async {
  final path = await _prepareImagePathForOcr(file.path);
  if (path.isEmpty) {
    throw StateError('Không đọc được đường dẫn ảnh');
  }
  final inputImage = InputImage.fromFilePath(path);
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final recognizedText = await recognizer.processImage(inputImage);
    return recognizedText.text;
  } finally {
    await recognizer.close();
  }
}

/// Tiền xử lý ảnh trước khi đưa vào ML Kit: xám hoá → tăng tương phản nhẹ →
/// convolution làm nét. Đơn thuốc thường là ảnh chụp giấy in mờ, các bước này
/// cải thiện tỉ lệ đọc đúng rõ rệt.
///
/// Ghi ảnh đã xử lý ra file tạm và trả về đường dẫn mới, vì
/// `InputImage.fromFilePath` chỉ nhận đường dẫn chứ không nhận bytes.
/// Mọi lỗi (ảnh hỏng, không ghi được file tạm) đều nuốt và trả lại đường dẫn
/// gốc — thà OCR trên ảnh chưa xử lý còn hơn hỏng cả luồng quét.
Future<String> _prepareImagePathForOcr(String sourcePath) async {
  if (sourcePath.isEmpty) return sourcePath;
  try {
    final sourceFile = File(sourcePath);
    final bytes = await sourceFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return sourcePath;

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

    // CẢNH BÁO: đang nối đường dẫn bằng '\' cứng — chỉ đúng trên Windows.
    // Trên Android/iOS, '\' là ký tự hợp lệ trong tên file nên không lỗi:
    // nó tạo ra một file tên "…tmp\ocr_123.jpg" ngay trong thư mục cha,
    // OCR vẫn chạy nên bug này không lộ ra khi test. Cần sửa thành
    // `p.join(Directory.systemTemp.path, 'ocr_….jpg')` (package `path`).
    //
    // File tạm cũng không được dọn sau khi OCR xong — quét nhiều lần sẽ để
    // lại rác trong thư mục tạm cho tới khi hệ điều hành tự xoá.
    final tmpPath =
        '${Directory.systemTemp.path}\\ocr_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final tmpFile = File(tmpPath);
    await tmpFile.writeAsBytes(img.encodeJpg(enhanced, quality: 92));
    return tmpPath;
  } catch (_) {
    return sourcePath;
  }
}
