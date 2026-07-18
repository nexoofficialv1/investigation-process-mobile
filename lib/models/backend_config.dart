class BackendConfig {
  final String mode; // offline, custom_server, supabase
  final String apiBaseUrl;
  final String apiToken;
  final String fileUploadUrl;
  final bool syncEnabled;
  final DateTime? lastTestedAt;
  final String lastStatus;

  // Server-side officer/login/license state.
  final String serverOfficerId;
  final String serverOfficerName;
  final String serverOfficerMobile;
  final String serverOfficerRole;
  final String licensePlanName;
  final String licenseStatus;
  final DateTime? licenseExpiresAt;

  const BackendConfig({
    this.mode = 'offline',
    this.apiBaseUrl = '',
    this.apiToken = '',
    this.fileUploadUrl = '',
    this.syncEnabled = false,
    this.lastTestedAt,
    this.lastStatus = 'Offline only',
    this.serverOfficerId = '',
    this.serverOfficerName = '',
    this.serverOfficerMobile = '',
    this.serverOfficerRole = '',
    this.licensePlanName = 'Offline Trial',
    this.licenseStatus = 'trial',
    this.licenseExpiresAt,
  });

  bool get isCustomServer => mode == 'custom_server';
  bool get isSupabase => mode == 'supabase';
  bool get isOnlineEnabled => mode != 'offline' && syncEnabled;
  bool get isLoggedIn => apiToken.trim().isNotEmpty && serverOfficerId.trim().isNotEmpty;
  bool get hasActiveLicense => licenseStatus == 'active' || licenseStatus == 'trial';

  BackendConfig copyWith({
    String? mode,
    String? apiBaseUrl,
    String? apiToken,
    String? fileUploadUrl,
    bool? syncEnabled,
    DateTime? lastTestedAt,
    String? lastStatus,
    String? serverOfficerId,
    String? serverOfficerName,
    String? serverOfficerMobile,
    String? serverOfficerRole,
    String? licensePlanName,
    String? licenseStatus,
    DateTime? licenseExpiresAt,
    bool clearToken = false,
    bool clearLicenseExpiry = false,
  }) {
    return BackendConfig(
      mode: mode ?? this.mode,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiToken: clearToken ? '' : (apiToken ?? this.apiToken),
      fileUploadUrl: fileUploadUrl ?? this.fileUploadUrl,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      lastTestedAt: lastTestedAt ?? this.lastTestedAt,
      lastStatus: lastStatus ?? this.lastStatus,
      serverOfficerId: clearToken ? '' : (serverOfficerId ?? this.serverOfficerId),
      serverOfficerName: clearToken ? '' : (serverOfficerName ?? this.serverOfficerName),
      serverOfficerMobile: clearToken ? '' : (serverOfficerMobile ?? this.serverOfficerMobile),
      serverOfficerRole: clearToken ? '' : (serverOfficerRole ?? this.serverOfficerRole),
      licensePlanName: clearToken ? 'Offline Trial' : (licensePlanName ?? this.licensePlanName),
      licenseStatus: clearToken ? 'trial' : (licenseStatus ?? this.licenseStatus),
      licenseExpiresAt: clearToken || clearLicenseExpiry ? null : (licenseExpiresAt ?? this.licenseExpiresAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'apiBaseUrl': apiBaseUrl,
        'apiToken': apiToken,
        'fileUploadUrl': fileUploadUrl,
        'syncEnabled': syncEnabled,
        'lastTestedAt': lastTestedAt?.toIso8601String(),
        'lastStatus': lastStatus,
        'serverOfficerId': serverOfficerId,
        'serverOfficerName': serverOfficerName,
        'serverOfficerMobile': serverOfficerMobile,
        'serverOfficerRole': serverOfficerRole,
        'licensePlanName': licensePlanName,
        'licenseStatus': licenseStatus,
        'licenseExpiresAt': licenseExpiresAt?.toIso8601String(),
      };

  factory BackendConfig.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) {
      if (value == null || value.toString().isEmpty) return null;
      return DateTime.tryParse(value.toString());
    }

    return BackendConfig(
      mode: json['mode']?.toString() ?? 'offline',
      apiBaseUrl: json['apiBaseUrl']?.toString() ?? '',
      apiToken: json['apiToken']?.toString() ?? '',
      fileUploadUrl: json['fileUploadUrl']?.toString() ?? '',
      syncEnabled: json['syncEnabled'] == true,
      lastTestedAt: parseDate(json['lastTestedAt']),
      lastStatus: json['lastStatus']?.toString() ?? 'Offline only',
      serverOfficerId: json['serverOfficerId']?.toString() ?? '',
      serverOfficerName: json['serverOfficerName']?.toString() ?? '',
      serverOfficerMobile: json['serverOfficerMobile']?.toString() ?? '',
      serverOfficerRole: json['serverOfficerRole']?.toString() ?? '',
      licensePlanName: json['licensePlanName']?.toString() ?? 'Offline Trial',
      licenseStatus: json['licenseStatus']?.toString() ?? 'trial',
      licenseExpiresAt: parseDate(json['licenseExpiresAt']),
    );
  }

  factory BackendConfig.empty() => const BackendConfig();
}
