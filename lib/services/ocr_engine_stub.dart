class InvestigoOcrEngine {
  bool get isSupported => false;

  String get unsupportedMessage =>
      'এই platform-এ local OCR engine চালু নেই। Android/iOS app ব্যবহার করুন।';

  Future<String> recognize(String imagePath) {
    throw UnsupportedError(unsupportedMessage);
  }
}
