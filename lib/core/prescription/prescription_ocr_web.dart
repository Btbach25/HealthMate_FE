import 'dart:convert';
import 'dart:js_interop';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

Future<String> recognizePrescriptionImage(XFile file) async {
  final originalBytes = await file.readAsBytes();
  final enhancedBytes = await _prepareImageBytesForOcr(file);
  final mime = file.mimeType ?? 'image/jpeg';

  final enhancedDataUrl = 'data:$mime;base64,${base64Encode(enhancedBytes)}';
  final originalDataUrl = 'data:$mime;base64,${base64Encode(originalBytes)}';

  // Pass 1: enhanced image, Vietnamese+English
  final pass1 = await _tesseractRecognize(enhancedDataUrl, 'vie+eng');
  if (pass1.trim().isNotEmpty) return pass1;

  // Pass 2: original image, Vietnamese+English
  final pass2 = await _tesseractRecognize(originalDataUrl, 'vie+eng');
  if (pass2.trim().isNotEmpty) return pass2;

  // Pass 3: original image, English only (fallback when vie model unavailable on web)
  final pass3 = await _tesseractRecognize(originalDataUrl, 'eng');
  if (pass3.trim().isNotEmpty) return pass3;

  debugPrint('[OCR_WEB] all passes returned empty text');
  return '';
}

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
