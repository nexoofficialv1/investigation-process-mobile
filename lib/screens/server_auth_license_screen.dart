import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/backend_config.dart';
import '../models/officer_profile.dart';
import '../models/server_license.dart';
import '../services/backend_api_service.dart';
import '../services/local_store_service.dart';

class ServerAuthLicenseScreen extends StatefulWidget {
  final OfficerProfile profile;
  const ServerAuthLicenseScreen({super.key, required this.profile});

  @override
  State<ServerAuthLicenseScreen> createState() => _ServerAuthLicenseScreenState();
}

class _ServerAuthLicenseScreenState extends State<ServerAuthLicenseScreen> {
  final LocalStoreService _store = LocalStoreService();
  final BackendApiService _api = BackendApiService();

  final _apiBaseController = TextEditingController();
  final _setupCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _rankController = TextEditingController();
  final _psController = TextEditingController();
  final _districtController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _activationController = TextEditingController();
  final _grantMobileController = TextEditingController();
  final _grantCodeController = TextEditingController();
  final _paymentRefController = TextEditingController(text: 'MANUAL-UPI');

  BackendConfig _config = BackendConfig.empty();
  bool _busy = true;
  bool _working = false;
  String _message = '';
  String _grantPlan = 'Pro Sync';
  int _grantDays = 365;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _apiBaseController.dispose();
    _setupCodeController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _rankController.dispose();
    _psController.dispose();
    _districtController.dispose();
    _passwordController.dispose();
    _loginController.dispose();
    _loginPasswordController.dispose();
    _activationController.dispose();
    _grantMobileController.dispose();
    _grantCodeController.dispose();
    _paymentRefController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final config = await _store.loadBackendConfig();
    _apiBaseController.text = config.apiBaseUrl;
    _nameController.text = widget.profile.name;
    _mobileController.text = widget.profile.mobile;
    _emailController.text = widget.profile.email;
    _rankController.text = widget.profile.rank;
    _psController.text = widget.profile.policeStation;
    _districtController.text = widget.profile.district;
    _loginController.text = config.serverOfficerMobile.isNotEmpty ? config.serverOfficerMobile : widget.profile.mobile;
    _grantMobileController.text = config.serverOfficerMobile.isNotEmpty ? config.serverOfficerMobile : widget.profile.mobile;
    _grantCodeController.text = 'INVESTIGO-${DateTime.now().year}-PRO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    if (!mounted) return;
    setState(() {
      _config = config;
      _busy = false;
    });
  }

  Future<void> _saveBaseUrl() async {
    final updated = _config.copyWith(
      mode: 'custom_server',
      apiBaseUrl: _apiBaseController.text.trim(),
      lastStatus: 'Server URL saved',
    );
    await _store.saveBackendConfig(updated);
    if (!mounted) return;
    setState(() => _config = updated);
  }

  Future<void> _run(Future<void> Function() job) async {
    if (_working) return;
    setState(() {
      _working = true;
      _message = '';
    });
    try {
      await job();
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _registerOfficer() async {
    await _saveBaseUrl();
    await _run(() async {
      final session = await _api.registerOfficer(
        config: _config.copyWith(mode: 'custom_server', apiBaseUrl: _apiBaseController.text.trim()),
        setupCode: _setupCodeController.text.trim(),
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rank: _rankController.text.trim(),
        psName: _psController.text.trim(),
        district: _districtController.text.trim(),
        role: 'admin',
      );
      await _saveSession(session);
      await _refreshLicense(silent: true);
      if (!mounted) return;
      setState(() => _message = 'Officer registered and logged in successfully.');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Officer registered & logged in')));
    });
  }

  Future<void> _loginOfficer() async {
    await _saveBaseUrl();
    await _run(() async {
      final session = await _api.loginOfficer(
        config: _config.copyWith(mode: 'custom_server', apiBaseUrl: _apiBaseController.text.trim()),
        mobileOrEmail: _loginController.text.trim(),
        password: _loginPasswordController.text,
        deviceId: 'investigo-mobile-${_loginController.text.trim()}',
      );
      await _saveSession(session);
      await _refreshLicense(silent: true);
      if (!mounted) return;
      setState(() => _message = 'Officer login successful. Token saved.');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Officer login successful')));
    });
  }

  Future<void> _saveSession(ServerOfficerSession session) async {
    final updated = _config.copyWith(
      mode: 'custom_server',
      apiBaseUrl: _apiBaseController.text.trim(),
      apiToken: session.token,
      serverOfficerId: session.id,
      serverOfficerName: session.name,
      serverOfficerMobile: session.mobile,
      serverOfficerRole: session.role,
      lastStatus: 'Logged in as ${session.name}',
      lastTestedAt: DateTime.now(),
    );
    await _store.saveBackendConfig(updated);
    if (!mounted) return;
    setState(() {
      _config = updated;
      _loginController.text = session.mobile;
      _grantMobileController.text = session.mobile;
    });
  }

  Future<void> _refreshLicense({bool silent = false}) async {
    if (!_config.isLoggedIn && _config.apiToken.isEmpty) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('First login to server.')));
      }
      return;
    }
    await _run(() async {
      final license = await _api.getLicenseStatus(_config.copyWith(apiBaseUrl: _apiBaseController.text.trim()));
      await _saveLicense(license, status: 'License checked: ${license.planName} / ${license.status}');
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('License: ${license.planName} / ${license.status}')));
      }
    });
  }

  Future<void> _activateLicense() async {
    await _run(() async {
      final license = await _api.activateLicense(
        config: _config.copyWith(apiBaseUrl: _apiBaseController.text.trim()),
        activationCode: _activationController.text.trim(),
      );
      await _saveLicense(license, status: 'License activated: ${license.planName}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('License activated')));
    });
  }

  Future<void> _adminGrantLicense() async {
    await _saveBaseUrl();
    await _run(() async {
      final license = await _api.adminGrantLicense(
        config: _config.copyWith(mode: 'custom_server', apiBaseUrl: _apiBaseController.text.trim()),
        setupCode: _setupCodeController.text.trim(),
        officerMobile: _grantMobileController.text.trim(),
        planName: _grantPlan,
        days: _grantDays,
        allowedDevices: 1,
        aiQuotaMonthly: _grantPlan.contains('AI') ? 300 : 0,
        ocrQuotaMonthly: _grantPlan.contains('AI') ? 200 : 0,
        activationCode: _grantCodeController.text.trim(),
        paymentRef: _paymentRefController.text.trim(),
      );
      if (_config.serverOfficerMobile == _grantMobileController.text.trim()) {
        await _saveLicense(license, status: 'License granted: ${license.planName}');
      }
      if (!mounted) return;
      setState(() => _message = 'License granted. Activation code: ${_grantCodeController.text.trim()}');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('License granted')));
    });
  }

  Future<void> _saveLicense(ServerLicense license, {required String status}) async {
    final updated = _config.copyWith(
      licensePlanName: license.planName,
      licenseStatus: license.status,
      licenseExpiresAt: license.expiresAt,
      syncEnabled: license.isActive,
      lastStatus: status,
      lastTestedAt: DateTime.now(),
    );
    await _store.saveBackendConfig(updated);
    if (!mounted) return;
    setState(() => _config = updated);
  }

  Future<void> _logout() async {
    final updated = _config.copyWith(clearToken: true, syncEnabled: false, lastStatus: 'Logged out');
    await _store.saveBackendConfig(updated);
    if (!mounted) return;
    setState(() => _config = updated);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Officer Login & License')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _statusCard(),
          const SizedBox(height: 12),
          _serverCard(),
          const SizedBox(height: 12),
          _loginCard(),
          const SizedBox(height: 12),
          _registerCard(),
          const SizedBox(height: 12),
          _licenseCard(),
          const SizedBox(height: 12),
          _adminGrantCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statusCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Server Status', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Officer: ${_config.serverOfficerName.isEmpty ? 'Not logged in' : _config.serverOfficerName}'),
            Text('Mobile: ${_config.serverOfficerMobile.isEmpty ? '-' : _config.serverOfficerMobile}'),
            Text('Role: ${_config.serverOfficerRole.isEmpty ? '-' : _config.serverOfficerRole}'),
            Text('License: ${_config.licensePlanName} / ${_config.licenseStatus}'),
            Text('Expiry: ${_config.licenseExpiresAt == null ? '-' : _config.licenseExpiresAt}'),
            Text('Sync: ${_config.syncEnabled ? 'Enabled' : 'Disabled'}'),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_message, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.deepGreen)),
            ],
            if (_config.apiToken.isNotEmpty) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: _working ? null : _logout, icon: const Icon(Icons.logout), label: const Text('Logout / clear token')),
            ],
          ]),
        ),
      );

  Widget _serverCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Server URL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            TextField(controller: _apiBaseController, decoration: const InputDecoration(labelText: 'API Base URL', hintText: 'http://invrstigo-001-site1.dtempurl.com')),
            const SizedBox(height: 10),
            ElevatedButton.icon(onPressed: _working ? null : _saveBaseUrl, icon: const Icon(Icons.save), label: const Text('Save Server URL')),
          ]),
        ),
      );

  Widget _loginCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Officer Login', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            TextField(controller: _loginController, decoration: const InputDecoration(labelText: 'Mobile or Email')),
            const SizedBox(height: 8),
            TextField(controller: _loginPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: _working ? null : _loginOfficer, icon: const Icon(Icons.login), label: Text(_working ? 'Please wait...' : 'Login & Save Token')),
          ]),
        ),
      );

  Widget _registerCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('First Officer / Admin Setup', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 6),
            const Text('শুধু প্রথম setup/admin officer create করার সময় ব্যবহার করুন। Setup code server .env-এর ADMIN_SETUP_CODE।'),
            const SizedBox(height: 8),
            TextField(controller: _setupCodeController, obscureText: true, decoration: const InputDecoration(labelText: 'Private Setup Code')),
            const SizedBox(height: 8),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Officer Name')),
            const SizedBox(height: 8),
            TextField(controller: _mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile')),
            const SizedBox(height: 8),
            TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email optional')),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: _rankController, decoration: const InputDecoration(labelText: 'Rank'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _psController, decoration: const InputDecoration(labelText: 'PS'))),
            ]),
            const SizedBox(height: 8),
            TextField(controller: _districtController, decoration: const InputDecoration(labelText: 'District')),
            const SizedBox(height: 8),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Create Password')),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _working ? null : _registerOfficer, icon: const Icon(Icons.person_add), label: const Text('Create Officer & Login')),
          ]),
        ),
      );

  Widget _licenseCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('License Status / Activation', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Current: ${_config.licensePlanName} / ${_config.licenseStatus}', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            TextField(controller: _activationController, decoration: const InputDecoration(labelText: 'Activation Code')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _working ? null : _refreshLicense, icon: const Icon(Icons.refresh), label: const Text('Check'))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(onPressed: _working ? null : _activateLicense, icon: const Icon(Icons.verified), label: const Text('Activate'))),
            ]),
          ]),
        ),
      );

  Widget _adminGrantCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Admin Grant License', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 6),
            const Text('Admin/owner ব্যবহার করবে। Officer mobile দিয়ে license directly active হবে।'),
            const SizedBox(height: 8),
            TextField(controller: _grantMobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Officer Mobile')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _grantPlan,
              decoration: const InputDecoration(labelText: 'Plan'),
              items: const [
                DropdownMenuItem(value: 'Basic Offline', child: Text('Basic Offline')),
                DropdownMenuItem(value: 'Pro Sync', child: Text('Pro Sync')),
                DropdownMenuItem(value: 'AI Pro', child: Text('AI Pro')),
                DropdownMenuItem(value: 'Lifetime Manual', child: Text('Lifetime Manual')),
              ],
              onChanged: (v) => setState(() => _grantPlan = v ?? _grantPlan),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _grantDays,
              decoration: const InputDecoration(labelText: 'Validity'),
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 days')),
                DropdownMenuItem(value: 365, child: Text('1 year')),
                DropdownMenuItem(value: 3650, child: Text('10 years / lifetime style')),
              ],
              onChanged: (v) => setState(() => _grantDays = v ?? _grantDays),
            ),
            const SizedBox(height: 8),
            TextField(controller: _grantCodeController, decoration: const InputDecoration(labelText: 'Activation Code')),
            const SizedBox(height: 8),
            TextField(controller: _paymentRefController, decoration: const InputDecoration(labelText: 'Payment Ref')),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: _working ? null : _adminGrantLicense, icon: const Icon(Icons.admin_panel_settings), label: const Text('Grant License')),
          ]),
        ),
      );
}
