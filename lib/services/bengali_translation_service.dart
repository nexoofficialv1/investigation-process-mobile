import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// ইংরেজি লেখা বাংলায় রূপান্তরের কেন্দ্রীয় সেবা।
///
/// সাধারণ/সরকারি স্থির বাক্যগুলো অ্যাপের টেমপ্লেটেই বাংলায় রাখা হয়েছে। ব্যবহারকারী
/// কোনো বিবরণ ইংরেজিতে লিখলে এই সেবা অনলাইনে বাংলা অনুবাদ করে। নেটওয়ার্ক না থাকলে
/// মূল লেখা নষ্ট না করে অপরিবর্তিত রাখে।
class BengaliTranslationService {
  static final BengaliTranslationService instance = BengaliTranslationService._();

  BengaliTranslationService._();

  final Map<String, String> _cache = <String, String>{};

  bool containsEnglish(String value) => RegExp(r'[A-Za-z]').hasMatch(value);

  bool containsBangla(String value) => RegExp(r'[\u0980-\u09FF]').hasMatch(value);

  Future<String> translateToBangla(String source) async {
    final text = source.trim();
    if (text.isEmpty || !containsEnglish(text)) return source;
    final cached = _cache[text];
    if (cached != null) return _preserveOuterWhitespace(source, cached);

    try {
      final uri = Uri.https(
        'translate.googleapis.com',
        '/translate_a/single',
        <String, String>{
          'client': 'gtx',
          'sl': 'auto',
          'tl': 'bn',
          'dt': 't',
          'q': text,
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) return source;

      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty || decoded.first is! List) return source;
      final parts = <String>[];
      for (final item in decoded.first as List<dynamic>) {
        if (item is List && item.isNotEmpty && item.first != null) {
          parts.add(item.first.toString());
        }
      }
      final translated = parts.join().trim();
      if (translated.isEmpty) return source;
      _cache[text] = translated;
      return _preserveOuterWhitespace(source, translated);
    } catch (_) {
      return source;
    }
  }

  Future<bool> translateController(TextEditingController controller) async {
    final oldText = controller.text;
    final translated = await translateToBangla(oldText);
    if (translated == oldText) return false;
    controller.value = controller.value.copyWith(
      text: translated,
      selection: TextSelection.collapsed(offset: translated.length),
      composing: TextRange.empty,
    );
    return true;
  }

  Future<int> translateControllers(Iterable<TextEditingController> controllers) async {
    var changedCount = 0;
    for (final controller in controllers) {
      if (await translateController(controller)) changedCount++;
    }
    return changedCount;
  }

  String _preserveOuterWhitespace(String original, String translated) {
    final leading = RegExp(r'^\s*').firstMatch(original)?.group(0) ?? '';
    final trailing = RegExp(r'\s*$').firstMatch(original)?.group(0) ?? '';
    return '$leading$translated$trailing';
  }
}
