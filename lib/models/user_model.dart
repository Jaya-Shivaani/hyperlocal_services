class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String? address;
  final String role; // 'customer' or 'admin'
  final String createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.address,
    this.role = 'customer',
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      phone: map['phone'],
      address: map['address'],
      role: map['role'] ?? 'customer',
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'address': address,
      'role': role,
      'created_at': createdAt,
    };
  }
}

