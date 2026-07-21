import 'package:flutter/material.dart';

import '../services/bengali_translation_service.dart';

class FormHelpers {
  static Widget textField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool? autoTranslate,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BanglaTextField(
        controller: controller,
        label: label,
        maxLines: maxLines,
        keyboardType: keyboardType,
        autoTranslate: autoTranslate ?? _shouldTranslate(label),
      ),
    );
  }

  static bool _shouldTranslate(String label) {
    final lower = label.toLowerCase();
    const excluded = <String>[
      'date', 'time', 'case no', 'section', 'mobile', 'phone', 'email', 'url',
      'token', 'id no', 'code', 'amount', 'age', 'sex', 'json', 'imei', 'upi',
      'transaction', 'receipt', 'year', 'latitude', 'longitude',
      'তারিখ', 'সময়', 'মামলা নং', 'ধারা', 'মোবাইল', 'ফোন', 'ইমেইল', 'ইউআরএল',
      'টোকেন', 'কোড', 'পরিমাণ', 'বয়স', 'লিঙ্গ', 'পিন', 'আইএমইআই', 'ইউপিআই',
      'লেনদেন', 'রসিদ', 'সাল', 'অক্ষাংশ', 'দ্রাঘিমাংশ', 'আলামত চিহ্ন',
    ];
    return !excluded.any(lower.contains);
  }


  static Widget dateField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month_outlined),
        ),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );

          if (picked != null) {
            final day = picked.day.toString().padLeft(2, '0');
            final month = picked.month.toString().padLeft(2, '0');
            controller.text = '$day-$month-${picked.year}';
          }
        },
      ),
    );
  }

  static Widget timeField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.access_time_outlined),
        ),
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );

          if (picked != null) {
            final hour = picked.hour.toString().padLeft(2, '0');
            final minute = picked.minute.toString().padLeft(2, '0');
            controller.text = '$hour:$minute';
          }
        },
      ),
    );
  }

  static Widget yesNoTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value ? 'হ্যাঁ — বিস্তারিত লেখা আবশ্যক' : 'না'),
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// বাংলা-প্রথম ইনপুট ফিল্ড। ইংরেজি লেখা থাকলে ফোকাস ছাড়ার সময় স্বয়ংক্রিয়ভাবে
/// অনুবাদ করার চেষ্টা করে; পাশের অনুবাদ বোতাম চাপলেও একই কাজ হয়।
class BanglaTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final bool autoTranslate;
  final InputDecoration? decoration;

  const BanglaTextField({
    super.key,
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.autoTranslate = true,
    this.decoration,
  });

  @override
  State<BanglaTextField> createState() => _BanglaTextFieldState();
}

class _BanglaTextFieldState extends State<BanglaTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _translating = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocus() {
    if (!_focusNode.hasFocus && widget.autoTranslate) {
      _translate();
    }
  }

  Future<void> _translate() async {
    if (_translating || !BengaliTranslationService.instance.containsEnglish(widget.controller.text)) return;
    setState(() => _translating = true);
    final before = widget.controller.text;
    final changed = await BengaliTranslationService.instance.translateController(widget.controller);
    if (!mounted) return;
    setState(() => _translating = false);
    if (!changed && before.isNotEmpty && BengaliTranslationService.instance.containsEnglish(before)) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('অনুবাদ করা যায়নি। ইন্টারনেট সংযোগ পরীক্ষা করুন।')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseDecoration = widget.decoration ?? InputDecoration(labelText: widget.label);
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      textInputAction: widget.maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
      onEditingComplete: () {
        _focusNode.unfocus();
        if (widget.autoTranslate) _translate();
      },
      onTapOutside: (_) {
        _focusNode.unfocus();
        if (widget.autoTranslate) _translate();
      },
      decoration: baseDecoration.copyWith(
        labelText: baseDecoration.labelText ?? widget.label,
        suffixIcon: widget.autoTranslate
            ? IconButton(
                tooltip: 'ইংরেজি লেখা বাংলায় অনুবাদ করুন',
                onPressed: _translating ? null : _translate,
                icon: _translating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.translate),
              )
            : baseDecoration.suffixIcon,
      ),
    );
  }
}
