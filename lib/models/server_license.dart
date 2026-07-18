class ServerLicense {
  final String planName;
  final String status;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final int allowedDevices;
  final int aiQuotaMonthly;
  final int ocrQuotaMonthly;
  final String activationCode;

  const ServerLicense({
    this.planName = 'Offline Trial',
    this.status = 'trial',
    this.startsAt,
    this.expiresAt,
    this.allowedDevices = 1,
    this.aiQuotaMonthly = 0,
    this.ocrQuotaMonthly = 0,
    this.activationCode = '',
  });

  bool get isActive => status == 'active' || status == 'trial';

  factory ServerLicense.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) {
      if (value == null || value.toString().isEmpty) return null;
      return DateTime.tryParse(value.toString());
    }

    return ServerLicense(
      planName: json['plan_name']?.toString() ?? json['planName']?.toString() ?? 'Offline Trial',
      status: json['status']?.toString() ?? 'trial',
      startsAt: parseDate(json['starts_at'] ?? json['startsAt']),
      expiresAt: parseDate(json['expires_at'] ?? json['expiresAt']),
      allowedDevices: int.tryParse((json['allowed_devices'] ?? json['allowedDevices'] ?? 1).toString()) ?? 1,
      aiQuotaMonthly: int.tryParse((json['ai_quota_monthly'] ?? json['aiQuotaMonthly'] ?? 0).toString()) ?? 0,
      ocrQuotaMonthly: int.tryParse((json['ocr_quota_monthly'] ?? json['ocrQuotaMonthly'] ?? 0).toString()) ?? 0,
      activationCode: json['activation_code']?.toString() ?? json['activationCode']?.toString() ?? '',
    );
  }
}

class ServerOfficerSession {
  final String token;
  final String id;
  final String name;
  final String mobile;
  final String email;
  final String rank;
  final String psName;
  final String district;
  final String role;

  const ServerOfficerSession({
    required this.token,
    required this.id,
    required this.name,
    required this.mobile,
    this.email = '',
    this.rank = '',
    this.psName = '',
    this.district = '',
    this.role = 'officer',
  });

  factory ServerOfficerSession.fromLoginJson(Map<String, dynamic> json) {
    final officer = Map<String, dynamic>.from(json['officer'] ?? <String, dynamic>{});
    return ServerOfficerSession(
      token: json['token']?.toString() ?? '',
      id: officer['id']?.toString() ?? '',
      name: officer['name']?.toString() ?? '',
      mobile: officer['mobile']?.toString() ?? '',
      email: officer['email']?.toString() ?? '',
      rank: officer['rank']?.toString() ?? '',
      psName: officer['ps_name']?.toString() ?? officer['psName']?.toString() ?? '',
      district: officer['district']?.toString() ?? '',
      role: officer['role']?.toString() ?? 'officer',
    );
  }
}
