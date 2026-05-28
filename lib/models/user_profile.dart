class UserProfile {
  final int id;
  final String name;
  final String email;
  final String role;
  final String supplierName;
  final String phone;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.supplierName,
    required this.phone,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return UserProfile(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      avatarUrl: _parseAvatarUrl(json['avatarUrl']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'supplierName': supplierName,
        'phone': phone,
        'avatarUrl': avatarUrl,
      };
}

// Пустую строку трактуем как отсутствие аватарки - бекенд может прислать "" вместо null.
String? _parseAvatarUrl(dynamic value) {
  final str = value?.toString().trim() ?? '';
  return str.isEmpty ? null : str;
}
