import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/document_language.dart';

/// নির্বাচিত নথির ভাষায় ব্যবহারকারীর লেখা অনুবাদ করে।
/// নেটওয়ার্ক ব্যর্থ হলে মূল লেখা অপরিবর্তিত রাখা হয়।
class DocumentTranslationService {
  static final DocumentTranslationService instance =
      DocumentTranslationService._();

  DocumentTranslationService._();

  final Map<String, String> _cache = <String, String>{};

  bool containsEnglish(String value) => RegExp(r'[A-Za-z]').hasMatch(value);
  bool containsBangla(String value) => RegExp(r'[\u0980-\u09FF]').hasMatch(value);

  Future<String> translate(
    String source, {
    required DocumentLanguage target,
  }) async {
    final text = source.trim();
    if (text.isEmpty) return source;
    if (target.isBangla && !containsEnglish(text)) return source;
    if (target.isEnglish && !containsBangla(text)) return source;

    final key = '${target.code}::$text';
    final cached = _cache[key];
    if (cached != null) return _preserveOuterWhitespace(source, cached);

    try {
      final uri = Uri.https('translate.googleapis.com', '/translate_a/single');
      final response = await http.post(
        uri,
        body: <String, String>{
          'client': 'gtx',
          'sl': 'auto',
          'tl': target.code,
          'dt': 't',
          'q': text,
        },
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) return source;

      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty || decoded.first is! List) {
        return source;
      }
      final parts = <String>[];
      for (final item in decoded.first as List<dynamic>) {
        if (item is List && item.isNotEmpty && item.first != null) {
          parts.add(item.first.toString());
        }
      }
      final translated = parts.join().trim();
      if (translated.isEmpty) return source;
      _cache[key] = translated;
      return _preserveOuterWhitespace(source, translated);
    } catch (_) {
      return source;
    }
  }

  Future<bool> translateController(
    TextEditingController controller, {
    required DocumentLanguage target,
  }) async {
    final oldText = controller.text;
    final translated = await translate(oldText, target: target);
    if (translated == oldText) return false;
    controller.value = controller.value.copyWith(
      text: translated,
      selection: TextSelection.collapsed(offset: translated.length),
      composing: TextRange.empty,
    );
    return true;
  }

  Future<int> translateControllers(
    Iterable<TextEditingController> controllers, {
    required DocumentLanguage target,
  }) async {
    var changedCount = 0;
    for (final controller in controllers) {
      if (await translateController(controller, target: target)) {
        changedCount++;
      }
    }
    return changedCount;
  }

  String _preserveOuterWhitespace(String original, String translated) {
    final leading = RegExp(r'^\s*').firstMatch(original)?.group(0) ?? '';
    final trailing = RegExp(r'\s*$').firstMatch(original)?.group(0) ?? '';
    return '$leading$translated$trailing';
  }
}
