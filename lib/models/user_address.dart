class AddressDraft {
  final String label;
  final String addressLine;
  final String street;
  final String zip;
  final String apartment;

  const AddressDraft({
    required this.label,
    required this.addressLine,
    required this.street,
    required this.zip,
    required this.apartment,
  });

  factory AddressDraft.fromAddress(UserAddress address) {
    return AddressDraft(
      label: address.label,
      addressLine: address.addressLine,
      street: address.street,
      zip: address.zip,
      apartment: address.apartment,
    );
  }

  Map<String, dynamic> toRequestPayload() {
    return {
      'label': label,
      'addressLine': addressLine,
      'street': street,
      'zip': zip,
      'apartment': apartment,
    };
  }
}

class UserAddress {
  final int id;
  final int userId;
  final String label;
  final String addressLine;
  final String street;
  final String zip;
  final String apartment;

  const UserAddress({
    required this.id,
    required this.userId,
    required this.label,
    required this.addressLine,
    required this.street,
    required this.zip,
    required this.apartment,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return UserAddress(
      id: parseInt(json['id']),
      userId: parseInt(json['userId'] ?? json['user_id']),
      label: json['label']?.toString() ?? '',
      addressLine: json['addressLine']?.toString() ??
          json['address_line']?.toString() ??
          '',
      street: json['street']?.toString() ?? '',
      zip: json['zip']?.toString() ?? '',
      apartment: json['apartment']?.toString() ?? '',
    );
  }

  String get normalizedLabel => label.trim().toLowerCase();

  String get displayTitle {
    switch (normalizedLabel) {
      case 'home':
        return 'Дом';
      case 'work':
        return 'Работа';
      case 'other':
        return 'Другое';
      default:
        return label.isNotEmpty ? label : 'Другое';
    }
  }

  String get displayAddress {
    final parts = <String>[];
    if (addressLine.trim().isNotEmpty) {
      parts.add(addressLine.trim());
    }
    if (street.trim().isNotEmpty) {
      parts.add(street.trim());
    }
    if (apartment.trim().isNotEmpty) {
      parts.add('кв. ${apartment.trim()}');
    }
    if (zip.trim().isNotEmpty) {
      parts.add(zip.trim());
    }
    return parts.isEmpty ? '' : parts.join(', ');
  }
}

