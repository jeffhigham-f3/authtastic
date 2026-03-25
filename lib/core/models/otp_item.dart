class OtpItem {
  OtpItem({
    required this.id,
    required this.issuer,
    required this.accountName,
    required this.secret,
    required this.createdAt,
    required this.updatedAt,
    this.algorithm = 'SHA1',
    this.digits = 6,
    this.period = 30,
    this.syncPreference = 'deviceOnly',
    this.revision = 1,
    this.scopeId,
    this.scopeType = 'personal',
  });

  final String id;
  final String issuer;
  final String accountName;
  final String secret;
  final String algorithm;
  final int digits;
  final int period;
  final String syncPreference;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int revision;
  final String? scopeId;
  final String scopeType;

  String get displayName => issuer.isEmpty ? accountName : issuer;

  OtpItem copyWith({
    String? id,
    String? issuer,
    String? accountName,
    String? secret,
    String? algorithm,
    int? digits,
    int? period,
    String? syncPreference,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? revision,
    String? scopeId,
    String? scopeType,
  }) {
    return OtpItem(
      id: id ?? this.id,
      issuer: issuer ?? this.issuer,
      accountName: accountName ?? this.accountName,
      secret: secret ?? this.secret,
      algorithm: algorithm ?? this.algorithm,
      digits: digits ?? this.digits,
      period: period ?? this.period,
      syncPreference: syncPreference ?? this.syncPreference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      scopeId: scopeId ?? this.scopeId,
      scopeType: scopeType ?? this.scopeType,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'issuer': issuer,
      'accountName': accountName,
      'secret': secret,
      'algorithm': algorithm,
      'digits': digits,
      'period': period,
      'syncPreference': syncPreference,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'revision': revision,
      'scopeId': scopeId,
      'scopeType': scopeType,
    };
  }

  factory OtpItem.fromJson(Map<String, dynamic> json) {
    return OtpItem(
      id: json['id'] as String,
      issuer: json['issuer'] as String? ?? '',
      accountName: json['accountName'] as String,
      secret: json['secret'] as String,
      algorithm: (json['algorithm'] as String?) ?? 'SHA1',
      digits: (json['digits'] as num?)?.toInt() ?? 6,
      period: (json['period'] as num?)?.toInt() ?? 30,
      syncPreference: (json['syncPreference'] as String?) ?? 'deviceOnly',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      revision: (json['revision'] as num?)?.toInt() ?? 1,
      scopeId: json['scopeId'] as String?,
      scopeType: (json['scopeType'] as String?) ?? 'personal',
    );
  }
}
