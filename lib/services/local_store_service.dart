import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/officer_profile.dart';
import '../models/statement_entry.dart';
import '../models/form_notice.dart';
import '../models/pending_cd_action.dart';
import '../models/sketch_map.dart';
import '../models/backend_config.dart';
import '../models/ud_case.dart';
import '../models/investigation_action.dart';

class LocalStoreService {
  static const _profileKey = 'officer_profile_v1';
  static const _casesKey = 'cases_v1';
  static const _cdsKey = 'cd_entries_v1';
  static const _statementsKey = 'statement_entries_v1';
  static const _formsKey = 'form_notice_entries_v1';
  static const _pendingCdActionsKey = 'pending_cd_actions_v1';
  static const _sketchMapsKey = 'sketch_maps_v1';
  static const _backendConfigKey = 'backend_config_v1';
  static const _udCasesKey = 'ud_cases_v1';
  static const _investigationActionsKey = 'investigation_actions_v1';




  Future<List<InvestigationActionEntry>> loadInvestigationActions(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_investigationActionsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => InvestigationActionEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.caseId == caseId)
        .toList()
      ..sort((a, b) => b.actionDate.compareTo(a.actionDate));
  }

  Future<void> saveInvestigationAction(InvestigationActionEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_investigationActionsKey);
    final all = raw == null || raw.isEmpty
        ? <InvestigationActionEntry>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => InvestigationActionEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
    final index = all.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      all[index] = entry;
    } else {
      all.add(entry);
    }
    await prefs.setString(_investigationActionsKey, jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<List<UdCase>> loadUdCases() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_udCasesKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => UdCase.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveUdCase(UdCase udCase) async {
    final cases = await loadUdCases();
    final index = cases.indexWhere((c) => c.id == udCase.id);
    if (index >= 0) {
      cases[index] = udCase;
    } else {
      cases.add(udCase);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_udCasesKey, jsonEncode(cases.map((e) => e.toJson()).toList()));
  }

  Future<BackendConfig> loadBackendConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_backendConfigKey);
    if (raw == null || raw.isEmpty) return BackendConfig.empty();
    return BackendConfig.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
  }

  Future<void> saveBackendConfig(BackendConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendConfigKey, jsonEncode(config.toJson()));
  }

  Future<OfficerProfile> loadOfficerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return OfficerProfile.empty();
    return OfficerProfile.fromJson(jsonDecode(raw));
  }

  Future<void> saveOfficerProfile(OfficerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<List<CaseFile>> loadCases() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_casesKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CaseFile.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveCase(CaseFile file) async {
    final cases = await loadCases();
    final index = cases.indexWhere((c) => c.id == file.id);
    if (index >= 0) {
      cases[index] = file;
    } else {
      cases.add(file);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _casesKey,
      jsonEncode(cases.map((e) => e.toJson()).toList()),
    );
  }


  Future<List<CdEntry>> _loadAllCdsRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cdsKey);
    if (raw == null || raw.isEmpty) return <CdEntry>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <CdEntry>[];
    return decoded
        .whereType<Map>()
        .map((item) => CdEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _writeAllCds(List<CdEntry> cds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cdsKey,
      jsonEncode(cds.map((item) => item.toJson()).toList()),
    );
  }

  String _cdLineKey(CdTableLine line) {
    String normalize(String value) => value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final noHourParts = line.noAndHour.split('\n');
    final timeOnly = noHourParts.length > 1
        ? noHourParts.skip(1).join(' ')
        : line.noAndHour;
    return <String>[
      normalize(timeOnly),
      normalize(line.placeOfEntry),
      normalize(line.synopsis),
      normalize(line.proceedings),
    ].join('|');
  }

  CdEntry _mergeCdPair(CdEntry existing, CdEntry incoming) {
    final lines = <CdTableLine>[];
    final seen = <String>{};
    for (final line in <CdTableLine>[
      ...existing.tableLines,
      ...incoming.tableLines,
    ]) {
      final key = _cdLineKey(line);
      if (key.isEmpty || !seen.add(key)) continue;
      lines.add(line);
    }
    final body = lines
        .map((line) => line.proceedings.trim())
        .where((text) => text.isNotEmpty)
        .join('\n\n');
    return CdEntry(
      id: existing.id,
      caseId: existing.caseId,
      cdNumber: existing.cdNumber < incoming.cdNumber
          ? existing.cdNumber
          : incoming.cdNumber,
      cdDate: existing.cdDate,
      startTime: existing.startTime.trim().isEmpty
          ? incoming.startTime
          : existing.startTime,
      endTime: incoming.endTime.trim().isEmpty
          ? existing.endTime
          : incoming.endTime,
      placeOfEntry: incoming.placeOfEntry.trim().isEmpty
          ? existing.placeOfEntry
          : incoming.placeOfEntry,
      body: body,
      tableLines: lines,
      languageCode: incoming.languageCode,
      isFinal: existing.id == incoming.id
          ? incoming.isFinal
          : false,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<List<CdEntry>> _normalizeCaseCds(
    String caseId,
    List<CdEntry> all,
  ) async {
    final others = all.where((item) => item.caseId != caseId).toList();
    final caseItems = all.where((item) => item.caseId == caseId).toList()
      ..sort((a, b) {
        final date = a.cdDate.compareTo(b.cdDate);
        return date != 0 ? date : a.cdNumber.compareTo(b.cdNumber);
      });

    final byDate = <String, CdEntry>{};
    for (final cd in caseItems) {
      final dateKey = cd.cdDate.trim();
      final previous = byDate[dateKey];
      byDate[dateKey] = previous == null ? cd : _mergeCdPair(previous, cd);
    }

    final normalized = byDate.values.toList()
      ..sort((a, b) {
        final date = a.cdDate.compareTo(b.cdDate);
        return date != 0 ? date : a.createdAt.compareTo(b.createdAt);
      });

    final renumbered = <CdEntry>[
      for (var index = 0; index < normalized.length; index++)
        normalized[index].copyWith(cdNumber: index + 1),
    ];

    await _writeAllCds(<CdEntry>[...others, ...renumbered]);
    return renumbered;
  }

  Future<List<CdEntry>> loadCds(String caseId) async {
    final all = await _loadAllCdsRaw();
    return _normalizeCaseCds(caseId, all);
  }

  Future<void> saveCd(CdEntry cd) async {
    await saveCdForDate(cd);
  }

  Future<CdEntry?> loadCdForDate(
    String caseId,
    String cdDate,
  ) async {
    final cds = await loadCds(caseId);
    for (final cd in cds) {
      if (cd.cdDate == cdDate) return cd;
    }
    return null;
  }

  Future<CdEntry> saveCdForDate(CdEntry cd) async {
    final all = await _loadAllCdsRaw();
    final sameDate = all
        .where(
          (item) =>
              item.caseId == cd.caseId &&
              item.cdDate == cd.cdDate,
        )
        .toList();

    all.removeWhere(
      (item) =>
          item.caseId == cd.caseId &&
          item.cdDate == cd.cdDate,
    );

    // Saving the same CD ID is an edit: use the edited record as authoritative.
    // Only older duplicate records with different IDs are merged into it.
    CdEntry merged = cd;
    for (final previous in sameDate.where((item) => item.id != cd.id)) {
      merged = _mergeCdPair(previous, merged);
    }
    all.add(merged);

    final normalized = await _normalizeCaseCds(cd.caseId, all);
    return normalized.firstWhere((item) => item.cdDate == cd.cdDate);
  }



  Future<void> deleteCd(String cdId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cdsKey);
    if (raw == null || raw.isEmpty) return;
    final all = (jsonDecode(raw) as List<dynamic>)
        .map((e) => CdEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id != cdId)
        .toList();
    await prefs.setString(_cdsKey, jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<int> nextCdNumber(String caseId) async {
    final cds = await loadCds(caseId);
    return cds.length + 1;
  }

  Future<List<StatementEntry>> loadStatements(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statementsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => StatementEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.caseId == caseId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveStatement(StatementEntry statement) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statementsKey);
    final all = raw == null || raw.isEmpty
        ? <StatementEntry>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => StatementEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
    all.add(statement);
    await prefs.setString(
      _statementsKey,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }


  Future<List<FormNotice>> loadForms(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_formsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => FormNotice.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.caseId == caseId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveForm(FormNotice form) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_formsKey);
    final all = raw == null || raw.isEmpty
        ? <FormNotice>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => FormNotice.fromJson(Map<String, dynamic>.from(e)))
            .toList();
    final index = all.indexWhere((e) => e.id == form.id);
    if (index >= 0) {
      all[index] = form;
    } else {
      all.add(form);
    }
    await prefs.setString(
      _formsKey,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }


  Future<List<PendingCdAction>> loadPendingCdActions(String caseId, {bool includeConsumed = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingCdActionsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PendingCdAction.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.caseId == caseId && (includeConsumed || !e.consumed))
        .toList()
      ..sort((a, b) => a.actionDate.compareTo(b.actionDate));
  }

  Future<void> savePendingCdAction(PendingCdAction action) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingCdActionsKey);
    final all = raw == null || raw.isEmpty
        ? <PendingCdAction>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => PendingCdAction.fromJson(Map<String, dynamic>.from(e)))
            .toList();

    final duplicate = all.indexWhere((e) => e.caseId == action.caseId && e.sourceId == action.sourceId && e.title == action.title && !e.consumed);
    if (duplicate >= 0) {
      all[duplicate] = action;
    } else {
      all.add(action);
    }
    await prefs.setString(_pendingCdActionsKey, jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<void> markPendingCdActionsConsumed(List<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingCdActionsKey);
    if (raw == null || raw.isEmpty) return;
    final all = (jsonDecode(raw) as List<dynamic>)
        .map((e) => PendingCdAction.fromJson(Map<String, dynamic>.from(e)))
        .map((e) => ids.contains(e.id) ? e.copyWith(consumed: true) : e)
        .toList();
    await prefs.setString(_pendingCdActionsKey, jsonEncode(all.map((e) => e.toJson()).toList()));
  }



  Future<SketchMapEntry?> loadSketchMap(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sketchMapsKey);
    if (raw == null || raw.isEmpty) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    final maps = list
        .map((e) => SketchMapEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.caseId == caseId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return maps.isEmpty ? null : maps.first;
  }

  Future<void> saveSketchMap(SketchMapEntry map) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sketchMapsKey);
    final all = raw == null || raw.isEmpty
        ? <SketchMapEntry>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => SketchMapEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
    final index = all.indexWhere((e) => e.id == map.id);
    if (index >= 0) {
      all[index] = map;
    } else {
      all.add(map);
    }
    await prefs.setString(_sketchMapsKey, jsonEncode(all.map((e) => e.toJson()).toList()));
  }

}
