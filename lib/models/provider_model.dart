class ProviderModel {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String? address;
  final int categoryId;
  final String? description;
  final int isActive;
  final double rating;
  final String createdAt;

  ProviderModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.address,
    required this.categoryId,
    this.description,
    this.isActive = 1,
    this.rating = 0.0,
    required this.createdAt,
  });

  factory ProviderModel.fromMap(Map<String, dynamic> map) {
    return ProviderModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      phone: map['phone'],
      address: map['address'],
      categoryId: map['category_id'],
      description: map['description'],
      isActive: map['is_active'] ?? 1,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
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
      'category_id': categoryId,
      'description': description,
      'is_active': isActive,
      'rating': rating,
      'created_at': createdAt,
    };
  }
}

