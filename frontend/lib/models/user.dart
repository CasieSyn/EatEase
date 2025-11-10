class User {
  final int id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? address;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.address,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phone: json['phone'],
      address: json['address'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'address': address,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
