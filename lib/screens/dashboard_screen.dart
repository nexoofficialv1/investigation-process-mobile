import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../services/local_store_service.dart';
import '../widgets/home_grid_card.dart';
import 'case_detail_screen.dart';
import 'case_form_screen.dart';
import 'case_parser_screen.dart';
import 'forms_screen.dart';
import 'miscellaneous_screen.dart';
import 'ocr_scanner_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'ud_case_screen.dart';

class DashboardScreen extends StatefulWidget {
  final OfficerProfile profile;

  const DashboardScreen({
    super.key,
    required this.profile,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocalStoreService _store = LocalStoreService();

  late OfficerProfile _profile;
  List<CaseFile> _cases = <CaseFile>[];
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _load();
  }

  Future<void> _load() async {
    final List<CaseFile> cases = await _store.loadCases();
    if (!mounted) return;
    setState(() => _cases = cases);
  }

  CaseFile? get _latestCase => _cases.isEmpty ? null : _cases.first;

  Uint8List? _photoBytes() {
    if (_profile.photoBase64.trim().isEmpty) return null;
    try {
      return base64Decode(_profile.photoBase64);
    } catch (_) {
      return null;
    }
  }

  Future<void> _newCase() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CaseFormScreen(profile: _profile),
      ),
    );
    await _load();
  }

  Future<void> _openCase(CaseFile file) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            CaseDetailScreen(profile: _profile, caseFile: file),
      ),
    );
    await _load();
  }

  Future<void> _openLatestCase() async {
    final CaseFile? file = _latestCase;
    if (file == null) {
      await _newCase();
      return;
    }
    await _openCase(file);
  }

  void _needCaseMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'প্রথমে একটি মামলা তৈরি বা নির্বাচন করুন।',
        ),
      ),
    );
  }

  Future<void> _openForms() async {
    final CaseFile? file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            FormsScreen(profile: _profile, caseFile: file),
      ),
    );
  }

  Future<void> _openReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ReportScreen(profile: _profile, caseFile: _latestCase),
      ),
    );
  }

  Future<void> _openCaseParser() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CaseParserScreen(profile: _profile),
      ),
    );
    await _load();
  }

  Future<void> _openMiscellaneous() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MiscellaneousScreen(
          profile: _profile,
          latestCase: _latestCase,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openUdCase() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => UdCaseScreen(profile: _profile),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          profile: _profile,
          latestCase: _latestCase,
          onProfileUpdated: (OfficerProfile updated) async {
            await _store.saveOfficerProfile(updated);
            if (!mounted) return;
            setState(() => _profile = updated);
          },
        ),
      ),
    );
    await _load();
  }

  void _comingSoon(String module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$module মডিউলটি পরবর্তী সংস্করণে পূর্ণাঙ্গ হবে।',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              _topHeader(),
              const SizedBox(height: 18),
              _gridMenu(),
              const SizedBox(height: 18),
              _recentCasesBlock(),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newCase,
        icon: const Icon(Icons.add),
        label: const Text('নতুন মামলা'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (int index) {
          setState(() => _tabIndex = index);
          if (index == 1) _openLatestCase();
          if (index == 2) {
            _comingSoon('কাজ/অপেক্ষমাণ সিডি এন্ট্রি');
          }
          if (index == 3) _openSettings();
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'হোম',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_copy_rounded),
            label: 'মামলা',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_rounded),
            label: 'কাজ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _topHeader() {
    final Uint8List? photo = _photoBytes();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Color(0xFF003E34),
            Color(0xFF00745E),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 29,
            backgroundColor: Colors.white24,
            backgroundImage: photo == null ? null : MemoryImage(photo),
            child: photo == null
                ? const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 32,
                  )
                : null,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'ইনভেস্টিগো — তদন্ত সহায়ক',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_profile.rank} ${_profile.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE6C773),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _profile.policeStation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridMenu() {
    final List<_Menu> items = <_Menu>[
      _Menu(
        'কেস ডায়েরি',
        'মামলার ভিতরে কাজ করুন',
        Icons.menu_book_rounded,
        AppTheme.gold,
        _openLatestCase,
      ),
      _Menu(
        'নতুন মামলা',
        'মামলার তথ্য',
        Icons.add_box_rounded,
        AppTheme.teal,
        _newCase,
      ),
      _Menu(
        'মামলা তথ্য বিশ্লেষক',
        'নথি থেকে মামলা',
        Icons.document_scanner_rounded,
        const Color(0xFF0E7C86),
        _openCaseParser,
      ),
      _Menu(
        'ফর্ম ও নোটিশ',
        'নোটিশ/রিকুইজিশন',
        Icons.description_rounded,
        AppTheme.purple,
        _openForms,
      ),
      _Menu(
        'প্রতিবেদন',
        'SP/SDPO/SDO',
        Icons.summarize_rounded,
        const Color(0xFFD68A00),
        _openReport,
      ),
      _Menu(
        'OCR Scanner',
        'ছবি থেকে লেখা',
        Icons.text_snippet_rounded,
        const Color(0xFF536DFE),
        () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const OcrScannerScreen(),
          ),
        ),
      ),
      _Menu(
        'অস্বাভাবিক মৃত্যু মামলা',
        'সুরতহাল/চূড়ান্ত প্রতিবেদন',
        Icons.assignment_rounded,
        const Color(0xFF5D4037),
        _openUdCase,
      ),
      _Menu(
        'বিবিধ',
        'Duty/Inventory/Report',
        Icons.apps_rounded,
        const Color(0xFF37474F),
        _openMiscellaneous,
      ),
      _Menu(
        'Settings',
        'Profile/Backup/Backend/SOP',
        Icons.settings_rounded,
        const Color(0xFF455A64),
        _openSettings,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (_, int index) => HomeGridCard(
          title: items[index].title,
          subtitle: items[index].subtitle,
          icon: items[index].icon,
          color: items[index].color,
          onTap: items[index].onTap,
        ),
      ),
    );
  }

  Widget _recentCasesBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: <Widget>[
          const Text(
            'সাম্প্রতিক মামলা',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: AppTheme.deepGreen,
            ),
          ),
          const SizedBox(height: 12),
          if (_cases.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'কাজ শুরু করতে প্রথম মামলা যোগ করুন।',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            ..._cases.take(3).map(
                  (CaseFile file) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.deepGreen,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.folder_open),
                      ),
                      title: Text(
                        file.displayTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(
                        'ধারা: ${file.sections}\n'
                        'অভিযোগকারী: ${file.complainantName}',
                        maxLines: 2,
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openCase(file),
                    ),
                  ),
                ),
          const SizedBox(height: 10),
          const Text(
            '© Astra Technologies',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppTheme.deepGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _Menu {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _Menu(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
  );
}
