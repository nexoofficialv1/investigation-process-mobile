import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/guided_daily_entry.dart';

class GuidedDailyEntryStore {
  static const String _key = 'guided_daily_entries_v1';

  Future<List<GuidedDailyEntry>> _loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.trim().isEmpty) return <GuidedDailyEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <GuidedDailyEntry>[];
      return decoded
          .whereType<Map>()
          .map((item) => GuidedDailyEntry.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (_) {
      return <GuidedDailyEntry>[];
    }
  }

  Future<List<GuidedDailyEntry>> loadForCase(String caseId) async {
    final entries = (await _loadAll())
        .where((item) => item.caseId == caseId)
        .toList();
    entries.sort((a, b) {
      final dateCompare = b.actionDate.compareTo(a.actionDate);
      return dateCompare != 0
          ? dateCompare
          : b.updatedAt.compareTo(a.updatedAt);
    });
    return entries;
  }

  Future<List<GuidedDailyEntry>> loadForDate(
    String caseId,
    String actionDate,
  ) async {
    final entries = (await loadForCase(caseId))
        .where((item) => item.actionDate == actionDate)
        .toList();
    entries.sort((a, b) => a.source.index.compareTo(b.source.index));
    return entries;
  }

  Future<GuidedDailyEntry?> loadOne(
    String caseId,
    String actionDate,
    DailyEntrySource source,
  ) async {
    final entries = await loadForDate(caseId, actionDate);
    final matches = entries.where((item) => item.source == source).toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return matches.first;
  }

  Future<void> save(GuidedDailyEntry entry) async {
    final preferences = await SharedPreferences.getInstance();
    final all = await _loadAll();

    // One authoritative entry for each Case + Date + Source.
    all.removeWhere((item) =>
        item.caseId == entry.caseId &&
        item.actionDate == entry.actionDate &&
        item.source == entry.source &&
        item.id != entry.id);

    final index = all.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      all[index] = entry;
    } else {
      all.add(entry);
    }
    await preferences.setString(
      _key,
      jsonEncode(all.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> delete(String id) async {
    final preferences = await SharedPreferences.getInstance();
    final all = await _loadAll();
    all.removeWhere((item) => item.id == id);
    await preferences.setString(
      _key,
      jsonEncode(all.map((item) => item.toJson()).toList()),
    );
  }
}
