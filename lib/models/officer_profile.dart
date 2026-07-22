class OfficerProfile {
  final String name;
  final String rank;
  final String beltNo;
  final String policeStation;
  final String district;
  final String courtName;
  final String mobile;
  final String email;
  final String photoBase64;

  const OfficerProfile({
    required this.name,
    required this.rank,
    required this.beltNo,
    required this.policeStation,
    required this.district,
    required this.courtName,
    required this.mobile,
    required this.email,
    this.photoBase64 = '',
  });

  factory OfficerProfile.empty() => const OfficerProfile(
        name: '',
        rank: '',
        beltNo: '',
        policeStation: 'Kalna PS',
        district: 'পূর্ব বর্ধমান',
        courtName: 'বিজ্ঞ এসিজেএম আদালত, কালনা',
        mobile: '',
        email: '',
        photoBase64: '',
      );

  bool get isComplete => name.trim().isNotEmpty && rank.trim().isNotEmpty;

  OfficerProfile copyWith({
    String? name,
    String? rank,
    String? beltNo,
    String? policeStation,
    String? district,
    String? courtName,
    String? mobile,
    String? email,
    String? photoBase64,
  }) {
    return OfficerProfile(
      name: name ?? this.name,
      rank: rank ?? this.rank,
      beltNo: beltNo ?? this.beltNo,
      policeStation: policeStation ?? this.policeStation,
      district: district ?? this.district,
      courtName: courtName ?? this.courtName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'rank': rank,
        'beltNo': beltNo,
        'policeStation': policeStation,
        'district': district,
        'courtName': courtName,
        'mobile': mobile,
        'email': email,
        'photoBase64': photoBase64,
      };

  factory OfficerProfile.fromJson(Map<dynamic, dynamic> json) {
    return OfficerProfile(
      name: json['name']?.toString() ?? '',
      rank: json['rank']?.toString() ?? '',
      beltNo: json['beltNo']?.toString() ?? '',
      policeStation: json['policeStation']?.toString() ?? 'Kalna PS',
      district: json['district']?.toString() ?? 'পূর্ব বর্ধমান',
      courtName:
          json['courtName']?.toString() ?? 'বিজ্ঞ এসিজেএম আদালত, কালনা',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      photoBase64: json['photoBase64']?.toString() ?? '',
    );
  }
}
