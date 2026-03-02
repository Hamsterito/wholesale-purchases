class UserProfile {
  final int id;
  final String name;
  final String email;
  final String role;
  final String supplierName;
  final String phone;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.supplierName,
    required this.phone,
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
    );
  }
}
