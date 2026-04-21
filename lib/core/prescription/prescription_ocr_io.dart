import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

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

    final tmpPath =
        '${Directory.systemTemp.path}\\ocr_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final tmpFile = File(tmpPath);
    await tmpFile.writeAsBytes(img.encodeJpg(enhanced, quality: 92));
    return tmpPath;
  } catch (_) {
    return sourcePath;
  }
}
