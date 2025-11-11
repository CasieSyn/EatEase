class User {
  final int id;
  final String email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? phone;
  final String? address;
  final String? profilePhoto;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.username,
    this.firstName,
    this.lastName,
    this.fullName,
    this.phone,
    this.address,
    this.profilePhoto,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      fullName: json['full_name'],
      phone: json['phone'],
      address: json['address'],
      profilePhoto: json['profile_photo'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'phone': phone,
      'address': address,
      'profile_photo': profilePhoto,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
