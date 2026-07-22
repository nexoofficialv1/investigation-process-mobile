import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/officer_profile.dart';
import '../widgets/form_helpers.dart';

class OfficerProfileScreen extends StatefulWidget {
  final OfficerProfile profile;
  final ValueChanged<OfficerProfile> onSaved;

  const OfficerProfileScreen({
    super.key,
    required this.profile,
    required this.onSaved,
  });

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController name;
  late final TextEditingController rank;
  late final TextEditingController beltNo;
  late final TextEditingController ps;
  late final TextEditingController district;
  late final TextEditingController court;
  late final TextEditingController mobile;
  late final TextEditingController email;

  String _photoBase64 = '';
  bool _photoBusy = false;

  @override
  void initState() {
    super.initState();
    final OfficerProfile p = widget.profile;
    name = TextEditingController(text: p.name);
    rank = TextEditingController(text: p.rank);
    beltNo = TextEditingController(text: p.beltNo);
    ps = TextEditingController(text: p.policeStation);
    district = TextEditingController(text: p.district);
    court = TextEditingController(text: p.courtName);
    mobile = TextEditingController(text: p.mobile);
    email = TextEditingController(text: p.email);
    _photoBase64 = p.photoBase64;
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

  Uint8List? _decodedPhoto() {
    if (_photoBase64.trim().isEmpty) return null;
    try {
      return base64Decode(_photoBase64);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photoBusy) return;
    setState(() => _photoBusy = true);
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
        requestFullMetadata: false,
      );
      if (image == null) return;
      final Uint8List bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _photoBase64 = base64Encode(bytes));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ছবি নেওয়া যায়নি: $error')),
      );
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  void _save() {
    if (name.text.trim().isEmpty || rank.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অফিসারের নাম ও পদবি আবশ্যক')),
      );
      return;
    }

    widget.onSaved(
      OfficerProfile(
        name: name.text.trim(),
        rank: rank.text.trim(),
        beltNo: beltNo.text.trim(),
        policeStation: ps.text.trim(),
        district: district.text.trim(),
        courtName: court.text.trim(),
        mobile: mobile.text.trim(),
        email: email.text.trim(),
        photoBase64: _photoBase64,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? photoBytes = _decodedPhoto();

    return Scaffold(
      appBar: AppBar(title: const Text('অফিসার প্রোফাইল')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'এই প্রোফাইল থেকে সিডি, বিবৃতি ও ফর্মের অফিসার-তথ্য পূরণ হবে। '
            'প্রোফাইলের ছবি শুধু অ্যাপের পরিচিতি অংশে ব্যবহৃত হবে; '
            'অফিশিয়াল নথিতে স্বয়ংক্রিয়ভাবে বসবে না।',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
              radius: 58,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage:
                  photoBytes == null ? null : MemoryImage(photoBytes),
              child: photoBytes == null
                  ? const Icon(Icons.person_rounded, size: 62)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed:
                    _photoBusy ? null : () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('ক্যামেরা'),
              ),
              OutlinedButton.icon(
                onPressed:
                    _photoBusy ? null : () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('গ্যালারি'),
              ),
              if (_photoBase64.isNotEmpty)
                TextButton.icon(
                  onPressed: _photoBusy
                      ? null
                      : () => setState(() => _photoBase64 = ''),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('ছবি সরান'),
                ),
            ],
          ),
          if (_photoBusy) ...<Widget>[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 18),
          FormHelpers.textField(
            controller: name,
            label: 'অফিসারের নাম',
          ),
          FormHelpers.textField(
            controller: rank,
            label: 'পদবি',
          ),
          FormHelpers.textField(
            controller: beltNo,
            label: 'বেল্ট/আইডি নং',
          ),
          FormHelpers.textField(
            controller: ps,
            label: 'PS',
          ),
          FormHelpers.textField(
            controller: district,
            label: 'জেলা',
          ),
          FormHelpers.textField(
            controller: court,
            label: 'ডিফল্ট আদালত',
          ),
          FormHelpers.textField(
            controller: mobile,
            label: 'মোবাইল নং',
          ),
          FormHelpers.textField(
            controller: email,
            label: 'ই-মেইল',
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('প্রোফাইল সংরক্ষণ করুন'),
          ),
        ],
      ),
    );
  }
}
