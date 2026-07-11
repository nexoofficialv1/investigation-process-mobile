import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../services/local_store_service.dart';
import '../widgets/home_grid_card.dart';
import 'case_detail_screen.dart';
import 'case_form_screen.dart';
import 'officer_profile_screen.dart';

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

  void _openLatestOrNew() {
    if (_cases.isEmpty) {
      _newCase();
    } else {
      _openCase(_cases.first);
    }
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
      floatingActionButton: FloatingActionButton.extended(onPressed: _newCase, icon: const Icon(Icons.add), label: const Text('New Case')),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) {
          setState(() => _tabIndex = i);
          if (i == 1) _openLatestOrNew();
          if (i == 3) _editProfile();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_copy_rounded), label: 'CASES'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'TASKS'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'PROFILE'),
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
          const Text('Investigation & Process', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('${_profile.rank} ${_profile.name} • ${_profile.policeStation}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _gridMenu() {
    final items = [
      _Menu('Case Diary', Icons.menu_book_rounded, AppTheme.gold, _openLatestOrNew),
      _Menu('New Case', Icons.add_box_rounded, AppTheme.teal, _newCase),
      _Menu('Forms', Icons.description_rounded, AppTheme.purple, _openLatestOrNew),
      _Menu('Statement', Icons.assignment_ind_rounded, const Color(0xFF673AB7), _openLatestOrNew),
      _Menu('Compliance', Icons.event_available_rounded, AppTheme.blue, _openLatestOrNew),
      _Menu('IF5 / CS', Icons.fact_check_rounded, AppTheme.coral, _openLatestOrNew),
      _Menu('Evidence', Icons.inventory_2_rounded, const Color(0xFF795000), _openLatestOrNew),
      _Menu('PDF Export', Icons.picture_as_pdf_rounded, const Color(0xFF42A5F5), _openLatestOrNew),
      _Menu('Final CD', Icons.verified_rounded, const Color(0xFFC2188B), _openLatestOrNew),
      _Menu('Sketch Map', Icons.map_rounded, const Color(0xFF1B5E4B), _openLatestOrNew),
      _Menu('Backup', Icons.backup_rounded, const Color(0xFFF4A62A), _openLatestOrNew),
      _Menu('Reports', Icons.warning_rounded, const Color(0xFFD68A00), _openLatestOrNew),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 18,
          crossAxisSpacing: 14,
          childAspectRatio: .86,
        ),
        itemBuilder: (_, i) => HomeGridCard(title: items[i].title, icon: items[i].icon, color: items[i].color, onTap: items[i].onTap),
      ),
    );
  }

  Widget _welcomeBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          const Text('Welcome to Investigation Desk', textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: AppTheme.deepGreen)),
          const SizedBox(height: 14),
          if (_cases.isEmpty)
            const Text('Create your first case to generate CD, statement, forms and IF5.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600))
          else
            ..._cases.take(3).map((file) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppTheme.deepGreen, foregroundColor: Colors.white, child: Icon(Icons.folder_open)),
                    title: Text(file.displayTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text('Sections: ${file.sections}\nComplainant: ${file.complainantName}', maxLines: 2),
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
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _Menu(this.title, this.icon, this.color, this.onTap);
}
