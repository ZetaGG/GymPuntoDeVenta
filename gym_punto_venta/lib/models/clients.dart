class Client {
  final String id;
  String name;
  String? email;
  String? phone;
  DateTime startDate;
  DateTime endDate;
  bool isActive;
  String? photo;
  String membershipType; // e.g., "Monthly", "Weekly"
  String paymentStatus;  // e.g., "Paid", "Pending"
  DateTime? lastVisitDate;
  int? membershipTypeId; // Foreign key to Memberships table
  double? currentMembershipPrice; // Store the price at the time of registration/renewal

  Client({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.photo,
    required this.membershipType,
    String? paymentStatus,
    this.lastVisitDate,
    this.membershipTypeId,
    this.currentMembershipPrice,
  }) : paymentStatus = paymentStatus ?? 'Paid';

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isActive: json['is_active'] == 1,
      photo: json['photo'],
      membershipType: json['membership_name'] ?? json['membershipType'] ?? '',
      paymentStatus: json['payment_status'] ?? json['paymentStatus'] ?? 'Paid',
      lastVisitDate: json['last_visit_date'] != null
          ? DateTime.parse(json['last_visit_date'])
          : null,
      membershipTypeId: json['membership_type_id'],
      currentMembershipPrice: (json['current_membership_price'] is String)
          ? double.tryParse(json['current_membership_price'])
          : (json['current_membership_price'] as num?)?.toDouble(),
    );
  }

  // Para la UI, si lo necesitas
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'photo': photo,
      'membershipType': membershipType, // Solo para UI, no para DB
      'payment_status': paymentStatus,
      'last_visit_date': lastVisitDate?.toIso8601String(),
      'membership_type_id': membershipTypeId,
      'current_membership_price': currentMembershipPrice,
    };
  }

  // SOLO PARA BASE DE DATOS (sin membershipType)
  Map<String, dynamic> toDbJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'photo': photo,
      'payment_status': paymentStatus,
      'last_visit_date': lastVisitDate?.toIso8601String(),
      'membership_type_id': membershipTypeId,
      'current_membership_price': currentMembershipPrice,
    };
  }
}