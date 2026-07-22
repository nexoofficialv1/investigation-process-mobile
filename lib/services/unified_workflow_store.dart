import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_narration_record.dart';

class UnifiedWorkflowStore {
  static const String _recordsKey = 'daily_narration_records_v1';

  Future<List<DailyNarrationRecord>> loadRecords(String caseId) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_recordsKey);
    if (raw == null || raw.isEmpty) return <DailyNarrationRecord>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return <DailyNarrationRecord>[];

    return decoded
        .map((item) => DailyNarrationRecord.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .where((item) => item.caseId == caseId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveRecord(DailyNarrationRecord record) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_recordsKey);

    final all = raw == null || raw.isEmpty
        ? <DailyNarrationRecord>[]
        : (jsonDecode(raw) as List)
            .map((item) => DailyNarrationRecord.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();

    final existingIndex = all.indexWhere((item) => item.id == record.id);
    if (existingIndex >= 0) {
      all[existingIndex] = record;
    } else {
      all.add(record);
    }

    await preferences.setString(
      _recordsKey,
      jsonEncode(all.map((item) => item.toJson()).toList()),
    );
  }
}
