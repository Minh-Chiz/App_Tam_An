class User {
  final int id;
  final String email;
  final String? phoneNumber;
  final String name;
  final String? avatarUrl;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    this.phoneNumber,
    required this.name,
    this.avatarUrl,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone_number': phoneNumber,
      'name': name,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
