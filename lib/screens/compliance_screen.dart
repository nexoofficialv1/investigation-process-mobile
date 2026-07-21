import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../services/compliance_service.dart';

class ComplianceScreen extends StatelessWidget {
  final CaseFile caseFile;

  const ComplianceScreen({super.key, required this.caseFile});

  @override
  Widget build(BuildContext context) {
    final tasks = ComplianceService().buildTasks(caseFile);
    return Scaffold(
      appBar: AppBar(title: const Text('আইনগত অনুবর্তিতা যাচাইতালিকা')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(caseFile.displayTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('ধারা: ${caseFile.sections}'),
                  const SizedBox(height: 8),
                  const Text('এই যাচাইতালিকা ধারাভিত্তিক নির্দেশনা দেয়। এটি তদন্তকারী অফিসারের বিচারবোধ বা আইনগত যাচাইয়ের বিকল্প নয়।', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...tasks.map((task) => Card(
                child: ListTile(
                  leading: Icon(task.mandatory ? Icons.priority_high : Icons.check_circle_outline),
                  title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('অগ্রাধিকার: ${task.priority} • ${task.detail}'),
                  isThreeLine: true,
                ),
              )),
          const SizedBox(height: 70),
        ],
      ),
    );
  }
}
