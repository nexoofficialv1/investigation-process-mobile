import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_theme.dart';
import 'models/officer_profile.dart';
import 'screens/dashboard_screen.dart';
import 'screens/officer_profile_screen.dart';
import 'screens/intro_screen.dart';
import 'services/local_store_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InvestigationProcessApp());
}

class InvestigationProcessApp extends StatelessWidget {
  const InvestigationProcessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ইনভেস্টিগো — তদন্ত সহায়ক',
      locale: const Locale('bn', 'BD'),
      supportedLocales: const [Locale('bn', 'BD'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      home: const StartupGate(),
    );
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  final LocalStoreService _store = LocalStoreService();
  OfficerProfile? _profile;
  bool _introDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _store.loadOfficerProfile();
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    if (!_introDone) {
      return IntroScreen(onStart: () => setState(() => _introDone = true));
    }
    final profile = _profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!profile.isComplete) {
      return OfficerProfileScreen(
        profile: profile,
        onSaved: (updated) async {
          await _store.saveOfficerProfile(updated);
          if (!mounted) return;
          setState(() => _profile = updated);
        },
      );
    }
    return DashboardScreen(profile: profile);
  }
}
