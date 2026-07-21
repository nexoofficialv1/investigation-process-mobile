import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_theme.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _upiController = TextEditingController();
  final _txnController = TextEditingController();
  final _activationController = TextEditingController();
  final _feeController = TextEditingController();
  String _plan = 'বিনামূল্যে/অফলাইন ট্রায়াল';
  String _status = 'সক্রিয় নয়';
  String _fee = 'নির্ধারণ করা হয়নি';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _plan = prefs.getString('license_plan_v1') ?? 'বিনামূল্যে/অফলাইন ট্রায়াল';
      _status = prefs.getString('license_status_v1') ?? 'সক্রিয় নয়';
      _fee = prefs.getString('license_fee_v1') ?? 'নির্ধারণ করা হয়নি';
      _feeController.text = _fee;
      _upiController.text = prefs.getString('license_upi_v1') ?? '';
      _txnController.text = prefs.getString('license_txn_v1') ?? '';
      _activationController.text = prefs.getString('license_code_v1') ?? '';
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('license_plan_v1', _plan);
    await prefs.setString('license_status_v1', _status);
    await prefs.setString('license_fee_v1', _feeController.text.trim().isEmpty ? _fee : _feeController.text.trim());
    await prefs.setString('license_upi_v1', _upiController.text.trim());
    await prefs.setString('license_txn_v1', _txnController.text.trim());
    await prefs.setString('license_code_v1', _activationController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('লাইসেন্স/পেমেন্ট সেটিংস সংরক্ষিত হয়েছে')));
  }

  Future<void> _activateOffline() async {
    final code = _activationController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('বৈধ সক্রিয়করণ কোড লিখুন')));
      return;
    }
    setState(() => _status = 'স্থানীয়ভাবে সক্রিয় হয়েছে');
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('লাইসেন্স ও ফি')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('বর্তমান লাইসেন্স', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 8),
                Text('পরিকল্পনা: $_plan'),
                Text('অবস্থা: $_status'),
                Text('ফি: $_fee'),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('পরিকল্পনা/ফি সেটআপ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _plan,
                  decoration: const InputDecoration(labelText: 'পরিকল্পনা'),
                  items: const [
                    DropdownMenuItem(value: 'বিনামূল্যে/অফলাইন ট্রায়াল', child: Text('বিনামূল্যে/অফলাইন ট্রায়াল')),
                    DropdownMenuItem(value: 'মাসিক লাইসেন্স', child: Text('মাসিক লাইসেন্স')),
                    DropdownMenuItem(value: 'বার্ষিক লাইসেন্স', child: Text('বার্ষিক লাইসেন্স')),
                    DropdownMenuItem(value: 'আজীবন/ম্যানুয়াল সক্রিয়করণ', child: Text('আজীবন/ম্যানুয়াল সক্রিয়করণ')),
                  ],
                  onChanged: (v) => setState(() => _plan = v ?? _plan),
                ),
                const SizedBox(height: 8),
                TextField(controller: _feeController, decoration: const InputDecoration(labelText: 'ফি-এর পরিমাণ/মন্তব্য')),
                const SizedBox(height: 8),
                TextField(controller: _upiController, decoration: const InputDecoration(labelText: 'ইউপিআই আইডি/পেমেন্টের বিবরণ')),
                const SizedBox(height: 8),
                TextField(controller: _txnController, decoration: const InputDecoration(labelText: 'লেনদেন আইডি/রসিদ নং')),
                const SizedBox(height: 8),
                TextField(controller: _activationController, decoration: const InputDecoration(labelText: 'সক্রিয়করণ কোড')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('সংরক্ষণ'))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(onPressed: _activateOffline, icon: const Icon(Icons.verified), label: const Text('সক্রিয় করুন'))),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('নোট: এখন লোকাল/ম্যানুয়াল লাইসেন্স রেকর্ড থাকবে। ব্যাকএন্ড সার্ভার যুক্ত হলে লাইসেন্স যাচাই, মেয়াদ, নবায়ন, পেমেন্ট রসিদ আপলোড ও সার্ভারভিত্তিক সক্রিয়করণ যুক্ত করা যাবে।'),
            ),
          ),
        ],
      ),
    );
  }
}
