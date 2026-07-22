import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class InvestigoOcrEngine {
  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  String get unsupportedMessage =>
      'Local OCR বর্তমানে Android এবং iOS-এ চালু আছে।';

  Future<String> recognize(String imagePath) async {
    if (!isSupported) {
      throw UnsupportedError(unsupportedMessage);
    }

    final TextRecognizer recognizer =
        TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final InputImage inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText result =
          await recognizer.processImage(inputImage);
      return result.text.trim();
    } finally {
      await recognizer.close();
    }
  }
}
