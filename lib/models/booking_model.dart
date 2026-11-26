class BookingModel {
  final int? id;
  final int customerId;
  final int providerId;
  final int categoryId;
  final String serviceDescription;
  final String address;
  final String scheduledDate;
  final String status; // pending, accepted, rejected, cancelled, completed
  final String? notes;
  final String createdAt;
  final String updatedAt;

  BookingModel({
    this.id,
    required this.customerId,
    required this.providerId,
    required this.categoryId,
    required this.serviceDescription,
    required this.address,
    required this.scheduledDate,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'],
      customerId: map['customer_id'],
      providerId: map['provider_id'],
      categoryId: map['category_id'],
      serviceDescription: map['service_description'],
      address: map['address'],
      scheduledDate: map['scheduled_date'],
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'provider_id': providerId,
      'category_id': categoryId,
      'service_description': serviceDescription,
      'address': address,
      'scheduled_date': scheduledDate,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }
}

