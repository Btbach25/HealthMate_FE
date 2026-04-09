import 'dart:convert';
import 'dart:js_interop';

import 'package:image_picker/image_picker.dart';

Future<String> recognizePrescriptionImage(XFile file) async {
  final bytes = await file.readAsBytes();
  final mime = file.mimeType ?? 'image/jpeg';
  final dataUrl =
      'data:$mime;base64,${base64Encode(bytes)}';
  return _tesseractRecognize(dataUrl);
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

Future<String> _tesseractRecognize(String dataUrl) async {
  final result = await tesseract.recognize(dataUrl.toJS, 'vie+eng'.toJS).toDart;
  final resp = _TesseractResponse(result);
  return resp.data.text;
}
