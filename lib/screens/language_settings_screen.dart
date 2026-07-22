import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_language_controller.dart';
import '../core/app_theme.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  static const String _narrationKey = 'investigo_narration_language_v1';
  static const String _cdKey = 'investigo_default_cd_language_v1';
  static const String _reportKey = 'investigo_default_report_language_v1';

  String _appLanguage = AppLanguageController.instance.languageCode;
  String _narrationLanguage = 'bn';
  String _cdLanguage = 'en';
  String _reportLanguage = 'en';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _appLanguage = AppLanguageController.instance.languageCode;
      _narrationLanguage =
          preferences.getString(_narrationKey) ?? 'bn';
      _cdLanguage = preferences.getString(_cdKey) ?? 'en';
      _reportLanguage = preferences.getString(_reportKey) ?? 'en';
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.setString(_narrationKey, _narrationLanguage);
    await preferences.setString(_cdKey, _cdLanguage);
    await preferences.setString(_reportKey, _reportLanguage);
    await AppLanguageController.instance.setLanguage(_appLanguage);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Language settings saved')),
    );
  }

  Widget _languageField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey<String>('$label-$value'),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: const <DropdownMenuItem<String>>[
        DropdownMenuItem<String>(
          value: 'bn',
          child: Text('বাংলা'),
        ),
        DropdownMenuItem<String>(
          value: 'en',
          child: Text('English'),
        ),
      ],
      onChanged: (String? next) {
        if (next != null) onChanged(next);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Language Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'App-এর ভাষা, IO narration-এর default ভাষা এবং '
                'CD/Report-এর default output ভাষা আলাদাভাবে নির্বাচন করুন। '
                'প্রয়োজনে প্রতিটি নথি তৈরির সময় ভাষা বদলানো যাবে।',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _languageField(
            label: 'App language',
            value: _appLanguage,
            onChanged: (String value) =>
                setState(() => _appLanguage = value),
          ),
          const SizedBox(height: 12),
          _languageField(
            label: 'IO narration-এর default ভাষা',
            value: _narrationLanguage,
            onChanged: (String value) =>
                setState(() => _narrationLanguage = value),
          ),
          const SizedBox(height: 12),
          _languageField(
            label: 'Case Diary-এর default ভাষা',
            value: _cdLanguage,
            onChanged: (String value) =>
                setState(() => _cdLanguage = value),
          ),
          const SizedBox(height: 12),
          _languageField(
            label: 'Report-এর default ভাষা',
            value: _reportLanguage,
            onChanged: (String value) =>
                setState(() => _reportLanguage = value),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: Text(_saving ? 'সংরক্ষণ হচ্ছে...' : 'সংরক্ষণ করুন'),
          ),
        ],
      ),
    );
  }
}
