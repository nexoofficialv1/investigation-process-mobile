import 'package:flutter/material.dart';

import '../models/officer_profile.dart';
import '../widgets/form_helpers.dart';

class OfficerProfileScreen extends StatefulWidget {
  final OfficerProfile profile;
  final ValueChanged<OfficerProfile> onSaved;

  const OfficerProfileScreen({super.key, required this.profile, required this.onSaved});

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  late final TextEditingController name;
  late final TextEditingController rank;
  late final TextEditingController beltNo;
  late final TextEditingController ps;
  late final TextEditingController district;
  late final TextEditingController court;
  late final TextEditingController mobile;
  late final TextEditingController email;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    name = TextEditingController(text: p.name);
    rank = TextEditingController(text: p.rank);
    beltNo = TextEditingController(text: p.beltNo);
    ps = TextEditingController(text: p.policeStation);
    district = TextEditingController(text: p.district);
    court = TextEditingController(text: p.courtName);
    mobile = TextEditingController(text: p.mobile);
    email = TextEditingController(text: p.email);
  }

  @override
  void dispose() {
    name.dispose();
    rank.dispose();
    beltNo.dispose();
    ps.dispose();
    district.dispose();
    court.dispose();
    mobile.dispose();
    email.dispose();
    super.dispose();
  }

  void _save() {
    if (name.text.trim().isEmpty || rank.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অফিসারের নাম ও পদবি আবশ্যক')));
      return;
    }
    widget.onSaved(OfficerProfile(
      name: name.text.trim(),
      rank: rank.text.trim(),
      beltNo: beltNo.text.trim(),
      policeStation: ps.text.trim(),
      district: district.text.trim(),
      courtName: court.text.trim(),
      mobile: mobile.text.trim(),
      email: email.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('অফিসার প্রোফাইল')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('প্রথমে অফিসার প্রোফাইল পূরণ করুন। এই প্রোফাইল থেকে সিডি, বিবৃতি ও ফর্ম স্বয়ংক্রিয়ভাবে পূরণ হবে।', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          FormHelpers.textField(controller: name, label: 'অফিসারের নাম'),
          FormHelpers.textField(controller: rank, label: 'পদবি'),
          FormHelpers.textField(controller: beltNo, label: 'বেল্ট/আইডি নং'),
          FormHelpers.textField(controller: ps, label: 'PS'),
          FormHelpers.textField(controller: district, label: 'জেলা'),
          FormHelpers.textField(controller: court, label: 'ডিফল্ট আদালত'),
          FormHelpers.textField(controller: mobile, label: 'মোবাইল নং'),
          FormHelpers.textField(controller: email, label: 'ই-মেইল'),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('প্রোফাইল সংরক্ষণ করুন')),
        ],
      ),
    );
  }
}
