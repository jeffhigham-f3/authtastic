class PasswordItem {
  PasswordItem({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
    this.website,
    this.notes,
    this.category,
    this.lastUsedAt,
    this.revision = 1,
    this.scopeId,
    this.scopeType = 'personal',
  });

  final String id;
  final String title;
  final String username;
  final String password;
  final String? website;
  final String? notes;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  final int revision;
  final String? scopeId;
  final String scopeType;

  PasswordItem copyWith({
    String? id,
    String? title,
    String? username,
    String? password,
    String? website,
    String? notes,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    int? revision,
    String? scopeId,
    String? scopeType,
  }) {
    return PasswordItem(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      revision: revision ?? this.revision,
      scopeId: scopeId ?? this.scopeId,
      scopeType: scopeType ?? this.scopeType,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'website': website,
      'notes': notes,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'revision': revision,
      'scopeId': scopeId,
      'scopeType': scopeType,
    };
  }

  factory PasswordItem.fromJson(Map<String, dynamic> json) {
    return PasswordItem(
      id: json['id'] as String,
      title: json['title'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      website: json['website'] as String?,
      notes: json['notes'] as String?,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastUsedAt: json['lastUsedAt'] == null
          ? null
          : DateTime.parse(json['lastUsedAt'] as String),
      revision: (json['revision'] as num?)?.toInt() ?? 1,
      scopeId: json['scopeId'] as String?,
      scopeType: (json['scopeType'] as String?) ?? 'personal',
    );
  }
}
