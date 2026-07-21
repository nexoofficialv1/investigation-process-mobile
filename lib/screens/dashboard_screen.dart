import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../services/local_store_service.dart';
import '../widgets/home_grid_card.dart';
import 'case_detail_screen.dart';
import 'case_form_screen.dart';
import 'forms_screen.dart';
import 'statement_screen.dart';
import 'compliance_screen.dart';
import 'investigation_checklist_screen.dart';
import 'report_screen.dart';
import 'officer_profile_screen.dart';
import 'sketch_map_screen.dart';
import 'case_parser_screen.dart';
import 'evidence_screen.dart';
import 'backend_settings_screen.dart';
import 'ud_case_screen.dart';
import 'sop_compliance_screen.dart';
import 'investigation_screen.dart';
import 'backup_screen.dart';
import 'license_screen.dart';
import 'server_auth_license_screen.dart';
import 'miscellaneous_screen.dart';

class DashboardScreen extends StatefulWidget {
  final OfficerProfile profile;
  const DashboardScreen({super.key, required this.profile});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocalStoreService _store = LocalStoreService();
  late OfficerProfile _profile;
  List<CaseFile> _cases = [];
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _load();
  }

  Future<void> _load() async {
    final cases = await _store.loadCases();
    if (!mounted) return;
    setState(() => _cases = cases);
  }

  Future<void> _newCase() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CaseFormScreen(profile: _profile)));
    await _load();
  }

  Future<void> _editProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfficerProfileScreen(
          profile: _profile,
          onSaved: (updated) async {
            await _store.saveOfficerProfile(updated);
            if (!mounted) return;
            setState(() => _profile = updated);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _openCase(CaseFile file) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CaseDetailScreen(profile: _profile, caseFile: file)));
    await _load();
  }

  CaseFile? get _latestCase => _cases.isEmpty ? null : _cases.first;

  void _needCaseMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('প্রথমে একটি মামলা তৈরি করুন, তারপর এই মডিউল খুলবে।')),
    );
  }

  Future<void> _openLatestCase() async {
    final file = _latestCase;
    if (file == null) {
      await _newCase();
      return;
    }
    await _openCase(file);
  }

  Future<void> _openCdWriter() async {
    final file = _latestCase;
    if (file == null) {
      await _newCase();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CaseDetailScreen(profile: _profile, caseFile: file)));
    await _load();
  }

  Future<void> _openForms() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => FormsScreen(profile: _profile, caseFile: file)));
  }

  Future<void> _openStatements() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => StatementScreen(profile: _profile, caseFile: file)));
  }

  Future<void> _openCompliance() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ComplianceScreen(caseFile: file)));
  }

  Future<void> _openInvestigationChecklist() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => InvestigationChecklistScreen(caseFile: file)));
  }

  Future<void> _openReport() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(profile: _profile, caseFile: _latestCase)));
  }


  Future<void> _openCaseParser() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CaseParserScreen(profile: _profile)));
    await _load();
  }


  Future<void> _openSketchMap() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => SketchMapScreen(profile: _profile, caseFile: file)));
    await _load();
  }

  Future<void> _openInvestigation() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => InvestigationScreen(profile: _profile, caseFile: file)));
    await _load();
  }

  Future<void> _openEvidence() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => EvidenceScreen(profile: _profile, caseFile: file)));
    await _load();
  }

  Future<void> _openBackendSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => BackendSettingsScreen(profile: _profile)));
  }

  Future<void> _openBackup() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => BackupScreen(profile: _profile)));
  }

  Future<void> _openLicense() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ServerAuthLicenseScreen(profile: _profile)));
  }

  Future<void> _openMiscellaneous() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => MiscellaneousScreen(profile: _profile, latestCase: _latestCase)));
    await _load();
  }


  Future<void> _openUdCase() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => UdCaseScreen(profile: _profile)));
  }

  Future<void> _openSopCompliance() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => SopComplianceScreen(caseFile: file)));
  }

  void _comingSoon(String module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$module মডিউলটি পরবর্তী সংস্করণে পূর্ণাঙ্গ হবে। এখন মামলার বিস্তারিত অংশ থেকে কাজ করুন।')),
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
            children: [
              _topHeader(),
              const SizedBox(height: 18),
              _gridMenu(),
              const SizedBox(height: 18),
              _welcomeBlock(),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _newCase, icon: const Icon(Icons.add), label: const Text('নতুন মামলা')),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) {
          setState(() => _tabIndex = i);
          if (i == 1) _openLatestCase();
          if (i == 2) _comingSoon('কাজ/অপেক্ষমাণ সিডি এন্ট্রি');
          if (i == 3) _editProfile();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'হোম'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_copy_rounded), label: 'মামলা'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'কাজ'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'প্রোফাইল'),
        ],
      ),
    );
  }

  Widget _topHeader() {
    return Container(
      height: 104,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF003E34), Color(0xFF00745E)]),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('ইনভেস্টিগো — তদন্ত সহায়ক', style: TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 1.1, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Investigation Process Manager', style: TextStyle(color: Color(0xFFE6C773), fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${_profile.rank} ${_profile.name} • ${_profile.policeStation}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _gridMenu() {
    final items = [
      _Menu('তদন্ত', 'এসওপি নির্দেশিত', Icons.manage_search_rounded, const Color(0xFF00695C), _openInvestigation),
      _Menu('কেস ডায়েরি', 'সিডি লেখক', Icons.menu_book_rounded, AppTheme.gold, _openCdWriter),
      _Menu('নতুন মামলা', 'মামলার তথ্য', Icons.add_box_rounded, AppTheme.teal, _newCase),
      _Menu('মামলা তথ্য বিশ্লেষক', 'স্বয়ংক্রিয় তথ্য সংগ্রহ', Icons.document_scanner_rounded, const Color(0xFF0E7C86), _openCaseParser),
      _Menu('ফর্ম', 'নোটিশ/রিকুইজিশন', Icons.description_rounded, AppTheme.purple, _openForms),
      _Menu('বিবৃতি', 'বিএনএসএস ১৮০', Icons.assignment_ind_rounded, const Color(0xFF673AB7), _openStatements),
      _Menu('যাচাইতালিকা', 'তদন্তের প্রয়োজন', Icons.checklist_rounded, AppTheme.blue, _openInvestigationChecklist),
      _Menu('প্রতিবেদন', 'এসপি/এসডিপিও/এসডিও', Icons.summarize_rounded, const Color(0xFFD68A00), _openReport),
      _Menu('আইনগত অনুবর্তিতা', 'আইনগত যাচাইতালিকা', Icons.event_available_rounded, const Color(0xFF1B5E4B), _openCompliance),
      _Menu('এসওপি', 'ডিজিপি নির্দেশনা', Icons.policy_rounded, const Color(0xFF004D40), _openSopCompliance),
      _Menu('আইএফ-৫ / চার্জশিট', 'চূড়ান্ত সিডি থেকে', Icons.fact_check_rounded, AppTheme.coral, () => _comingSoon('আইএফ-৫ / চার্জশিট')),
      _Menu('প্রমাণ', 'প্রমাণ ব্যবস্থাপনা', Icons.inventory_2_rounded, const Color(0xFF795000), _openEvidence),
      _Menu('অস্বাভাবিক মৃত্যু মামলা', 'সুরতহাল/চূড়ান্ত প্রতিবেদন', Icons.assignment_rounded, const Color(0xFF5D4037), _openUdCase),
      _Menu('ব্যাকআপ', 'manual backup/sync', Icons.backup_rounded, const Color(0xFF455A64), _openBackup),
      _Menu('ব্যাকএন্ড', 'সার্ভার সেটআপ', Icons.dns_rounded, const Color(0xFF263238), _openBackendSettings),
      _Menu('লাইসেন্স', 'ফি/সক্রিয়করণ', Icons.workspace_premium_rounded, const Color(0xFF8D6E00), _openLicense),
      _Menu('বিবিধ', 'report/duty/inventory', Icons.apps_rounded, const Color(0xFF37474F), _openMiscellaneous),
      _Menu('পিডিএফ এক্সপোর্ট', 'আগে প্রিভিউ', Icons.picture_as_pdf_rounded, const Color(0xFF42A5F5), () => _comingSoon('পিডিএফ এক্সপোর্ট')),
      _Menu('চূড়ান্ত সিডি', 'তদন্তের সারাংশ', Icons.verified_rounded, const Color(0xFFC2188B), _openCdWriter),
      _Menu('খসড়া নকশা', 'নির্মাতা/সূচি', Icons.map_rounded, const Color(0xFF006B57), _openSketchMap),
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
          childAspectRatio: .78,
        ),
        itemBuilder: (_, i) => HomeGridCard(
          title: items[i].title,
          subtitle: items[i].subtitle,
          icon: items[i].icon,
          color: items[i].color,
          onTap: items[i].onTap,
        ),
      ),
    );
  }

  Widget _welcomeBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          const Text('Welcome to INVESTIGO', textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: AppTheme.deepGreen)),
          const SizedBox(height: 6),
          const Text('© Astra Technologies', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.deepGreen)),
          const SizedBox(height: 14),
          if (_cases.isEmpty)
            const Text('সিডি, বিবৃতি, ফর্ম ও আইএফ-৫ তৈরি করতে প্রথম মামলা যোগ করুন।', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600))
          else
            ..._cases.take(3).map((file) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppTheme.deepGreen, foregroundColor: Colors.white, child: Icon(Icons.folder_open)),
                    title: Text(file.displayTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text('ধারা: ${file.sections}\nঅভিযোগকারী: ${file.complainantName}', maxLines: 2),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openCase(file),
                  ),
                )),
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
  _Menu(this.title, this.subtitle, this.icon, this.color, this.onTap);
}
