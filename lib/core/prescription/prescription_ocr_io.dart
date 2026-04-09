import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

Future<String> recognizePrescriptionImage(XFile file) async {
  final path = file.path;
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
