import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_language_controller.dart';
import 'core/app_theme.dart';
import 'models/officer_profile.dart';
import 'screens/dashboard_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/officer_profile_screen.dart';
import 'services/local_store_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLanguageController.instance.load();
  runApp(const InvestigationProcessApp());
}

class InvestigationProcessApp extends StatelessWidget {
  const InvestigationProcessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguageController.instance,
      builder: (context, _) {
        final language = AppLanguageController.instance;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: language.text(
            'ইনভেস্টিগো — তদন্ত সহায়ক',
            'INVESTIGO — Investigation Assistant',
          ),
          locale: language.locale,
          supportedLocales: const <Locale>[
            Locale('bn', 'BD'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
          builder: (context, child) => Stack(
            children: <Widget>[
              if (child != null) child,
              const Positioned(
                right: 10,
                bottom: 82,
                child: _GlobalLanguageButton(),
              ),
            ],
          ),
          home: const StartupGate(),
        );
      },
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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


class _GlobalLanguageButton extends StatelessWidget {
  const _GlobalLanguageButton();

  @override
  Widget build(BuildContext context) {
    final controller = AppLanguageController.instance;
    return SafeArea(
      child: Material(
        elevation: 5,
        color: Theme.of(context).colorScheme.surface,
        shape: const StadiumBorder(),
        child: PopupMenuButton<String>(
          tooltip: controller.text('ভাষা পরিবর্তন', 'Change language'),
          initialValue: controller.languageCode,
          onSelected: (value) { controller.setLanguage(value); },
          itemBuilder: (context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'bn', child: Text('বাংলা')),
            PopupMenuItem<String>(value: 'en', child: Text('English')),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.language, size: 19),
                const SizedBox(width: 6),
                Text(
                  controller.isBangla ? 'বাংলা' : 'EN',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
