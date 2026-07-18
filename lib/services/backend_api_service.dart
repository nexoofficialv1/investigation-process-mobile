import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/backend_config.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../models/server_license.dart';

class BackendApiException implements Exception {
  final String message;
  final int? statusCode;
  BackendApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class BackendApiService {
  String _base(BackendConfig config) => config.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  Future<String> testConnection(BackendConfig config) async {
    if (!config.isCustomServer) {
      return config.mode == 'offline' ? 'Offline mode selected' : 'Supabase mode will be configured later';
    }
    final base = _base(config);
    if (base.isEmpty) return 'API Base URL is empty';

    final paths = <String>['/health', '/api/health'];
    Object? lastError;
    for (final path in paths) {
      try {
        final res = await http
            .get(Uri.parse('$base$path'), headers: _headers(config))
            .timeout(const Duration(seconds: 12));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          return 'Connected: ${res.body}';
        }
        lastError = 'Server responded ${res.statusCode}: ${res.body}';
      } catch (e) {
        lastError = e;
      }
    }
    return 'Connection failed: $lastError';
  }

  Future<ServerOfficerSession> registerOfficer({
    required BackendConfig config,
    required String setupCode,
    required String name,
    required String mobile,
    required String email,
    required String password,
    required String rank,
    required String psName,
    required String district,
    String role = 'officer',
  }) async {
    final base = _base(config);
    if (base.isEmpty) throw BackendApiException('API Base URL is empty');
    final res = await http
        .post(
          Uri.parse('$base/api/auth/register'),
          headers: {
            'Content-Type': 'application/json',
            'x-admin-setup-code': setupCode,
          },
          body: jsonEncode({
            'name': name,
            'mobile': mobile,
            'email': email,
            'password': password,
            'rank': rank,
            'ps_name': psName,
            'district': district,
            'role': role,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw BackendApiException(_extractError(res), statusCode: res.statusCode);
    }
    // Register endpoint creates the officer; log in immediately to obtain token.
    return loginOfficer(config: config, mobileOrEmail: mobile, password: password);
  }

  Future<ServerOfficerSession> loginOfficer({
    required BackendConfig config,
    required String mobileOrEmail,
    required String password,
    String deviceId = 'investigo-mobile',
  }) async {
    final base = _base(config);
    if (base.isEmpty) throw BackendApiException('API Base URL is empty');
    final isEmail = mobileOrEmail.contains('@');
    final res = await http
        .post(
          Uri.parse('$base/api/auth/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            if (isEmail) 'email': mobileOrEmail else 'mobile': mobileOrEmail,
            'password': password,
            'device_id': deviceId,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw BackendApiException(_extractError(res), statusCode: res.statusCode);
    }
    return ServerOfficerSession.fromLoginJson(Map<String, dynamic>.from(jsonDecode(res.body)));
  }

  Future<ServerLicense> getLicenseStatus(BackendConfig config) async {
    final base = _base(config);
    if (base.isEmpty) throw BackendApiException('API Base URL is empty');
    final res = await http
        .get(Uri.parse('$base/api/license/status'), headers: _headers(config))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw BackendApiException(_extractError(res), statusCode: res.statusCode);
    }
    final decoded = Map<String, dynamic>.from(jsonDecode(res.body));
    return ServerLicense.fromJson(Map<String, dynamic>.from(decoded['license'] ?? <String, dynamic>{}));
  }

  Future<ServerLicense> activateLicense({
    required BackendConfig config,
    required String activationCode,
  }) async {
    final base = _base(config);
    if (base.isEmpty) throw BackendApiException('API Base URL is empty');
    final res = await http
        .post(
          Uri.parse('$base/api/license/activate-manual'),
          headers: _headers(config),
          body: jsonEncode({'activation_code': activationCode}),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw BackendApiException(_extractError(res), statusCode: res.statusCode);
    }
    final decoded = Map<String, dynamic>.from(jsonDecode(res.body));
    return ServerLicense.fromJson(Map<String, dynamic>.from(decoded['license'] ?? <String, dynamic>{}));
  }

  Future<ServerLicense> adminGrantLicense({
    required BackendConfig config,
    required String setupCode,
    required String officerMobile,
    required String planName,
    required int days,
    required int allowedDevices,
    required int aiQuotaMonthly,
    required int ocrQuotaMonthly,
    required String activationCode,
    String paymentRef = 'MANUAL',
  }) async {
    final base = _base(config);
    if (base.isEmpty) throw BackendApiException('API Base URL is empty');
    final res = await http
        .post(
          Uri.parse('$base/api/license/admin/grant'),
          headers: {
            'Content-Type': 'application/json',
            'x-admin-setup-code': setupCode,
          },
          body: jsonEncode({
            'officer_mobile': officerMobile,
            'plan_name': planName,
            'days': days,
            'allowed_devices': allowedDevices,
            'ai_quota_monthly': aiQuotaMonthly,
            'ocr_quota_monthly': ocrQuotaMonthly,
            'activation_code': activationCode,
            'payment_ref': paymentRef,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw BackendApiException(_extractError(res), statusCode: res.statusCode);
    }
    final decoded = Map<String, dynamic>.from(jsonDecode(res.body));
    return ServerLicense.fromJson(Map<String, dynamic>.from(decoded['license'] ?? <String, dynamic>{}));
  }

  Future<String> syncCases({
    required BackendConfig config,
    required OfficerProfile profile,
    required List<CaseFile> cases,
  }) async {
    if (!config.isCustomServer || !config.syncEnabled) return 'Sync disabled';
    final base = _base(config);
    if (base.isEmpty) return 'API Base URL is empty';
    try {
      final payload = {
        'officer': profile.toJson(),
        'cases': cases.map((e) => e.toJson()).toList(),
      };
      final res = await http
          .post(Uri.parse('$base/api/sync/cases'), headers: _headers(config), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode >= 200 && res.statusCode < 300) return 'Synced ${cases.length} cases';
      return 'Sync failed ${res.statusCode}: ${res.body}';
    } catch (e) {
      return 'Sync failed: $e';
    }
  }

  Map<String, String> _headers(BackendConfig config) => {
        'Content-Type': 'application/json',
        if (config.apiToken.trim().isNotEmpty) 'Authorization': 'Bearer ${config.apiToken.trim()}',
      };

  String _extractError(http.Response res) {
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(res.body));
      return decoded['message']?.toString() ?? decoded['error']?.toString() ?? res.body;
    } catch (_) {
      return res.body.isEmpty ? 'HTTP ${res.statusCode}' : res.body;
    }
  }
}
