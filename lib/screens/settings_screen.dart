import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';
import 'backend_settings_screen.dart';
import 'backup_screen.dart';
import 'compliance_screen.dart';
import 'language_settings_screen.dart';
import 'ocr_scanner_screen.dart';
import 'officer_profile_screen.dart';
import 'server_auth_license_screen.dart';
import 'sop_compliance_screen.dart';

class SettingsScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile? latestCase;
  final Future<void> Function(OfficerProfile) onProfileUpdated;

  const SettingsScreen({
    super.key,
    required this.profile,
    required this.latestCase,
    required this.onProfileUpdated,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late OfficerProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  Uint8List? _photoBytes() {
    if (_profile.photoBase64.trim().isEmpty) return null;
    try {
      return base64Decode(_profile.photoBase64);
    } catch (_) {
      return null;
    }
  }

  void _needCase() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'আইনগত অনুবর্তিতা বা SOP খুলতে প্রথমে একটি মামলা নির্বাচন/তৈরি করুন।',
        ),
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OfficerProfileScreen(
          profile: _profile,
          onSaved: (OfficerProfile updated) async {
            await widget.onProfileUpdated(updated);
            if (!mounted) return;
            setState(() => _profile = updated);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _openCompliance() async {
    final CaseFile? file = widget.latestCase;
    if (file == null) {
      _needCase();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ComplianceScreen(caseFile: file),
      ),
    );
  }

  Future<void> _openSop() async {
    final CaseFile? file = widget.latestCase;
    if (file == null) {
      _needCase();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SopComplianceScreen(caseFile: file),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: AppTheme.deepGreen,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.deepGreen.withValues(alpha: 0.12),
          foregroundColor: AppTheme.deepGreen,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = _photoBytes();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                radius: 31,
                backgroundImage: bytes == null ? null : MemoryImage(bytes),
                child: bytes == null
                    ? const Icon(Icons.person_rounded, size: 34)
                    : null,
              ),
              title: Text(
                _profile.name.isEmpty ? 'Officer Profile' : _profile.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                '${_profile.rank} • ${_profile.policeStation}',
              ),
              trailing: const Icon(Icons.edit_rounded),
              onTap: _openProfile,
            ),
          ),
          _sectionTitle('অফিসার ও ভাষা'),
          _settingTile(
            icon: Icons.badge_rounded,
            title: 'Officer Profile',
            subtitle: 'IO-এর পরিচয়, ছবি, পদবি, PS, আদালত ও যোগাযোগ',
            onTap: _openProfile,
          ),
          _settingTile(
            icon: Icons.language_rounded,
            title: 'Language Settings',
            subtitle: 'App, narration, CD এবং Report-এর default ভাষা',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const LanguageSettingsScreen(),
              ),
            ),
          ),
          _settingTile(
            icon: Icons.document_scanner_rounded,
            title: 'OCR Scanner',
            subtitle: 'ক্যামেরা/গ্যালারির নথি থেকে editable text সংগ্রহ',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const OcrScannerScreen(),
              ),
            ),
          ),
          _sectionTitle('ডেটা ও সার্ভার'),
          _settingTile(
            icon: Icons.dns_rounded,
            title: 'Backend / Server',
            subtitle: 'Offline/Server mode, connection ও sync configuration',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => BackendSettingsScreen(profile: _profile),
              ),
            ),
          ),
          _settingTile(
            icon: Icons.backup_rounded,
            title: 'Backup & Restore',
            subtitle: 'Local backup, share backup এবং restore',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => BackupScreen(profile: _profile),
              ),
            ),
          ),
          _settingTile(
            icon: Icons.workspace_premium_rounded,
            title: 'Login & License',
            subtitle: 'Officer login, activation এবং license status',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    ServerAuthLicenseScreen(profile: _profile),
              ),
            ),
          ),
          _sectionTitle('আইন ও তদন্ত নির্দেশনা'),
          _settingTile(
            icon: Icons.gavel_rounded,
            title: 'আইনগত অনুবর্তিতা',
            subtitle: 'সর্বশেষ নির্বাচিত মামলার ধারাভিত্তিক legal checks',
            onTap: _openCompliance,
          ),
          _settingTile(
            icon: Icons.policy_rounded,
            title: 'SOP',
            subtitle: 'সর্বশেষ নির্বাচিত মামলার SOP নির্দেশনা ও status',
            onTap: _openSop,
          ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }
}
