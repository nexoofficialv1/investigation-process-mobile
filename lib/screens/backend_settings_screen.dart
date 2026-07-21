import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/backend_config.dart';
import '../models/officer_profile.dart';
import '../services/backend_api_service.dart';
import '../services/local_store_service.dart';
import 'server_auth_license_screen.dart';

class BackendSettingsScreen extends StatefulWidget {
  final OfficerProfile profile;
  const BackendSettingsScreen({super.key, required this.profile});

  @override
  State<BackendSettingsScreen> createState() => _BackendSettingsScreenState();
}

class _BackendSettingsScreenState extends State<BackendSettingsScreen> {
  final LocalStoreService _store = LocalStoreService();
  final BackendApiService _api = BackendApiService();
  final _apiBaseController = TextEditingController();
  final _tokenController = TextEditingController();
  final _uploadController = TextEditingController();

  BackendConfig _config = BackendConfig.empty();
  bool _busy = true;
  bool _testing = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await _store.loadBackendConfig();
    _apiBaseController.text = config.apiBaseUrl;
    _tokenController.text = config.apiToken;
    _uploadController.text = config.fileUploadUrl;
    if (!mounted) return;
    setState(() {
      _config = config;
      _busy = false;
    });
  }

  Future<void> _save({String? status, DateTime? testedAt}) async {
    final updated = _config.copyWith(
      apiBaseUrl: _apiBaseController.text.trim(),
      apiToken: _tokenController.text.trim(),
      fileUploadUrl: _uploadController.text.trim(),
      lastStatus: status,
      lastTestedAt: testedAt,
    );
    await _store.saveBackendConfig(updated);
    if (!mounted) return;
    setState(() => _config = updated);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backend settings saved')));
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    final draft = _config.copyWith(
      apiBaseUrl: _apiBaseController.text.trim(),
      apiToken: _tokenController.text.trim(),
      fileUploadUrl: _uploadController.text.trim(),
    );
    final result = await _api.testConnection(draft);
    await _store.saveBackendConfig(draft.copyWith(lastStatus: result, lastTestedAt: DateTime.now()));
    if (!mounted) return;
    setState(() {
      _config = draft.copyWith(lastStatus: result, lastTestedAt: DateTime.now());
      _testing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final cases = await _store.loadCases();
    final draft = _config.copyWith(
      apiBaseUrl: _apiBaseController.text.trim(),
      apiToken: _tokenController.text.trim(),
      fileUploadUrl: _uploadController.text.trim(),
    );
    final result = await _api.syncCases(config: draft, profile: widget.profile, cases: cases);
    await _store.saveBackendConfig(draft.copyWith(lastStatus: result, lastTestedAt: DateTime.now()));
    if (!mounted) return;
    setState(() {
      _config = draft.copyWith(lastStatus: result, lastTestedAt: DateTime.now());
      _syncing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Backend Server Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusCard(),
          const SizedBox(height: 12),
          _modeCard(),
          const SizedBox(height: 12),
          _serverCard(),
          const SizedBox(height: 12),
          _officerLicenseCard(),
          const SizedBox(height: 12),
          _migrationCard(),
        ],
      ),
    );
  }

  Widget _statusCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Current Status', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 8),
            Text('Mode: ${_config.mode}'),
            Text('Sync: ${_config.syncEnabled ? 'Enabled' : 'Disabled'}'),
            Text('সর্বশেষ অবস্থা: ${_config.lastStatus}'),
            if (_config.lastTestedAt != null) Text('সর্বশেষ পরীক্ষা/সিঙ্ক: ${_config.lastTestedAt}'),
          ]),
        ),
      );

  Widget _modeCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ব্যাকএন্ড মোড', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            RadioListTile<String>(
              value: 'offline',
              groupValue: _config.mode,
              title: const Text('শুধু অফলাইন'),
              subtitle: const Text('সব তথ্য মোবাইলের লোকাল স্টোরেজে থাকবে।'),
              onChanged: (v) => setState(() => _config = _config.copyWith(mode: v, syncEnabled: false, lastStatus: 'শুধুমাত্র অফলাইন')),
            ),
            RadioListTile<String>(
              value: 'custom_server',
              groupValue: _config.mode,
              title: const Text('নিজস্ব সার্ভার + পোস্টগ্রেসকিউএল'),
              subtitle: const Text('নিজস্ব এপিআই সার্ভারের মাধ্যমে তথ্য পোস্টগ্রেসকিউএল-এ সংরক্ষণ/সিঙ্ক হবে।'),
              onChanged: (v) => setState(() => _config = _config.copyWith(mode: v, lastStatus: 'নিজস্ব সার্ভার মোড নির্বাচিত')),
            ),
            RadioListTile<String>(
              value: 'supabase',
              groupValue: _config.mode,
              title: const Text('পরবর্তীতে সুপাবেস/পোস্টগ্রেসকিউএল'),
              subtitle: const Text('পরবর্তী সময়ে সুপাবেস ইউআরএল/কী দিয়ে সক্রিয় করা যাবে।'),
              onChanged: (v) => setState(() => _config = _config.copyWith(mode: v, syncEnabled: false, lastStatus: 'সুপাবেস সেটআপ অপেক্ষমাণ')),
            ),
            SwitchListTile(
              value: _config.syncEnabled,
              title: const Text('সিঙ্ক চালু করুন'),
              subtitle: const Text('সার্ভার সংযোগ পরীক্ষা সফল হলে চালু করুন।'),
              onChanged: _config.mode == 'custom_server' ? (v) => setState(() => _config = _config.copyWith(syncEnabled: v)) : null,
            ),
          ]),
        ),
      );

  Widget _serverCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('নিজস্ব সার্ভারের বিবরণ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 8),
            TextField(controller: _apiBaseController, decoration: const InputDecoration(labelText: 'এপিআই মূল ইউআরএল', hintText: 'https://api.yourdomain.com')),
            const SizedBox(height: 8),
            TextField(controller: _tokenController, decoration: const InputDecoration(labelText: 'এপিআই টোকেন / বেয়ারার টোকেন')),
            const SizedBox(height: 8),
            TextField(controller: _uploadController, decoration: const InputDecoration(labelText: 'ফাইল আপলোড ইউআরএল (ঐচ্ছিক)')),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('সংরক্ষণ'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: _testing ? null : _test, icon: const Icon(Icons.wifi_tethering), label: Text(_testing ? 'পরীক্ষা চলছে...' : 'পরীক্ষা করুন'))),
            ]),
          ]),
        ),
      );


  Widget _officerLicenseCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('অফিসার লগইন ও লাইসেন্স', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 8),
            Text(_config.apiToken.isEmpty
                ? 'Server login হয়নি। Officer login করলে token auto-save হবে।'
                : 'Logged in: ${_config.serverOfficerName.isEmpty ? _config.serverOfficerMobile : _config.serverOfficerName}'),
            Text('License: ${_config.licensePlanName} / ${_config.licenseStatus}'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('Open Officer Login / License'),
              onPressed: () async {
                await _save(status: _config.lastStatus, testedAt: _config.lastTestedAt);
                if (!mounted) return;
                await Navigator.push(context, MaterialPageRoute(builder: (_) => ServerAuthLicenseScreen(profile: widget.profile)));
                await _load();
              },
            ),
          ]),
        ),
      );

  Widget _migrationCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('লোকাল তথ্য আপলোড/স্থানান্তর', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 8),
            const Text('ব্যাকএন্ড চালু করার পরে বর্তমান লোকাল মামলাগুলি সার্ভারে আপলোড করা যাবে। প্রথম সংস্করণে মামলা সিঙ্ক হবে; পরে সিডি, বিবৃতি, ফর্ম, প্রমাণ ও ফাইল সিঙ্ক যুক্ত হবে।'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _syncing || !_config.isOnlineEnabled ? null : _syncNow,
              icon: const Icon(Icons.cloud_upload),
              label: Text(_syncing ? 'সিঙ্ক চলছে...' : 'স্থানীয় মামলাগুলি এখন আপলোড করুন'),
            ),
          ]),
        ),
      );
}
