import 'package:flutter/material.dart';

class FormHelpers {
  static Widget textField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }


  static DateTime? _parseDate(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final iso = DateTime.tryParse(t);
    if (iso != null) return iso;
    final m = RegExp(r'^(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})').firstMatch(t);
    if (m == null) return null;
    final day = int.tryParse(m.group(1)!);
    final month = int.tryParse(m.group(2)!);
    var year = int.tryParse(m.group(3)!);
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;
    return DateTime(year, month, day);
  }

  static TimeOfDay? _parseTime(String text) {
    final m = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(text.trim());
    if (m == null) return null;
    final hour = int.tryParse(m.group(1)!);
    final minute = int.tryParse(m.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  static String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')} hrs';

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
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: _parseDate(controller.text) ?? now,
            firstDate: DateTime(2000),
            lastDate: DateTime(now.year + 10),
          );
          if (picked != null) controller.text = _formatDate(picked);
        },
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month),
        ),
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
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: _parseTime(controller.text) ?? TimeOfDay.now(),
          );
          if (picked != null) controller.text = _formatTime(picked);
        },
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.schedule),
        ),
      ),
    );
  }

  static Widget dateTimeField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          final now = DateTime.now();
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: _parseDate(controller.text) ?? now,
            firstDate: DateTime(2000),
            lastDate: DateTime(now.year + 10),
          );
          if (pickedDate == null) return;
          if (!context.mounted) return;
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: _parseTime(controller.text) ?? TimeOfDay.now(),
          );
          final timeText = pickedTime == null ? '' : ' ${_formatTime(pickedTime)}';
          controller.text = '${_formatDate(pickedDate)}$timeText'.trim();
        },
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.event),
        ),
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
      subtitle: Text(value ? 'Yes — details required' : 'No'),
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
