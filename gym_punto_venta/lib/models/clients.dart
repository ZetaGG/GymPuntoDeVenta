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
    String? paymentStatus, // Made nullable here to allow default 'Paid'
    this.lastVisitDate,
    this.membershipTypeId,
    this.currentMembershipPrice,
  }) : paymentStatus = paymentStatus ?? 'Paid'; // Initialize to 'Paid' if not provided

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      startDate: DateTime.parse(json['start_date']), // Assuming from DB 'start_date'
      endDate: DateTime.parse(json['end_date']),     // Assuming from DB 'end_date'
      isActive: json['is_active'] == 1,             // Assuming from DB 'is_active' is 0 or 1
      photo: json['photo'],
      membershipType: json['membership_name'] ?? json['membershipType'] ?? '', // Handle direct value or from join
      paymentStatus: json['payment_status'] ?? json['paymentStatus'] ?? 'Paid',
      lastVisitDate: json['last_visit_date'] != null
          ? DateTime.parse(json['last_visit_date'])
          : null,
      membershipTypeId: json['membership_type_id'],
      currentMembershipPrice: (json['current_membership_price'] is String)
          ? double.tryParse(json['current_membership_price'])
          : (json['current_membership_price'] as num?)?.toDouble(), // Handle potential price from join or direct
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'start_date': startDate.toIso8601String(), // Changed to match DB
      'end_date': endDate.toIso8601String(),     // Changed to match DB
      'is_active': isActive ? 1 : 0,             // Changed to match DB (integer)
      'photo': photo,
      'membershipType': membershipType, // This is the name, e.g., "Monthly"
      'payment_status': paymentStatus,   // Changed to match DB
      'last_visit_date': lastVisitDate?.toIso8601String(), // Changed to match DB
      'membership_type_id': membershipTypeId,
      'current_membership_price': currentMembershipPrice,
    };
  }
}